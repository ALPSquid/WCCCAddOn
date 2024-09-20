--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
-- Adds OpenRaidLib keystone data for guild members without this AddOn.
--

local _, ns = ...
local WCCCAD = ns.WCCCAD
local MythicPlus = WCCCAD:GetModule("WCCC_MythicPlus")

local OpenRaidLib = LibStub:GetLibrary("LibOpenRaid-1.0")
if not OpenRaidLib then
    return
end

local orlProvider = MythicPlus:CreateKeystoneDataProvider("OpenRaidLibProvider")
--orlProvider.debugMode = true

function orlProvider:InitializeProvider()
    if not self.providerDB.keyData then
        self.providerDB.keyData = {}
    end
    OpenRaidLib.RegisterCallback(self, "KeystoneUpdate", "OnKeystoneUpdate")
    WCCC_MythicPlus_Frame:HookScript("OnShow", function(uiFrame)
        OpenRaidLib.RequestKeystoneDataFromGuild()
    end)
end

function orlProvider:OnKeystoneUpdate(unitId, keystoneInfo, allKeystonesInfo)
    MythicPlus.UI:OnDataUpdated()
end

function orlProvider:UpdateData(guildKeys, leaderboardData)
    -- Insert OpenRaidLib data.
    -- Since it doesn't provide a GUID, we can't merge data so we'll just tack it on at the UI level.
    --
    -- ORL player names have the realm attached if it's different from the local player
    -- whereas the guild addon data doesn't provide the realm because it uses GUIDs.

    -- Get all guild members to filter ORL data by guild.
    local guildName = GetGuildInfo("player")
    if not guildName then
        return
    end

    local guildMembers = {}
    local totalMembers = GetNumGuildMembers()
    for i=1, totalMembers do
        local guildPlayerName = GetGuildRosterInfo(i)
        if guildPlayerName then
            -- Remove the realm name to match guild addon data.
            guildMembers[guildPlayerName:gsub("%-.*", "")] = true
        end
    end

    -- Update cached data for guild members.
    local orlKeystoneData = OpenRaidLib.GetAllKeystonesInfo()
    for orlPlayerName, orlKeystoneInfo in pairs(orlKeystoneData) do
        orlPlayerName = orlPlayerName:gsub("%-.*", "")
        if guildMembers[orlPlayerName] then
            orlKeystoneInfo.lastUpdateTimestamp = GetServerTime()
            self.providerDB.keyData[orlPlayerName] = orlKeystoneInfo
        end
    end

    -- Add ORL data if we don't have guild addon data for that player.
    local lastResetTimestamp = ns.utils.GetLastServerResetTimestamp()
    for orlPlayerName, orlKeystoneInfo in pairs(self.providerDB.keyData) do
        if orlKeystoneInfo.challengeMapID ~= 0 then
            local addPlayer = true
            if orlKeystoneInfo.lastUpdateTimestamp < lastResetTimestamp then
                addPlayer = false
            else
                for _, entryData in pairs(guildKeys) do
                    if entryData.playerName == orlPlayerName then
                        self:PrintDebugMessage(orlPlayerName.." has guild addon data. Skipping.")
                        addPlayer = false
                        break
                    end
                end
            end
            if addPlayer then
                self:PrintDebugMessage(format("Adding player: '%s' - %i +%i", orlPlayerName, orlKeystoneInfo.challengeMapID, orlKeystoneInfo.level))
                -- Update UI data.
                guildKeys[orlPlayerName] =
                {
                    GUID = orlPlayerName,
                    playerName = orlPlayerName,
                    classID = orlKeystoneInfo.classID,
                    mapID = orlKeystoneInfo.challengeMapID,
                    level = orlKeystoneInfo.level,
                    lastUpdateTimestamp = orlKeystoneInfo.lastUpdateTimestamp
                }
            end
        end
    end
end

MythicPlus:RegisterKeystoneDataProvider(orlProvider)