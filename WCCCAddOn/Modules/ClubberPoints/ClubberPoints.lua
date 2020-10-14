--
-- Module for interacting with season-based Clubber Points. Other modules, such as the ClubbingCompetition use this for scoring.
--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD

local COMM_KEY_PERSONAL_SCORE_UPDATE = "guildyScoreUpdate"

local clubberPointsData =
{
    profile =
    {
        -- Might want to sync everyone's score to a leaderboard at some point, but for now we'll keep them secret for people to share on their terms.
        score = 0,

        -- Timestamp when the current season started.
        seasonTimestamp = 0,

        ---@class QueuedRewardEntry
        ---@field GUID string  target player.
        ---@field points number  Number of points to award.
        ---@field timestamp number  Time it was awarded.

        ---@type table<string, table<number, QueuedRewardEntry>
        queuedRewards =
        {
            -- [GUID] = {[timestamp] = {QueuedRewardEntry}}
        },

        -- Array of timestamps relating to a reward for the local player from queuedRewards
        collectedRewards =
        {
            -- [timestamp]
        },

        ---@class ClubberLeaderboardDataEntry
        ---@field GUID string
        ---@field playerName string
        ---@field classID number
        ---@field score number
        ---@field lastUpdateTimestamp number

        ---@type table<string, ClubberLeaderboardDataEntry>
        leaderboardData =
        {
            -- [GUID] = {GUID, playerName, classID, score, lastUpdateTimestamp}
        },
    }
}

local ClubberPoints = WCCCAD:CreateModule("WCCC_ClubberPoints", clubberPointsData)
LibStub("AceEvent-3.0"):Embed(ClubberPoints)
ClubberPoints.SCORE_UPDATED_EVENT = ClubberPoints.moduleName .. "SCORE_UPDATED_EVENT"
ClubberPoints.NEW_SEASON_EVENT = ClubberPoints.moduleName .. "NEW_SEASON_EVENT"

function ClubberPoints:InitializeModule()
    if self.moduleDB.leaderboardData == nil then
        self.moduleDB.leaderboardData = {}
    end
    self:RegisterModuleComm(COMM_KEY_PERSONAL_SCORE_UPDATE, self.OnGuildyScoreUpdateReceived)
    self:PrintDebugMessage("Clubber Points module loaded.")
    end

function ClubberPoints:OnEnable()
    self:InitiateSync()
    self.UI:OnEnable()
end

function ClubberPoints:OnDisable()
    self.UI:OnDisable()
end

function ClubberPoints:GetOwnScore()
    return self.moduleDB.score
end

function ClubberPoints:AddPoints(numPoints)
    self.moduleDB.score = self.moduleDB.score + numPoints
    local GUID = UnitGUID("player")
    local _, _, classID = UnitClass("player")
    if self.moduleDB.leaderboardData[GUID] == nil then
        self.moduleDB.leaderboardData[GUID] =
        {
            GUID = GUID,
            playerName = UnitName("player"),
            classID = classID
        }
    end
    self.moduleDB.leaderboardData[GUID].lastUpdateTimestamp = GetServerTime()
    self.moduleDB.leaderboardData[GUID].score = self.moduleDB.score
    self:SendMessage(ClubberPoints.SCORE_UPDATED_EVENT)
    self:SendPersonalScoreComm()
end

function ClubberPoints:SendPersonalScoreComm()
    local GUID = UnitGUID("player")
    if self.moduleDB.leaderboardData[GUID] == nil then
        self:PrintDebugMessage("Skipping sending score update as we have no data.")
        return
    end
    self:SendModuleComm(COMM_KEY_PERSONAL_SCORE_UPDATE, self.moduleDB.leaderboardData[GUID], ns.consts.CHAT_CHANNEL.GUILD)
end

function ClubberPoints:OnGuildyScoreUpdateReceived(data)
    if self.moduleDB.leaderboardData[data.GUID] ~= nil and self.moduleDB.leaderboardData[data.GUID].lastUpdateTimestamp > data.lastUpdateTimestamp then
        -- We've got newer data, weirdly.
        self:PrintDebugMessage(format("Received an old score update from %s.", data.playerName))
        return
    end
    self.moduleDB.leaderboardData[data.GUID] = data
end

function ClubberPoints:CollectAvailableRewards()
    local GUID = UnitGUID("player")
    if self.moduleDB.queuedRewards[GUID] == nil then
        return
    end

    for timestamp, reward in pairs(self.moduleDB.queuedRewards[GUID]) do
        if timestamp < self.moduleDB.seasonTimestamp then
            return
        end

        local isCollected = false
        for _, collectedTimestamp in ipairs(self.moduleDB.collectedRewards) do
            if collectedTimestamp == timestamp then
                isCollected = true
                break
            end
        end

        if not isCollected and reward ~= nil then
            table.insert(self.moduleDB.collectedRewards, timestamp)
            self:AddPoints(reward.points)
            WCCCAD.UI:PrintAddOnMessage(format("Congratulations! You've been awarded %i Clubber Points! Current score: %i", reward.points, self:GetOwnScore()))
        end
    end
end

--region Leaderboard

--endregion

--region Season
---
--- Call to start a new season. Subscribe to ClubberPoints.SCORE_UPDATED_EVENT to be notified when this happens.
---
function ClubberPoints:OC_StartNewSeason(seasonTimestamp)
    if not WCCCAD:IsPlayerOfficer() then
        return
    end

    self:StartNewSeason(seasonTimestamp)
    self:BroadcastSyncData()
end

---
--- Called internally to actually start a new season.
---
function ClubberPoints:StartNewSeason(seasonTimestamp)
    if seasonTimestamp <= self.moduleDB.seasonTimestamp then
        self:PrintDebugMessage("ClubberPoints already have new season data, skipping season update.")
        return
    end

    self:PrintDebugMessage("Starting new ClubberPoints season.")
    self.moduleDB.score = 0
    self.moduleDB.collectedRewards = {}
    self.moduleDB.seasonTimestamp = seasonTimestamp
    self.moduleDB.leaderboardData = {}

    -- Clear out expired rewards
    for GUID, queuedRewards in pairs(self.moduleDB.queuedRewards) do
        local expiredRewardKeys = {}
        for timestamp, reward in pairs(queuedRewards) do
            if timestamp < seasonTimestamp then
                table.insert(expiredRewardKeys, timestamp)
            end
        end

        for _, rewardKey in ipairs(expiredRewardKeys) do
            queuedRewards[rewardKey] = nil
            self:PrintDebugMessage(format("Removing expired reward. Timestamp: %i, season: %i ", rewardKey, seasonTimestamp))
        end
    end

    -- TODO: For now, there's a nasty dependency on ClubbingComp managing the season flow.
    -- TODO: Ideally, this should all be moved into this module and other modules should subscribe to this event instead.
    -- TODO: How other modules can add data to a season, such as seasonrace, needs to be considered though.
    self:SendMessage(ClubberPoints.NEW_SEASON_EVENT)
end
--endregion

--region Officer Controls
function ClubberPoints:OC_AwardPointsToPlayer(playerGUID, numPoints)
    if not WCCCAD:IsPlayerOfficer() then
        return
    end

    local timestamp = GetServerTime()
    ---@type QueuedRewardEntry
    local newRewardEntry =
    {
        GUID = playerGUID,
        points = numPoints,
        timestamp = timestamp
    }

    if self.moduleDB.queuedRewards[playerGUID] == nil then
        self.moduleDB.queuedRewards[playerGUID] = {}
    end

    self.moduleDB.queuedRewards[playerGUID][timestamp] = newRewardEntry

    self:CollectAvailableRewards()
    self:BroadcastSyncData()
end
--endregion


--region Sync functions

function ClubberPoints:GetSyncData()
    local syncData =
    {
        seasonTimestamp = self.moduleDB.seasonTimestamp,
        queuedRewards = self.moduleDB.queuedRewards,
        leaderboardData = self.moduleDB.leaderboardData
    }

    return syncData
end

function ClubberPoints:CompareSyncData(remoteData)
    -- Can skip syncing both if the season has changed.
    if remoteData.seasonTimestamp > self.moduleDB.seasonTimestamp then
        return ns.consts.DATA_SYNC_RESULT.REMOTE_NEWER
    elseif self.moduleDB.seasonTimestamp > remoteData.seasonTimestamp then
        return ns.consts.DATA_SYNC_RESULT.LOCAL_NEWER
    end

    local remoteHasNewData = self:DoesRewardsQueueHaveNewData(remoteData.queuedRewards, self.moduleDB.queuedRewards)
    local localHasNewData = self:DoesRewardsQueueHaveNewData(self.moduleDB.queuedRewards, remoteData.queuedRewards)

    -- If we're not already syncing the remote, check the leaderboard
    if not remoteHasNewData then
        remoteHasNewData = self:DoesLeaderboardHaveNewData(remoteData.leaderboardData, self.moduleDB.leaderboardData)
    end
    -- If we're not already syncing local, check the leaderboard
    if not localHasNewData then
        localHasNewData = self:DoesLeaderboardHaveNewData(self.moduleDB.leaderboardData, remoteData.leaderboardData)
    end

    if remoteHasNewData and localHasNewData then
        return ns.consts.DATA_SYNC_RESULT.BOTH_NEWER
    elseif remoteHasNewData then
        return ns.consts.DATA_SYNC_RESULT.REMOTE_NEWER
    elseif localHasNewData then
        return ns.consts.DATA_SYNC_RESULT.LOCAL_NEWER
    end

    return ns.consts.DATA_SYNC_RESULT.EQUAL
end

---
--- Checks whether originQueuedRewards has entries otherQueuedRewards doesn't.
--- @param sourceQueuedRewardsTable table<string, QueuedRewardEntry> queuedRewards table from a moduleDB to use as the source.
--- @param otherQueuedRewardsTable table<string, QueuedRewardEntry> queuedRewards table from a moduleDB to compare against.
---
function ClubberPoints:DoesRewardsQueueHaveNewData(sourceQueuedRewardsTable, otherQueuedRewardsTable)
    for GUID, queuedRewards in pairs(sourceQueuedRewardsTable) do
        if otherQueuedRewardsTable[GUID] == nil then
            return true
        else
            for rewardTimestamp, _ in pairs(queuedRewards) do
                if otherQueuedRewardsTable[GUID][rewardTimestamp] == nil and rewardTimestamp >= self.moduleDB.seasonTimestamp then
                    return true
                end
            end
        end
    end

    return false
end

---
--- Checks whether sourceLeaderboardData has newer data than otherLeaderboardData.
--- @param sourceLeaderboardData table<string, ClubberLeaderboardDataEntry> leaderboardData table from a moduleDB to use as the source.
--- @param otherLeaderboardData table<string, ClubberLeaderboardDataEntry> leaderboardData table from a moduleDB to compare against.
---
function ClubberPoints:DoesLeaderboardHaveNewData(sourceLeaderboardData, otherLeaderboardData)
    for GUID, entry in pairs(sourceLeaderboardData) do
        if otherLeaderboardData[GUID] == nil then
            return true
        else if entry.lastUpdateTimestamp > otherLeaderboardData[GUID].lastUpdateTimestamp then
                return true
            end
        end
    end

    return false
end

-- TODO: If the other season is less than ours, ignore their leaderboard data
-- TODO: When we start a new season, reset the leaderboard then take the other data.
function ClubberPoints:OnSyncDataReceived(data)
    if data.seasonTimestamp > self.moduleDB.seasonTimestamp then
        self:StartNewSeason(data.seasonTimestamp)
    end
    self:UpdateLeaderboard(data.leaderboardData)
    self:UpdateQueuedRewards(data.queuedRewards)
end

function ClubberPoints:UpdateQueuedRewards(otherQueuedRewards)
    for GUID, queuedRewards in pairs(otherQueuedRewards) do
        if self.moduleDB.queuedRewards[GUID] == nil then
            self.moduleDB.queuedRewards[GUID] = queuedRewards
        else
            for rewardTimestamp, queuedReward in pairs(queuedRewards) do
                if self.moduleDB.queuedRewards[GUID][rewardTimestamp] == nil and rewardTimestamp >= self.moduleDB.seasonTimestamp then
                    self.moduleDB.queuedRewards[GUID][rewardTimestamp] = queuedReward
                end
            end
        end
    end

    self:CollectAvailableRewards()
end

function ClubberPoints:UpdateLeaderboard(leaderboardData)
    for key, entryData in pairs(leaderboardData) do
        if self.moduleDB.leaderboardData[key] == nil or self.moduleDB.leaderboardData[key].lastUpdateTimestamp < entryData.lastUpdateTimestamp then
            self.moduleDB.leaderboardData[key] = entryData
        end
    end
end
--endregion