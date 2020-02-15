--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local name, ns = ...
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
        showGuildmemberNewRecordNotification = true,

        sendGuildReceivedKeystoneNotification = true,
        sendGuildNewRecordNotification = true,

        leaderboardData = 
        {
            -- [GUID] = {GUID, playerName, classID, mapID, level, lastUpdateTimestamp}
        },

        guildKeys =
        {
             -- [GUID] = {GUID, playerName, classID, mapID, level, lastUpdateTimestamp}
        }
    }
}

local MythicPlus = WCCCAD:CreateModule("WCCC_MythicPlus", mythicPlusData)
LibStub("AceEvent-3.0"):Embed(MythicPlus) 

function MythicPlus:InitializeModule()
    MythicPlus:RegisterModuleSlashCommand("mythics", MythicPlus.MythicPlusCommand)
    MythicPlus:RegisterModuleSlashCommand("mythicplus", MythicPlus.MythicPlusCommand)
    MythicPlus:RegisterModuleSlashCommand("mp", MythicPlus.MythicPlusCommand)
    WCCCAD.UI:PrintAddOnMessage("Mythic Plus module loaded.")

    MythicPlus:RegisterModuleComm(COMM_KEY_GUILDY_RECEIVED_KEYSTONE, MythicPlus.OnGuildyReceivedKeystoneCommReceieved)
    MythicPlus:RegisterModuleComm(COMM_KEY_GUILDY_COMPLETED_KEYSTONE, MythicPlus.OnGuildyNewRecordCommReceived)
end

function MythicPlus:OnEnable()
    MythicPlus.initialSyncComplete = false
    MythicPlus:PruneOldEntries()

    MythicPlus:RegisterEvent("BAG_UPDATE", MythicPlus.ScheduleOwnKeystoneUpdate)
    MythicPlus:RegisterEvent("MYTHIC_PLUS_NEW_WEEKLY_RECORD", MythicPlus.OnNewWeeklyRecord)
    MythicPlus:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE", MythicPlus.ScheduleOwnKeystoneUpdate)
    MythicPlus:RegisterEvent("CHALLENGE_MODE_RESET", MythicPlus.ScheduleOwnKeystoneUpdate)
    MythicPlus:RegisterEvent("CHALLENGE_MODE_COMPLETED", MythicPlus.ScheduleOwnKeystoneUpdate)

    -- Bit of a heavy handed catch for reset. Ideally we should calculate the time until reset and start a timer on that.
    WCCCAD:ScheduleRepeatingTimer(MythicPlus.PruneOldEntries, PRUNE_TICK_INTERVAl)
end

function MythicPlus:OnDisable()
    MythicPlus:UnregisterEvent("BAG_UPDATE")
    MythicPlus:UnregisterEvent("MYTHIC_PLUS_NEW_WEEKLY_RECORD")
    MythicPlus:UnregisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
    MythicPlus:UnregisterEvent("CHALLENGE_MODE_RESET")
    MythicPlus:UnregisterEvent("CHALLENGE_MODE_COMPLETED")
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

    local mapID = mapChallengeModeID
    local keystoneLevel = level

    local GUID = UnitGUID("player")
    local className, classTag, classID = UnitClass("player")
    MythicPlus.moduleDB.leaderboardData[GUID] = 
    {
        GUID = GUID,
        playerName = UnitName("player"),
        classID = classID,
        mapID = mapID,
        level = keystoneLevel,
        lastUpdateTimestamp = GetServerTime()
    }

    MythicPlus:SendGuildyNewRecordComm(MythicPlus.moduleDB.leaderboardData[GUID])
    MythicPlus:InitiateSync()
    MythicPlus.UI:OnDataUpdated()

    WCCCAD.UI:PrintDebugMessage("Updating own weekly best: "..mapID.. " +"..keystoneLevel, MythicPlus.moduleDB.debugMode)
end

function MythicPlus:ScheduleOwnKeystoneUpdate()
    if not MythicPlus.updateKeystoneTimer then
        WCCCAD.UI:PrintDebugMessage("Scheduling keystone update.", MythicPlus.moduleDB.debugMode)

        MythicPlus.updateKeystoneTimer = WCCCAD:ScheduleTimer(
            function() 
                if not WCCCAD:CheckAddonActive(false) then
                    return
                end
                
                WCCCAD.UI:PrintDebugMessage("Triggering keystone update.", MythicPlus.moduleDB.debugMode)
                MythicPlus.updateKeystoneTimer = nil
                if not MythicPlus.initialSyncComplete then
                    MythicPlus.initialSyncComplete = true
                    MythicPlus:UpdateOwnKeystone()
                    MythicPlus:UpdateOwnWeeklyBest()
                    MythicPlus.UI:OnDataUpdated()
                    MythicPlus:InitiateSync()
                else
                    local isNewKeystone = MythicPlus:UpdateOwnKeystone()
                    if not isNewKeystone then
                        return
                    end
            
                    MythicPlus:SendGuildyReceivedKeystoneComm(MythicPlus.moduleDB.guildKeys[UnitGUID("player")])
                    MythicPlus:InitiateSync()
                    MythicPlus.UI:OnDataUpdated()
                end 
            end, 
        KEYSTONE_UPDATE_DELAY)
    end
end

---
--- Returns true if the new keystone is different to the previous one.
---
function MythicPlus:UpdateOwnKeystone()
    if not WCCCAD:CheckAddonActive(false) then
        return
    end

    local keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel()
    if keystoneLevel == nil then
        return false
    end

    -- Don't update if we're currently in a run since the key will show as downgraded already 
    -- and we don't want to update other users until the run is finished.
    local activeKeystoneLevel = C_ChallengeMode.GetActiveKeystoneInfo()
    if activeKeystoneLevel > 0 then
        WCCCAD.UI:PrintDebugMessage("Mythic in progress, skipping keystone update.", MythicPlus.moduleDB.debugMode)
        return false
    end

    local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()

    local GUID = UnitGUID("player")
    local className, classTag, classID = UnitClass("player")
    local prevKeystoneData = MythicPlus.moduleDB.guildKeys[GUID]
    MythicPlus.moduleDB.guildKeys[GUID] = 
    {
        GUID = GUID,
        playerName = UnitName("player"),
        classID = classID,
        mapID = mapID,
        level = keystoneLevel,
        lastUpdateTimestamp = GetServerTime()
    }

    local isNewKey = prevKeystoneData == nil or (prevKeystoneData.mapID ~= mapID or prevKeystoneData.level ~= keystoneLevel)
    WCCCAD.UI:PrintDebugMessage("Updating own key: "..mapID.. " +"..keystoneLevel .. " is new: " .. tostring(isNewKey), MythicPlus.moduleDB.debugMode)

    return isNewKey
end

---
--- Updates the leaderboardData for this player manually.
--- This is mainly intended to be used if the addon is installed after having run a key as MYTHIC_PLUS_NEW_WEEKLY_RECORD will handle future events.
---
function MythicPlus:UpdateOwnWeeklyBest()
    if not WCCCAD:CheckAddonActive(false) then
        return
    end

    local maps = C_ChallengeMode.GetMapTable()
    local highestLevel = 0
    local highestMapID = nil
    local playerName = UnitName("player")

    for _, mapID in pairs(maps) do
        local durationSec, level, completionDate, affixIDs, members = C_MythicPlus.GetWeeklyBestForMap(mapID)
        if members then
			for _, member in pairs(members) do
				if member.name == playerName then
					if level and level > highestLevel then
                        highestLevel = level
                        highestMapID = mapID
					end
					break
				end
			end
		end
    end

    local GUID = UnitGUID("player")
    local className, classTag, classID = UnitClass("player")
    MythicPlus.moduleDB.leaderboardData[GUID] = 
    {
        GUID = GUID,
        playerName = playerName,
        classID = classID,
        mapID = highestMapID,
        level = highestLevel,
        lastUpdateTimestamp = GetServerTime()
    }

end

---
--- Guildy keystone notification
---
function MythicPlus:SendGuildyReceivedKeystoneComm(keystoneData)
    if not MythicPlus.moduleDB.sendGuildReceivedKeystoneNotification then
        return
    end

    MythicPlus:SendModuleComm(COMM_KEY_GUILDY_RECEIVED_KEYSTONE, keystoneData, ns.consts.CHAT_CHANNEL.GUILD)
end

function MythicPlus:OnGuildyReceivedKeystoneCommReceieved(data)
    if not MythicPlus.moduleDB.showGuildMemberReceivedKeystoneNotification then
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
    if not MythicPlus.moduleDB.sendGuildNewRecordNotification then
        return
    end

    MythicPlus:SendModuleComm(COMM_KEY_GUILDY_COMPLETED_KEYSTONE, keystoneData, ns.consts.CHAT_CHANNEL.GUILD)
end

function MythicPlus:OnGuildyNewRecordCommReceived(data)
    if not MythicPlus.moduleDB.showGuildmemberNewRecordNotification then
        return
    end

    local dungeonName = C_ChallengeMode.GetMapUIInfo(data.mapID)

    local message = "{playerName} has completed {dungeonName} +{level}."
    message = message:gsub("{playerName}", data.playerName)
    message = message:gsub("{dungeonName}", dungeonName)
    message = message:gsub("{level}", data.level)

    WCCCAD.UI:PrintAddOnMessage(message, ns.consts.MSG_TYPE.GUILD)
end


--#region Player Entry Tools
function MythicPlus:PruneOldEntries(playerKeyTable)
    local dataChanged = false
    local lastResetTimestamp = ns.utils.GetLastServerResetTimestamp()

    for key, entryData in pairs(MythicPlus.moduleDB.leaderboardData) do
        if entryData.lastUpdateTimestamp < lastResetTimestamp then
            MythicPlus.moduleDB.leaderboardData[key] = nil
            dataChanged = true
        end
    end

    for key, entryData in pairs(MythicPlus.moduleDB.guildKeys) do
        if entryData.lastUpdateTimestamp < lastResetTimestamp then
            MythicPlus.moduleDB.guildKeys[key] = nil
            dataChanged = true
        end
    end

    if dataChanged then
        WCCCAD.UI:PrintDebugMessage("Pruned last season's M+ entries.", MythicPlus.moduleDB.debugMode)
        MythicPlus.UI:OnDataUpdated()
    end
end
--#endregion

--#region Weekly Leaderboard
---
--- Called when new data is received from a client.
---
function MythicPlus:UpdateLeaderboard(leaderboardData)
    local dataChanged = false
    for key, entryData in pairs(leaderboardData) do
        if MythicPlus.moduleDB.leaderboardData[key] == nil or MythicPlus.moduleDB.leaderboardData[key].lastUpdateTimestamp < entryData.lastUpdateTimestamp then
            MythicPlus.moduleDB.leaderboardData[key] = entryData
            dataChanged = true
        end
    end
    
    if dataChanged then
        MythicPlus.UI:OnDataUpdated()
    end
end
--#endregion

--#region Guild Keystones 

function MythicPlus:UpdateGuildKeys(guildKeys)
    local dataChanged = false
    for key, entryData in pairs(guildKeys) do
        if MythicPlus.moduleDB.guildKeys[key] == nil or MythicPlus.moduleDB.guildKeys[key].lastUpdateTimestamp < entryData.lastUpdateTimestamp then
            MythicPlus.moduleDB.guildKeys[key] = entryData
            dataChanged = true
        end
    end

    if dataChanged then
        MythicPlus.UI:OnDataUpdated()
    end
end

--#endregion

--#region Sync functions

function MythicPlus:GetSyncData() 
    -- Refresh updated timestamp.
    MythicPlus:UpdateOwnKeystone()

    local syncData =
    {
        leaderboardData = MythicPlus.moduleDB.leaderboardData,
        guildKeys = MythicPlus.moduleDB.guildKeys
    }

    return syncData
end

function MythicPlus:CompareSyncData(remoteData)
    return ns.consts.DATA_SYNC_RESULT.BOTH_NEWER
end

function MythicPlus:OnSyncDataReceived(data)    
    MythicPlus:UpdateLeaderboard(data.leaderboardData)
    MythicPlus:UpdateGuildKeys(data.guildKeys)

    MythicPlus.PruneOldEntries()
end

--#endregion