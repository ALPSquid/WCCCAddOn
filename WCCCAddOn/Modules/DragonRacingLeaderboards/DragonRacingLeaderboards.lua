--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--

local _, ns = ...
local WCCCAD = ns.WCCCAD

local COMM_KEY_GUILDY_NEW_PERSONAL_BEST_TIME = "guildyNewPersonalBestTime"

local DRL_data =
{
    profile =
    {
        ---@class DRL_LeaderboardDataEntry
        ---@field GUID string
        ---@field raceID number
        ---@field playerName string
        ---@field time number
        ---@field achievedTimestamp number

        ---@class DRL_RaceLeaderboardData
        ---@field raceID number
        ---@field leaderboard table<string, DRL_LeaderboardDataEntry>

        ---@type table<number, DRL_RaceLeaderboardData>
        leaderboardData =
        {
            -- [raceID] = {raceID, {[GUID] = {GUID, raceID, playerName, time, achievedTimestamp}}}
        },
    }
}

local DRL = WCCCAD:CreateModule("WCCC_DragonRacingLeaderboards", DRL_data)
LibStub("AceEvent-3.0"):Embed(DRL)
DRL.Locale = LibStub("AceLocale-3.0"):GetLocale("WCCC_DragonRacingLeaderboards")


function DRL:InitializeModule()
    self:RegisterModuleSlashCommand("drl", self.DRLCommand)

    self:RegisterModuleComm(COMM_KEY_GUILDY_NEW_PERSONAL_BEST_TIME, self.OnGuildyNewPersonalBestCommReceived)
end

function DRL:OnEnable()
    self:RegisterEvent("QUEST_ACCEPTED", self.OnQuestAccepted, self)
    self:RegisterEvent("QUEST_REMOVED", self.OnQuestRemoved, self)

    self:ValidateData()
    self:ScanPersonalBests(false)
    self:InitiateSync()
end

function DRL:OnDisable()
    self:RegisterEvent("QUEST_ACCEPTED")
    self:RegisterEvent("QUEST_REMOVED")
end

---
--- Generic chat command, opens the config panel when the wccc command is entered.
---
function DRL:DRLCommand(args)
    if args ~= nil and args[1] ~= nil then
        if args[1] == "info" or args[1] == "settings" then
            self.UI:Show()
        end
        return
    end
    self.LeaderboardUI:Show()
end

---
--- @return DRL_RaceLeaderboardData @Leaderboard data table for the specified race.
---
function DRL:GetRaceLeaderboardData(raceID)
    if self.moduleDB.leaderboardData[raceID] == nil then
        self.moduleDB.leaderboardData[raceID] = {}
    end
    return self.moduleDB.leaderboardData[raceID]
end

---
--- Updates the player's personal best for every race.
---
function DRL:ScanPersonalBests(reportNewPBs)
    for raceID, raceData in pairs(DRL.races) do
        if raceData.currencyID > 0 then
            local rawTime = C_CurrencyInfo.GetCurrencyInfo(raceData.currencyID).quantity
            if rawTime > 0 then
                self:UpdateTime(raceID, rawTime / 1000, reportNewPBs)
            end
        end
    end
end

---
--- @return DRL_LeaderboardDataEntry @Leaderboard entry for the player's account, using their best time across all characters and their main as the player.
---
function DRL:GetPlayerAccountBest(characterGUID, raceID)
    local leaderboardData = self:GetRaceLeaderboardData(raceID)
    local bestRaceData = nil
    local playerMainData = WCCCAD:GetPlayerMain(characterGUID)
    if not playerMainData then
        playerMainData = {
            GUID = characterGUID,
            name = leaderboardData[characterGUID].playerName
        }
    end
    local characters = WCCCAD:GetPlayerCharacters(characterGUID)
    if characters then
        for GUID, characterData in pairs(characters) do
            if leaderboardData[GUID] and leaderboardData[GUID].time and (bestRaceData == nil or leaderboardData[GUID].time < bestRaceData.time) then
                bestRaceData = leaderboardData[GUID]
            end
        end
    end
    if not bestRaceData then
        bestRaceData = leaderboardData[characterGUID]
    end
    local data =
    {
        GUID = playerMainData.GUID,
        raceID = raceID,
        playerName = playerMainData.name,
        achievedPlayerName = bestRaceData and bestRaceData.playerName or playerMainData.name,
        time = bestRaceData and bestRaceData.time or 0,
        achievedTimestamp = bestRaceData and bestRaceData.achievedTimestamp or 0
    }
    return data
end

function DRL:OnQuestAccepted(event, questID)
    if not questID then return end
    self:PrintDebugMessage("Started quest: "..questID)
    for raceID, raceData in pairs(DRL.races) do
        if raceData.questID == questID then
            self:PrintDebugMessage("Started race: "..DRL:GetRaceName(raceData.questID))
            return
        end
    end
end

function DRL:OnQuestRemoved(event, questID)
    if not questID then return end
    self:PrintDebugMessage("Removed quest: "..questID)
    for raceID, raceData in pairs(DRL.races) do
        if raceData.questID == questID then
            self:PrintDebugMessage("Race removed: "..DRL:GetRaceName(raceData.questID))
            local guildBestTime = ns.utils.MinAttribute(self:GetRaceLeaderboardData(raceID), function(leaderboardEntry)
                if leaderboardEntry.time <= 0 then
                    return 300
                end
                return leaderboardEntry.time
            end) or 0
            local bestTime = C_CurrencyInfo.GetCurrencyInfo(raceData.currencyID).quantity
            if bestTime <= 0 then
                return
            end
            bestTime = bestTime / 1000
            self:UpdateTime(raceData.raceID, bestTime, true)

            -- Reporting
            local accountBest = self:GetPlayerAccountBest(UnitGUID("player"), raceID)
            -- If our time isn't the guild best, output the current best times.
            if accountBest.time > guildBestTime then
                WCCCAD.UI:PrintAddOnMessage(format("Guild best: |cFFFFFFFF%.3fs|r, Your best: |cFFFFFFFF%.3fs|r (%s)", guildBestTime, accountBest.time, accountBest.achievedPlayerName), ns.consts.MSG_TYPE.GUILD)
                -- If our time is the guild best and we didn't just earn that place, report that ours is still the best.
            elseif bestTime >= accountBest.time then
                WCCCAD.UI:PrintAddOnMessage(format("Your time of |cFFFFFFFF%.3fs|r (%s) is the guild best!", accountBest.time, accountBest.achievedPlayerName), ns.consts.MSG_TYPE.GUILD)
            end
            return
        end
    end
end

---
--- Updates the logged time for a race. If this is a new personal best, appropriate events will be triggered.
--- @param raceID number @ID of the race.
--- @param time number @New time for the race.
--- @param reportNewPBs boolean @If true, new PBs will be reported to the guild.
---
function DRL:UpdateTime(raceID, time, reportNewPBs)
    if not WCCCAD:CheckAddonActive(false) then
        return
    end
    self:PrintDebugMessage(format("Time for %s: %.3f", DRL:GetRaceName(raceID), time))
    local playerGUID = UnitGUID("player")
    local raceData = self:GetRaceLeaderboardData(raceID)[playerGUID]
    local accountBest = self:GetPlayerAccountBest(UnitGUID("player"), raceID)
    if raceData == nil then
        raceData =
        {
            GUID = playerGUID,
            raceID = raceID,
            playerName = UnitName("player"),
            time = 0,
            achievedTimestamp = 0
        }
        self:GetRaceLeaderboardData(raceID)[playerGUID] = raceData
    end
    if raceData.time <= 0 or time ~= raceData.time then
        raceData.time = time
        raceData.achievedTimestamp = GetServerTime()
        if reportNewPBs and (accountBest.time <= 0 or time < accountBest.time) then
            self:PrintPersonalBestMessage(raceData.playerName, raceData.raceID, raceData.time)
        end
        self:SendModuleComm(COMM_KEY_GUILDY_NEW_PERSONAL_BEST_TIME, {timeData = raceData, reportNewPBs = reportNewPBs}, ns.consts.CHAT_CHANNEL.GUILD)
        self.LeaderboardUI:OnLeaderboardDataUpdated()
    end
end

---
--- Fired when a guild member achieves a new personal best time.
---
function DRL:OnGuildyNewPersonalBestCommReceived(data)
    -- Pre 1.5.5 check.
    if not data.timeData then
        return
    end
    local raceData = self.races[data.timeData.raceID]
    local accountBest = self:GetPlayerAccountBest(data.timeData.GUID, data.timeData.raceID)
    self.moduleDB.leaderboardData[raceData.raceID][data.timeData.GUID] = data.timeData
    -- We need to update PBs for all characters, but we only want to report new account bests.
    if data.reportNewPBs and (not accountBest.time or data.timeData.time < accountBest.time) then
        self:PrintPersonalBestMessage(data.timeData.playerName, data.timeData.raceID, data.timeData.time)
    end
end

function DRL:PrintPersonalBestMessage(playerName, raceID, time)
    local processedMains = {}
    local accountBest = 0
    local position = 1
    for _, leaderboardEntry in pairs(self:GetRaceLeaderboardData(raceID)) do
        accountBest = self:GetPlayerAccountBest(leaderboardEntry.GUID, raceID)
        if not processedMains[accountBest.GUID] and accountBest.time < time then
            position = position + 1
        end
        processedMains[accountBest.GUID] = true
        -- We only care about reporting the top 3 places.
        if position > 3 then
            break
        end
    end
    -- Output
    local msg = format("%s has achieved a new personal best for the '%s' dragon race: |cFFFFFFFF%.3fs|r", playerName, DRL:GetRaceName(raceID), time)
    WCCCAD.UI:PrintAddOnMessage(msg, ns.consts.MSG_TYPE.GUILD)
    if position == 1 then WCCCAD.UI:PrintAddOnMessage("This is a new guild record!", ns.consts.MSG_TYPE.GUILD)
    elseif position == 2 then WCCCAD.UI:PrintAddOnMessage("This is the new 2nd best time!", ns.consts.MSG_TYPE.GUILD)
    elseif position == 3 then WCCCAD.UI:PrintAddOnMessage("This is the new 3rd best time!", ns.consts.MSG_TYPE.GUILD)
    end
end

--region Sync functions
function DRL:GetSyncData()
    local syncData =
    {
        leaderboardData = self.moduleDB.leaderboardData,
    }

    return syncData
end

function DRL:CompareSyncData(remoteData)
    local remoteHasNewData = self:DoesLeaderboardHaveNewData(remoteData.leaderboardData, self.moduleDB.leaderboardData)
    local localHasNewData = self:DoesLeaderboardHaveNewData(self.moduleDB.leaderboardData, remoteData.leaderboardData)

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
--- Checks whether sourceLeaderboardData has newer data than otherLeaderboardData.
--- @param sourceLeaderboardData table<number, DRL_RaceLeaderboardData> leaderboardData table from a moduleDB to use as the source.
--- @param otherLeaderboardData table<number, DRL_RaceLeaderboardData> leaderboardData table from a moduleDB to compare against.
---
function DRL:DoesLeaderboardHaveNewData(sourceLeaderboardData, otherLeaderboardData)
    if not sourceLeaderboardData then
        return false
    end
    if not otherLeaderboardData then
        return true
    end
    for raceID, raceLeaderboardData in pairs(sourceLeaderboardData) do
        if otherLeaderboardData[raceID] == nil then
            return true
        end
        for GUID, leaderboardEntry in pairs(raceLeaderboardData) do
            if otherLeaderboardData[raceID][GUID] == nil then
                return true
            elseif leaderboardEntry.achievedTimestamp > otherLeaderboardData[raceID][GUID].achievedTimestamp then
                return true
            end
        end
    end

    return false
end

function DRL:OnSyncDataReceived(data)
    self:UpdateLeaderboard(data.leaderboardData)
    self.LeaderboardUI:OnLeaderboardDataUpdated()
end

function DRL:UpdateLeaderboard(leaderboardData)
    for raceID, raceLeaderboardData in pairs(leaderboardData) do
        if self.moduleDB.leaderboardData[raceID] == nil then
            self.moduleDB.leaderboardData[raceID] = raceLeaderboardData
        else
            for GUID, leaderboardEntry in pairs(raceLeaderboardData) do
                local localRaceLeaderboardData = self:GetRaceLeaderboardData(raceID)
                if localRaceLeaderboardData[GUID] == nil or localRaceLeaderboardData[GUID].achievedTimestamp < leaderboardEntry.achievedTimestamp then
                    localRaceLeaderboardData[GUID] = leaderboardEntry
                end
            end
        end
    end
    self:ValidateData()
end

--- Removes bad data from the leaderboard table.
function DRL:ValidateData()
    for raceID in pairs(DRL.races) do
        local leaderboardData = self.moduleDB.leaderboardData[raceID] or {}
        for GUID, leaderboardEntry in pairs(leaderboardData) do
            -- Validate GUIDs. We've seen GUIDs with missing chunks, possibly due to syncs being interrupted and/or client errors.
            local GUIDKeyIsValid = ns.utils.isValidPlayerGUID(GUID)
            local GUIDValueIsValid = ns.utils.isValidPlayerGUID(leaderboardEntry.GUID)

            if GUIDKeyIsValid and GUIDValueIsValid then
                -- If both GUIDs are valid but don't match, take the key.
                if GUID ~= leaderboardEntry.GUID then
                    leaderboardEntry.GUID = GUID
                end
            elseif GUIDKeyIsValid then
                -- If only the key is valid, update the value to match.
                leaderboardEntry.GUID = GUID
            elseif GUIDValueIsValid then
                -- If only the value is valid, update the key to match.
                leaderboardData[leaderboardEntry.GUID] = leaderboardEntry
                leaderboardData[GUID] = nil
            else
                -- Neither are valid, delete this entry.
                leaderboardData[GUID] = nil
            end
        end
    end
end
--endregion