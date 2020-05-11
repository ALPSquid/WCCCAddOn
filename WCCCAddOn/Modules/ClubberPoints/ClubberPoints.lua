--
-- Module for interacting with season-based Clubber Points. Other modules, such as the ClubbingCompetition use this for scoring.
--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD

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
        }
    }
}

local ClubberPoints = WCCCAD:CreateModule("WCCC_ClubberPoints", clubberPointsData)

function ClubberPoints:InitializeModule()
    self:PrintDebugMessage("Clubber Points module loaded.")
end

function ClubberPoints:OnEnable()
    self:InitiateSync()
end

function ClubberPoints:GetOwnPoints()
    return self.moduleDB.score
end

function ClubberPoints:AddPoints(numPoints)
    self.moduleDB.score = self.moduleDB.score + numPoints
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
            WCCCAD.UI:PrintAddOnMessage(format("Congratulations! You've been awarded %i Clubber Points! Current score: %i", reward.points, self:GetOwnPoints()))
        end
    end
end

--region Season
function ClubberPoints:OC_StartNewSeason(seasonTimestamp)
    if not WCCCAD:IsPlayerOfficer() then
        return
    end

    self:StartNewSeason(seasonTimestamp)
    self:BroadcastSyncData()
end

function ClubberPoints:StartNewSeason(seasonTimestamp)
    if seasonTimestamp <= self.moduleDB.seasonTimestamp then
        self:PrintDebugMessage("ClubberPoints already have new season data, skipping season update.")
        return
    end

    self:PrintDebugMessage("Starting new ClubberPoints season.")
    self.moduleDB.score = 0
    self.moduleDB.collectedRewards = {}
    self.moduleDB.seasonTimestamp = seasonTimestamp

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
end
--endregion

--region Officer Controls
function ClubbingComp:OC_AwardPointsToPlayer(playerGUID, numPoints)
    if not WCCCAD:IsPlayerOfficer() then
        return
    end

    ---@type QueuedRewardEntry
    local newRewardEntry =
    {
        GUID = playerGUID,
        points = numPoints,
        timestamp = GetServerTime()
    }

    if self.moduleDB.queuedRewards[playerGUID] == nil then
        self.moduleDB.queuedRewards[playerGUID] = {}
    end

    self.moduleDB[playerGUID][timestamp] = newRewardEntry

    self:CollectAvailableRewards()
    self:BroadcastSyncData()
end
--endregion


--region Sync functions

function ClubberPoints:GetSyncData()
    local syncData =
    {
        seasonTimestamp = self.moduleDB.seasonTimestamp,
        queuedRewards = self.moduleDB.queuedRewards
    }

    return syncData
end

function ClubberPoints:CompareSyncData(remoteData)
    -- Can skip the queuedRewards comparison if the season has changed.
    if remoteData.seasonTimestamp > self.moduleDB.seasonTimestamp then
        return ns.consts.DATA_SYNC_RESULT.REMOTE_NEWER
    elseif self.moduleDB.seasonTimestamp > remoteData.seasonTimestamp then
        return ns.consts.DATA_SYNC_RESULT.LOCAL_NEWER
    end

    local remoteHasNewData = self:DoesRewardsQueueHaveNewData(remoteData.queuedRewards, self.moduleDB.queuedRewards)
    local localHasNewData = self:DoesRewardsQueueHaveNewData(self.moduleDB.queuedRewards, remoteData.queuedRewards)

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

function ClubberPoints:OnSyncDataReceived(data)
    if data.seasonTimestamp > self.moduleDB.seasonTimestamp then
        self:StartNewSeason(data.seasonTimestamp)
    end
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

--endregion