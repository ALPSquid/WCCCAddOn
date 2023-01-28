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
DRL.activeRaceID = nil


function DRL:InitializeModule()
    self:RegisterModuleSlashCommand("drl", self.DRLCommand)

    self:RegisterModuleComm(COMM_KEY_GUILDY_NEW_PERSONAL_BEST_TIME, self.OnGuildyNewPersonalBestCommReceived)
end

function DRL:OnEnable()
    self:RegisterEvent("CHAT_MSG_MONSTER_SAY", self.OnChatMsg, self)
    self:RegisterEvent("GOSSIP_SHOW", self.OnGossip, self)
    self:RegisterEvent("QUEST_ACCEPTED", self.OnQuestAccepted, self)

    self:InitiateSync()
end

function DRL:OnDisable()
    self:UnregisterEvent("CHAT_MSG_MONSTER_SAY")
    self:UnregisterEvent("GOSSIP_SHOW")
    self:RegisterEvent("QUEST_ACCEPTED")
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

function DRL:OnQuestAccepted(event, questID)
    if not questID then return end
    self:PrintDebugMessage("Started quest: "..questID)
    for raceID, raceData in pairs(DRL.races) do
        if raceData.questID == questID then
            self:PrintDebugMessage("Started race: " .. DRL:GetRaceName(raceData.questID))
            DRL.activeRaceID = raceID
            return
        end
    end
end

function DRL:OnChatMsg(event, text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    if ns.utils.TableContains(DRL.Locale["NPC_TIMEKEEPER"], playerName) then
        -- "Your race time was 64.095 seconds. Your personal best for this race is 58.368 seconds."
        -- "Your race time was 63.125 seconds. That was your best time yet!"
        if DRL.activeRaceID == nil then
            return
        end
        local raceData = DRL.races[DRL.activeRaceID]
        local times = self:ExtractTimes(text)
        local bestTime = #times > 1 and times[2] or times[1]
        if not bestTime or bestTime <= 0 then
            return
        end
        DRL.activeRaceID = nil
        self:UpdateTime(raceData.raceID, bestTime, true)
    end
end

function DRL:OnGossip(event, uiTextureKit)
    local npcName, _ = UnitName("npc")
    if ns.utils.TableContains(DRL.Locale["NPC_TIMEKEEPER_ASSISTANT"], npcName) then
        WCCCAD.UI:PrintAddOnMessage("Updating times from Assistants is disabled until Blizz fixes them reporting incorrect times.\
        To get your personal best, please complete the race again and the Timekeeper will say the correct time.")
        return
        -- "Did you know your best time for this course is 61.665 seconds?"
        -- "And for the advanced course it's 63.215 seconds,"
        -- "And for the reverse course it's 60.213 seconds.
        --local text = C_GossipInfo.GetText()
        --if text then
        --    local posX, posY = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player"):GetXY()
        --    local radius = 0.006
        --    local times = self:ExtractTimesByType(text)
        --    for raceID, raceConfig in pairs(DRL.races) do
        --        if abs(posX - raceConfig.coordX) <= radius and abs(posY - raceConfig.coordY) <= radius then
        --            local bestTime = times[raceConfig.raceType]
        --            if bestTime and bestTime > 0 then
        --                self:UpdateTime(raceID, bestTime, true)
        --            else
        --                self:PrintDebugMessage("Failed to get time for race:"..DRL:GetRaceName(raceConfig.raceID))
        --            end
        --
        --        end
        --    end
        --end
    end
end

---
--- Extracts all race times from a string
--- @returns table @Array of extracted times in order of appearance.
---
function DRL:ExtractTimes(text)
    local times = {}
    for time in string.gmatch(text, DRL.Locale["TIME_PATTERN"]) do
        time = time:gsub(",", ".")
        times[#times + 1] = tonumber(time)
    end
    return times
end

---
--- Extracts race times for each found race type from a string.
--- @returns table @Map of extracted times for each found race type in the format {[DRL.RaceType] = time}
---
function DRL:ExtractTimesByType(text)
    local times = {}
    local searchPattern = nil
    local time = nil
    for _, raceTypeID in pairs(DRL.RACE_TYPE) do
        searchPattern = DRL.Locale["ASSISTANT_TIME_PATTERN_"..raceTypeID]
        time = string.match(text, searchPattern)
        if time then
            time = time:gsub(",", ".")
            times[raceTypeID] = tonumber(time)
        end
    end
    return times
end

---
--- Updates the logged time for a race. If this is a new personal best, appropriate events will be triggered.
--- @param raceID number @ID of the race.
--- @param time number @New time for the race.
--- @param forceUpdate boolean @If true, the time will be updated regardless of whether it's slower.
---     If false, the time will only be updated if it's faster than the player's logged time.
---
function DRL:UpdateTime(raceID, time, forceUpdate)
    if not WCCCAD:CheckAddonActive(false) then
        return
    end
    self:PrintDebugMessage(format("Time for %s: %.3f", DRL:GetRaceName(raceID), time))
    local playerGUID = UnitGUID("player")
    local raceData = self:GetRaceLeaderboardData(raceID)[playerGUID]
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
    if raceData.time <= 0 or time < raceData.time or (forceUpdate and time ~= raceData.time) then
        raceData.time = time
        raceData.achievedTimestamp = GetServerTime()
        self:SendModuleComm(COMM_KEY_GUILDY_NEW_PERSONAL_BEST_TIME, raceData, ns.consts.CHAT_CHANNEL.GUILD)
        self.LeaderboardUI:OnLeaderboardDataUpdated()
    end
end

---
--- Fired when a guild member achieves a new personal best time.
---
function DRL:OnGuildyNewPersonalBestCommReceived(data)
    local raceData = self.races[data.raceID]
    --local guildBestTime = ns.utils.MaxAttribute(self:GetRaceLeaderboardData(raceData.raceID), function(leaderboardEntry) return leaderboardEntry.time end)
    local position = 1
    for _, leaderboardEntry in pairs(self:GetRaceLeaderboardData(raceData.raceID)) do
        if leaderboardEntry.time < data.time then
            position = position + 1
        end
        -- We only care about reporting the top 3 places.
        if position > 3 then
            break
        end
    end
    self.moduleDB.leaderboardData[raceData.raceID][data.GUID] = data

    local msg = format("%s has achieved a new personal best for the '%s' dragon race: |cFFFFFFFF%.3fs|r", data.playerName, DRL:GetRaceName(raceData.raceID), data.time)
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
end
--endregion