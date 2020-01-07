--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local name, ns = ...
local WCCCAD = ns.WCCCAD


local COMM_KEY_GUILDY_RECEIVED_KEYSTONE = "guildyReceivedKeystone"
local COMM_KEY_GUILDY_COMPLETED_KEYSTONE = "guildyCompletedKeystone"

local mythicPlusData = 
{
    profile =
    {
        showGuildMemberReceivedKeystoneNotification = true,
        showGuildMemberCompletedKeystoneNotification = true,

        sendGuildReceivedKeystoneNotification = true,
        sendGuildCompletedKeystoneNotification = true,

        leaderboardData = 
        {
            -- [playerID] = {playerName, dungeonName, level}
        },

        guildKeys =
        {
             -- [playerID] = {playerName, dungeonName, level, lastUpdateTimestamp}
        }
    }
}

local MythicPlus = WCCCAD:CreateModule("WCCC_MythicPlus", mythicPlusData)

function MythicPlus:InitializeModule()
    MythicPlus:RegisterModuleSlashCommand("mythics", MythicPlus.MythicPlusCommand)
    MythicPlus:RegisterModuleSlashCommand("mythicplus", MythicPlus.MythicPlusCommand)
    MythicPlus:RegisterModuleSlashCommand("m+", MythicPlus.MythicPlusCommand)
    WCCCAD.UI:PrintAddOnMessage("Mythic Plus module loaded.")

    MythicPlus:RegisterModuleComm(COMM_KEY_GUILDY_RECEIVED_KEYSTONE, MythicPlus.OnGuildyReceivedKeystoneCommReceieved)
    MythicPlus:RegisterModuleComm(COMM_KEY_GUILDY_COMPLETED_KEYSTONE, MythicPlus.OnGuildyCompletedKeystoneCommReceieved)
end

function MythicPlus:OnEnable()
    MythicPlus:PruneOldEntries()
    MythicPlus:InitiateSync()

    WCCCAD:ScheduleTimer(function() MythicPlus:PruneOldEntries() end, tickIntervalSecs)
end


function MythicPlus:MythicPlusCommand(args)
    self.UI:Show()
end

---
--- Guildy keystone notification
---
function MythicPlus:SendGuildyReceivedKeystoneComm(keystoneData)
    if MythicPlus.moduleDB.sendGuildReceivedKeystoneNotification == false then
        return
    end

    local playerName = UnitName("player")
    local data = 
    {
        playerName = playerName,
        dungeonName = keystoneData.dungeonName,
        level = keystoneData.level
    }

    MythicPlus:SendModuleComm(COMM_KEY_GUILDY_RECEIVED_KEYSTONE, data, ns.consts.CHAT_CHANNEL.GUILD)
end

function MythicPlus:OnGuildyReceivedKeystoneCommReceieved(data)
    if MythicPlus.moduleDB.showGuildMemberReceivedKeystoneNotification == false then
        return
    end    

    local message = "{playerName} received a Mythic Keystone: {dungeonName} +{level}."
    message = message:gsub("{playerName}", data.playerName)
    message = message:gsub("{dungeonName}", data.dungeonName)
    message = message:gsub("{level}", data.level)

    WCCCAD.UI:PrintAddOnMessage(message, ns.consts.MSG_TYPE.GUILD)
end

function MythicPlus:SendGuildyCompletedKeystoneComm(keystoneData)
    if MythicPlus.moduleDB.sendGuildCompletedKeystoneNotification == false then
        return
    end

    local playerName = UnitName("player")
    local data = 
    {
        playerName = playerName,
        dungeonName = keystoneData.dungeonName,
        level = keystoneData.level
    }

    MythicPlus:SendModuleComm(COMM_KEY_GUILDY_COMPLETED_KEYSTONE, data, ns.consts.CHAT_CHANNEL.GUILD)
end

function MythicPlus:OnGuildyCompletedKeystoneCommReceieved(data)
    if MythicPlus.moduleDB.showGuildMemberCompletedKeystoneNotification == false then
        return
    end    

    -- TODO: Change to new highest this week.
    local message = "{playerName} has completed {dungeonName} +{level}."
    message = message:gsub("{playerName}", data.playerName)
    message = message:gsub("{dungeonName}", data.dungeonName)
    message = message:gsub("{level}", data.level)

    WCCCAD.UI:PrintAddOnMessage(message, ns.consts.MSG_TYPE.GUILD)
end


--#region Player Entry Tools
function MythicPlus:PruneOldEntries(playerKeyTable)
    local lastResetTimestamp = ns.utils.GetLastServerResetTimestamp()

    for key, entryData in pairs(MythicPlus.moduleDB.leaderboardData) do
        if entryData.lastUpdateTimestamp < lastResetTimestamp then
            MythicPlus.moduleDB.leaderboardData[key] = nil
        end
    end

    for key, entryData in pairs(MythicPlus.moduleDB.guildKeys) do
        if entryData.lastUpdateTimestamp < lastResetTimestamp then
            MythicPlus.moduleDB.guildKeys[key] = nil
        end
    end
end
--#endregion

--#region Weekly Leaderboard
---
--- Called when new data is received from a client.
---
function MythicPlus:UpdateLeaderboard(leaderboardData)
    for key, entryData in pairs(leaderboardData) do
        if MythicPlus.moduleDB.leaderboardData[key] == nil or MythicPlus.moduleDB.leaderboardData[key].lastUpdateTimestamp < entryData.lastUpdateTimestamp then
            MythicPlus.moduleDB.leaderboardData[key] = entryData
        end
    end
end
--#endregion

--#region Guild Keystones 

function MythicPlus:UpdateGuildKeys(guildKeys)
    for key, entryData in pairs(guildKeysData) do
        if MythicPlus.moduleDB.guildKeys[key] == nil or MythicPlus.moduleDB.guildKeys[key].lastUpdateTimestamp < entryData.lastUpdateTimestamp then
            MythicPlus.moduleDB.guildKeys[key] = entryData
        end
    end
end

--#endregion

--#region Sync functions

function MythicPlus:GetSyncData() 
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