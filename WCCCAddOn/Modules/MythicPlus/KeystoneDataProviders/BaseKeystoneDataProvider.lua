--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD
local MythicPlus = WCCCAD:GetModule("WCCC_MythicPlus")

---
--- Creates a keystone provider object and returns it.
--- Add any required functions then call MythicPlus:RegisterKeystoneDataProvider to register the provider.
--- Providers have their own persistent DB as 'providerDB'
---
function MythicPlus:CreateKeystoneDataProvider(providerName)
    local provider =
    {
        providerName = providerName,
        debugMode = false,
        providerDB = {}
    }

    ---
    --- Internal: Called by the MythicPlus module when this module is initialised.
    --- Add initialise behaviour in InitializeProvider, not this function.
    ---
    function provider.OnInitialize(providerSelf)
        if not MythicPlus.moduleDB.keystoneDataProviders[providerSelf.providerName] then
            MythicPlus.moduleDB.keystoneDataProviders[providerSelf.providerName] = {}
        end
        providerSelf.providerDB = self.moduleDB.keystoneDataProviders[providerSelf.providerName]
        providerSelf:InitializeProvider()
    end

    ---
    --- Called when the MythicPlus module initialises.
    --- Override to implemented initialise behaviour.
    ---
    function provider.InitializeProvider(providerSelf)
    end

    ---
    --- Called when the UI updates its data for display.
    --- Add data from this provider into guildKeys and leaderboardData as required.
    --- @param guildKeys table<string, GuildKeyDataEntry> Table of guild key data. Add extra data to this for displaying on the UI.
    --- @param leaderboardData table<string, LeaderboardDataEntry> Table of guild leaderboard data. Add extra data to this for displaying on the UI.
    ---
    function provider.UpdateData(providerSelf, guildKeys, leaderboardData)

    end

    function provider.PrintDebugMessage(providerSelf, msg)
        WCCCAD.UI:PrintDebugMessage(format("[%s] %s", providerSelf.providerName, msg), providerSelf.debugMode)
    end

    return provider
end

---
--- Registers a provider with the MythicPlus module.
--- Only registered providers will receive events.
---
function MythicPlus:RegisterKeystoneDataProvider(provider)
    if not self.keystoneDataProviders then
        self.keystoneDataProviders = {}
    end

    table.insert(self.keystoneDataProviders, provider)
    if self.initialized then
        provider:OnInitialize()
    end
end