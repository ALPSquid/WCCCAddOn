--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--

local name, ns = ...

local WCCCAD = LibStub("AceAddon-3.0"):NewAddon("Worgen Cub Clubbing Club", "AceConsole-3.0", "AceEvent-3.0", "AceSerializer-3.0", "AceComm-3.0")

ns.WCCCAD = WCCCAD
ns.modules = {}

local dataDefaults = 
{
    profile = 
    {

    }
}

function WCCCAD:OnInitialize()
        -- Addon is deactivated if the player is not in the WCCC.
        WCCCAD.addonActive = true;

        -- Custom root commands set by modules. Any args parsed to /wccc command are checked against this table.
        WCCCAD.moduleCommands = {}

        -- Load database
        WCCCAD.db = LibStub("AceDB-3.0"):New("WCCCDB", dataDefaults, true)

        WCCCAD:RegisterComm("WCCCAD")        
end

function WCCCAD:OnEnable()
    WCCCAD:RegisterChatCommand("wccc", "WCCCCommand")

    WCCCAD:RegisterEvent("GUILD_ROSTER_UPDATE", "OnGuildRosterUpdate")
    WCCCAD:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteredWorld")
end

function WCCCAD:OnDisable()
    WCCCAD:UnregisterChatCommand("wccc")

    WCCCAD:UnregisterEvent("GUILD_ROSTER_UPDATE")
    WCCCAD:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

---
--- Register a slash command for a module. This is the first argument entered after "/wccc"
--- Use ModuleBase.RegisterModuleSlashCommand for convenience.
---
function WCCCAD:RegisterModuleSlashCommand(moduleObj, command, func) 
    WCCCAD.moduleCommands[command] = function(args) func(moduleObj, args) end
end

---
-- Generic chat command, opens the config panel when the wccc command is entered.
--
function WCCCAD:WCCCCommand(input)
    local args = {}
    for word in input:gmatch("%w+") do 
        table.insert(args, word) 
    end

    -- Open UI if no args were passed.
    if args == nil or next(args) == nil then
        WCCCAD.UI:Show()

        WCCCAD:CheckAddonActive()
    else 
        if WCCCAD:CheckAddonActive() == false then
            return
        end

        local moduleCmd = args[1]
        local cmdFunc = WCCCAD.moduleCommands[moduleCmd]
        if cmdFunc ~= nil then
            table.remove(args, 1)
            cmdFunc(args)
        end
    end
end

function WCCCAD:OnGuildRosterUpdate()
    WCCCAD:CheckGuild()
end

function WCCCAD:OnPlayerEnteredWorld()
    WCCCAD:CheckGuild()
end

---
--- Checks the player's current guild, disabling the addon if they are not in the WCCC.
--- 
function WCCCAD:CheckGuild()
    local guildName = GetGuildInfo("player")
    if guildName == nil or guildName ~= "Worgen Cub Clubbing Club" and WCCCAD.addonActive == true then
        WCCCAD.UI:PrintAddonDisabledMessage()
        WCCCAD.addonActive = false;
    elseif guildName == "Worgen Cub Clubbing Club" and WCCCAD.addonActive == false then
        WCCCAD.UI:PrintAddOnMessage("AddOn Loaded. Type /wccc for options.")
        WCCCAD.addonActive = true;
    end
end

---
--- Returns whether the addon is active (enabled for the current character).
--- If printMsg is true and the addon is disabled, the disabled message will be shown.
--- This is used to prevent commands if we're "disabled".
--- @param printMsg - Whether to print the addon disabled message.
--- 
function WCCCAD:CheckAddonActive(printMsg) 
    if printMsg then
        WCCCAD.UI:PrintAddonDisabledMessage() 
    end
    return WCCCAD.addonActive
end

function WCCCAD:IsPlayerOfficer()
    local guildName, rankName, rankIdx = GetGuildInfo("player")
    if guildName == nil then
        return false
    end

    return rankIdx <= 2
end


---
--- AddOn Comms API
--- For modules, use the methods included in the ModuleBase for auto filtering and custom callbacks.
---
WCCCAD.moduleCommBindings =
{
    -- [module] = { [messageKey] = func }
}

---
--- Bind module function for a specific message key. Callback will be passed the message deserialized data.
---
function WCCCAD:RegisterModuleComm(moduleObj, moduleName, messageKey, func)
    if WCCCAD.moduleCommBindings[moduleName] == nil then
        WCCCAD.moduleCommBindings[moduleName] = {}
    end
    
    -- TODO: Error about table being passed to format??
    if WCCCAD.moduleCommBindings[moduleName][messageKey] ~= nil then
        WCCCAD.UI:PrintAddOnMessage(format("Multiple comms registered for %s.%s, this should not happen! Please let Aerthok know.", moduleName, messageKey), ns.consts.MSG_TYPE.ERROR)
        return
    end

    WCCCAD.moduleCommBindings[moduleName][messageKey] = function(data) func(moduleObj, data) end
end

---
--- Send a module comms message. 
--- Data can be an object and will be automatically  serialized on send and deserialized on receive.
-- @param targetplayer only used for whisper channel.
---
function WCCCAD:SendModuleComm(moduleName, messageKey, data, channel, targetPlayer)
    local modulePrefix = format("%s[WCCCMOD]%s[WCCCKEY]", moduleName, messageKey)
    
    local serialisedData = WCCCAD:Serialize(data)
    serialisedData = modulePrefix..serialisedData

    WCCCAD:SendCommMessage("WCCCAD", serialisedData, channel, targetPlayer)
end

function WCCCAD:OnCommReceived(prefix, message, distribution, sender)
    if prefix ~= "WCCCAD" then
        return
    end

    local moduleName, messageKey, messageData = string.match(message, "(.-)%[WCCCMOD%](.-)%[WCCCKEY%](.+)")

    -- If no module attributes were found it's a core message so just use the original data.
    if messageData == nil then
        messageData = message
    end    

    if WCCCAD.moduleCommBindings[moduleName] == nil or WCCCAD.moduleCommBindings[moduleName][messageKey] == nil then
        return
    end

    local success, deserialisedData = WCCCAD:Deserialize(messageData)
    WCCCAD.moduleCommBindings[moduleName][messageKey](deserialisedData)    
end