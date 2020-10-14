--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD


local COMM_KEY_GUILDY_RECEIVED_KEYSTONE = "guildyReceivedKeystone"
local COMM_KEY_GUILDY_COMPLETED_KEYSTONE = "guildyCompletedKeystone"

local PRUNE_TICK_INTERVAl = 60 * 30 -- 30 mins
local KEYSTONE_UPDATE_DELAY = 5

local mythicPlusData =
{
    profile =
    {
        showGuildMemberReceivedKeystoneNotification = true,
        showGuildMemberNewRecordNotification = true,

        sendGuildReceivedKeystoneNotification = true,
        sendGuildNewRecordNotification = true,

        ---@class LeaderboardDataEntry
        ---@field GUID string
        ---@field playerName string
        ---@field classID number
        ---@field mapID number
        ---@field level number
        ---@field lastUpdateTimestamp number

        ---@type table<string, LeaderboardDataEntry>
        leaderboardData = 
        {
            -- [GUID] = {GUID, playerName, classID, mapID, level, lastUpdateTimestamp}
        },

        ---@class GuildKeyDataEntry
        ---@field GUID string
        ---@field playerName string
        ---@field classID number
        ---@field mapID number
        ---@field level number
        ---@field lastUpdateTimestamp number

        ---@type table<string, GuildKeyDataEntry>
        guildKeys =
        {
             -- [GUID] = {GUID, playerName, classID, mapID, level, lastUpdateTimestamp}
        }
    }
}

local MythicPlus = WCCCAD:CreateModule("WCCC_MythicPlus", mythicPlusData)
LibStub("AceEvent-3.0"):Embed(MythicPlus) 

function MythicPlus:InitializeModule()
    self:RegisterModuleSlashCommand("mythics", self.MythicPlusCommand)
    self:RegisterModuleSlashCommand("mythicplus", self.MythicPlusCommand)
    self:RegisterModuleSlashCommand("mp", self.MythicPlusCommand)
    self:PrintDebugMessage("Mythic Plus module loaded.")

    self:RegisterModuleComm(COMM_KEY_GUILDY_RECEIVED_KEYSTONE, self.OnGuildyReceivedKeystoneCommReceived)
    self:RegisterModuleComm(COMM_KEY_GUILDY_COMPLETED_KEYSTONE, self.OnGuildyNewRecordCommReceived)
end

function MythicPlus:OnEnable()
    self.initialSyncComplete = false
    self:CheckLastTimestamps()
    self:PruneOldEntries()
    C_MythicPlus.RequestMapInfo()
    C_MythicPlus.RequestRewards()

    self:RegisterEvent("MYTHIC_PLUS_NEW_WEEKLY_RECORD", self.OnNewWeeklyRecord, self)
    self:RegisterEvent("BAG_UPDATE", self.ScheduleOwnKeystoneUpdate, self)
    self:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE", self.ScheduleOwnKeystoneUpdate, self)
    self:RegisterEvent("CHALLENGE_MODE_RESET", self.ScheduleOwnKeystoneUpdate, self)
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED", self.OnChallengeModeCompleted, self)

    self:RegisterEvent("GUILD_ROSTER_UPDATE", self.UI.OnGuildRosterUpdate, self.UI)

    --Bit of a heavy handed catch for reset. Ideally we should calculate the time until reset and start a timer on that.
    WCCCAD:ScheduleRepeatingTimer(function() self:PruneOldEntries() end, PRUNE_TICK_INTERVAl)
end

function MythicPlus:OnDisable()
    self:UnregisterEvent("BAG_UPDATE")
    self:UnregisterEvent("MYTHIC_PLUS_NEW_WEEKLY_RECORD")
    self:UnregisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
    self:UnregisterEvent("CHALLENGE_MODE_RESET")
    self:UnregisterEvent("CHALLENGE_MODE_COMPLETED")

    self:UnregisterEvent("GUILD_ROSTER_UPDATE")
end


function MythicPlus:MythicPlusCommand(args)
    if args ~= nil and args[1] ~= nil then
        if args[1] == "info" or args[1] == "settings" then
            self.UI:Show()
        end
        return 
    end

    self.UI:ShowWindow()
end

function MythicPlus:OnNewWeeklyRecord(mapChallengeModeID, completionMilliseconds, level)
    if not WCCCAD:CheckAddonActive(false) then
        return
    end

    -- For some reason the arguments for this event are always nil.
    local mapID = C_ChallengeMode.GetActiveChallengeMapID()
    local keystoneLevel = C_ChallengeMode.GetActiveKeystoneInfo()

    local GUID = UnitGUID("player")
    local _, _, classID = UnitClass("player")
    if self.moduleDB.leaderboardData[GUID] == nil or keystoneLevel > self.moduleDB.leaderboardData[GUID].level then
        self.moduleDB.leaderboardData[GUID] =
        {
            GUID = GUID,
            playerName = UnitName("player"),
            classID = classID,
            mapID = mapID,
            level = keystoneLevel,
            lastUpdateTimestamp = GetServerTime()
        }

        self:SendGuildyNewRecordComm(self.moduleDB.leaderboardData[GUID])
        self:InitiateSync()
        self.UI:OnDataUpdated()

        self:PrintDebugMessage(format("Updating own weekly best: %s +%i", (tostring(mapID) or "<NO MAPID>"), keystoneLevel))
    else
        self:PrintDebugMessage(format("New weekly map best (not overall weekly best): %s +%i", (tostring(mapID) or "<NO MAPID>"), keystoneLevel))
    end
end

function MythicPlus:OnChallengeModeCompleted()
    --- Force an update ignoring the active keystone when an M+ is completed.
    self:PrintDebugMessage("Forcing keystone update.")
    if self.updateKeystoneTimer ~= nil then
        WCCCAD:CancelTimer(self.updateKeystoneTimer)
    end
    self:ScheduleOwnKeystoneUpdate(false)
end

---
--- Schedules a player keystone update.
--- @param skipIfMythicInProgress boolean @[default=true] If true, the update will be skipped if a Mythic+ is in progress
---
function MythicPlus:ScheduleOwnKeystoneUpdate(skipIfMythicInProgress)
    if not self.updateKeystoneTimer then
        self:PrintDebugMessage("Scheduling keystone update.")

        self.updateKeystoneTimer = WCCCAD:ScheduleTimer(
            function() 
                if not WCCCAD:CheckAddonActive(false) then
                    return
                end

                self:PrintDebugMessage("Triggering keystone update.")
                self.updateKeystoneTimer = nil
                if not self.initialSyncComplete then
                    self.initialSyncComplete = true
                    self:UpdateOwnKeystone()
                    self:UpdateOwnWeeklyBest()
                    self.UI:OnDataUpdated()
                    self:InitiateSync()
                else
                    self:UpdateOwnKeystone(skipIfMythicInProgress)
                end 
            end, 
        KEYSTONE_UPDATE_DELAY)
    end
end

---
--- Update the player's keystone, triggering events if it's new.
--- @param skipIfMythicInProgress boolean @[default=true] If true, the update will be skipped if a Mythic+ is in progress
---
function MythicPlus:UpdateOwnKeystone(skipIfMythicInProgress)
    if skipIfMythicInProgress == nil then
        skipIfMythicInProgress = true
    end

    if not WCCCAD:CheckAddonActive(false) then
        return
    end

    local keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel()
    if keystoneLevel == nil then
        return false
    end

    -- Don't update if we're currently in a run since the key will show as downgraded already
    -- and we don't want to update other users until the run is finished.
    -- Note, C_ChallengeMode.IsChallengeModeActive() cannot be used as it returns false if the dungeon is exited when
    -- the run is still in progress.
    local activeKeystoneLevel = C_ChallengeMode.GetActiveKeystoneInfo()
    if activeKeystoneLevel > 0 and skipIfMythicInProgress then
        self:PrintDebugMessage("Mythic in progress, skipping keystone update.")
        return false
    end

    local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()

    local GUID = UnitGUID("player")
    local _, _, classID = UnitClass("player")
    local prevKeystoneData = self.moduleDB.guildKeys[GUID]
    self.moduleDB.guildKeys[GUID] = 
    {
        GUID = GUID,
        playerName = UnitName("player"),
        classID = classID,
        mapID = mapID,
        level = keystoneLevel,
        lastUpdateTimestamp = GetServerTime()
    }

    local isNewKey = prevKeystoneData == nil 
        or (prevKeystoneData.mapID ~= mapID 
        or prevKeystoneData.level ~= keystoneLevel)

    self:PrintDebugMessage(format("Updating own key: %i +%i is new: %s",
            mapID, 
            keystoneLevel,
            tostring(isNewKey)))

    if isNewKey then
        self:SendGuildyReceivedKeystoneComm(self.moduleDB.guildKeys[UnitGUID("player")])
        self:InitiateSync()
        self.UI:OnDataUpdated()
    end
end

---
--- Updates the leaderboardData for this player manually.
--- This is mainly intended to be used if the addon is installed after having run a key as MYTHIC_PLUS_NEW_WEEKLY_RECORD will handle future events.
---
function MythicPlus:UpdateOwnWeeklyBest()
    if not WCCCAD:CheckAddonActive(false) then
        return
    end

    self:PrintDebugMessage("Updating weekly best (scan).")

    -- Using the level from the reward as, for whatever reason, the weekly best data can get corrupted(?) and won't contain the correct reward level or map.
    local weekBestLevel = C_MythicPlus.GetWeeklyChestRewardLevel()
    local highestMapID = nil
    local playerName = UnitName("player")

    self:PrintDebugMessage("Weekly Chest Level: " .. weekBestLevel)

    local hasWeeklyRun = false
    local maps = C_ChallengeMode.GetMapTable()
    for _, mapID in pairs(maps) do
        local _, level, _, _, members = C_MythicPlus.GetWeeklyBestForMap(mapID)
        if members then
            for _, member in pairs(members) do
                if member.name == playerName then
                    self:PrintDebugMessage("Found weekly best for " .. mapID .. " +" .. level)
                    hasWeeklyRun = true
                    if highestMapID == nil or (level and level > weekBestLevel) then
                        highestMapID = mapID
                        break
                    end
                end
            end
        end
    end

    local GUID = UnitGUID("player")
    local _, _, classID = UnitClass("player")
    if not hasWeeklyRun then
        self:PrintDebugMessage("No weekly run found.")
        self.moduleDB.leaderboardData[GUID] = nil
    else
        self.moduleDB.leaderboardData[GUID] =
        {
            GUID = GUID,
            playerName = playerName,
            classID = classID,
            mapID = highestMapID,
            level = weekBestLevel,
            lastUpdateTimestamp = GetServerTime()
        }
    end
end

---
--- Guildy keystone notification
---
function MythicPlus:SendGuildyReceivedKeystoneComm(keystoneData)
    if not self.moduleDB.sendGuildReceivedKeystoneNotification then
        return
    end

    self:SendModuleComm(COMM_KEY_GUILDY_RECEIVED_KEYSTONE, keystoneData, ns.consts.CHAT_CHANNEL.GUILD)
end

function MythicPlus:OnGuildyReceivedKeystoneCommReceived(data)
    if not self.moduleDB.showGuildMemberReceivedKeystoneNotification then
        return
    end

    local dungeonName = C_ChallengeMode.GetMapUIInfo(data.mapID)

    local message = "{playerName} received a Mythic Keystone: {dungeonName} +{level}."
    message = message:gsub("{playerName}", data.playerName)
    message = message:gsub("{dungeonName}", dungeonName)
    message = message:gsub("{level}", data.level)

    WCCCAD.UI:PrintAddOnMessage(message, ns.consts.MSG_TYPE.GUILD)
end

function MythicPlus:SendGuildyNewRecordComm(keystoneData)
    if not self.moduleDB.sendGuildNewRecordNotification then
        return
    end

    self:SendModuleComm(COMM_KEY_GUILDY_COMPLETED_KEYSTONE, keystoneData, ns.consts.CHAT_CHANNEL.GUILD)
end

function MythicPlus:OnGuildyNewRecordCommReceived(data)
    if not self.moduleDB.showGuildMemberNewRecordNotification then
        return
    end

    local dungeonName = data.mapID and C_ChallengeMode.GetMapUIInfo(data.mapID) or nil

    local message = "{playerName} has earned a new weekly best: +{level}{dungeonName}."
    message = message:gsub("{playerName}", data.playerName)
    message = message:gsub("{dungeonName}", dungeonName and (" "..dungeonName) or "")
    message = message:gsub("{level}", data.level)

    WCCCAD.UI:PrintAddOnMessage(message, ns.consts.MSG_TYPE.GUILD)
end

---
--- A fun little bug. For some reason, we've seen lastUpdateTimestamps synced that are > GetServerTime() by a long margin.
---
function MythicPlus:CheckLastTimestamps()
    local currentTime = GetServerTime()
    for key, entryData in pairs(self.moduleDB.leaderboardData) do
        if entryData.lastUpdateTimestamp > currentTime then
            self.moduleDB.leaderboardData[key] = nil
            dataChanged = true
        end
    end

    for key, entryData in pairs(self.moduleDB.guildKeys) do
        if entryData.lastUpdateTimestamp > currentTime then
            self.moduleDB.guildKeys[key] = nil
            dataChanged = true
        end
    end

    if dataChanged then
        self:PrintDebugMessage("Removed invalid lastUpdateTimestamp.")
        self.UI:OnDataUpdated()
    end
end

--region Player Entry Tools
function MythicPlus:PruneOldEntries()
    local dataChanged = false
    local lastResetTimestamp = ns.utils.GetLastServerResetTimestamp()

    for key, entryData in pairs(self.moduleDB.leaderboardData) do
        -- TODO: Mangofox has some weird timestamps so with the new system of discarding timestamps > current time, we need to just get rid of these broken entries first since they keep getting udpated.
        -- TODO: This must be removed in a future update...
        if entryData.lastUpdateTimestamp < lastResetTimestamp or entryData.playerName == "Mangofox" then
            self.moduleDB.leaderboardData[key] = nil
            dataChanged = true
        end
    end

    for key, entryData in pairs(self.moduleDB.guildKeys) do
        if entryData.lastUpdateTimestamp < lastResetTimestamp or entryData.playerName == "Mangofox" then
            self.moduleDB.guildKeys[key] = nil
            dataChanged = true
        end
    end

    if dataChanged then
        self:PrintDebugMessage("Pruned last season's M+ entries.")
        self.UI:OnDataUpdated()
    end
end
--endregion

--region Weekly Leaderboard
---
--- Called when new data is received from a client.
---
function MythicPlus:UpdateLeaderboard(leaderboardData)
    local dataChanged = false
    local currentTime = GetServerTime()
    for key, entryData in pairs(leaderboardData) do
        -- Somehow, we've seen people have timestamps from waaaay in the future. No idea how.
        -- TODO: Mangofox - Remove
        if entryData.lastUpdateTimestamp <= currentTime and entryData.playerName ~= "Mangofox" then
            if self.moduleDB.leaderboardData[key] == nil or self.moduleDB.leaderboardData[key].lastUpdateTimestamp < entryData.lastUpdateTimestamp then
                self.moduleDB.leaderboardData[key] = entryData
                dataChanged = true
            end
        end
    end

    if dataChanged then
        MythicPlus.UI:OnDataUpdated()
    end
end
--endregion

--region Guild Keystones

function MythicPlus:UpdateGuildKeys(guildKeys)
    local dataChanged = false
    local currentTime = GetServerTime()
    for key, entryData in pairs(guildKeys) do
        -- Somehow, we've seen people have timestamps from waaaay in the future. No idea how.
        -- TODO: Mangofox - Remove
        if entryData.lastUpdateTimestamp <= currentTime and entryData.playerName ~= "Mangofox" then
            if self.moduleDB.guildKeys[key] == nil or self.moduleDB.guildKeys[key].lastUpdateTimestamp < entryData.lastUpdateTimestamp then
                self.moduleDB.guildKeys[key] = entryData
                dataChanged = true
            end
        end
    end

    if dataChanged then
        self.UI:OnDataUpdated()
    end
end

--endregion

--region Sync functions

function MythicPlus:GetSyncData() 
    -- Refresh updated timestamp.
    self:UpdateOwnKeystone()

    local syncData =
    {
        leaderboardData = self.moduleDB.leaderboardData,
        guildKeys = self.moduleDB.guildKeys
    }

    return syncData
end

function MythicPlus:CompareSyncData(remoteData)
    return ns.consts.DATA_SYNC_RESULT.BOTH_NEWER
end

function MythicPlus:OnSyncDataReceived(data)    
    self:UpdateLeaderboard(data.leaderboardData)
    self:UpdateGuildKeys(data.guildKeys)

    self:PruneOldEntries()
end

--endregion