--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local name, ns = ...
local WCCCAD = ns.WCCCAD
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local WCCCAD_UI = {}

local UI_CHAT_CHANNEL_NAME = 
{
    EMOTE = "Emote",
    SAY = "Say",
    YELL = "Yell",
    GUILD = "Guild",
    PARTY = "Party",
    RAID = "Raid",
    INSTANCE_CHAT = "Instance Chat"
}

local WCCC_UI_CONFIG = 
{
    name = "Worgen Cub Clubbing Club",
    handler = WCCCAD,
    type = "group",
    args = 
    {
        wcccDesc = 
        {
            type = "description",
            fontSize = "medium",
            name = "Official AddOn of the <Worgen Cub Clubbing Club>.\nParticipate in the Clubbing Competition along with more features to come!\nClick the '+' on the left hand panel to access module windows, such as the Clubbing Competition.",
            order = 0
        },

        group =
        {
            type = "group",
            name = "Club Usage and Useful Macro",
            inline = true,
            order = 1,
            args = 
            {
                wcccMacroDesc = 
                {
                    type = "description",
                    name = "A useful macro for using the addon and the commands you can use: \n Left click: Use club (/wccc club) \n Ctrl+click: Open Clubbing Competition UI (/wccc club info) \n Alt+click: Open WCCC AddOn UI (this window) (/wccc).",
                    order = 1.01
                },

                wcccMacro = 
                {
                    type = "input",
                    name = "Useful Macro",
                    width = "full",
                    multiline = 2,
                    get = function() return "/run if IsControlKeyDown() then hash_SlashCmdList[\"/WCCC\"](\"club info\") elseif IsAltKeyDown() then hash_SlashCmdList[\"/WCCC\"](\"\") else hash_SlashCmdList[\"/WCCC\"](\"club\") end" 
                    end,
                    order = 1.02
                },
            },
        },

        settingsPanel = 
        {
            type = "group",
            name = "Settings",
            inline = true,
            order = 10,
            args =
            {
                toggleDebugMode = 
                {
                    type = "toggle",
                    name = "Debug Mode",
                    desc = "Enable verbose debug logging.",
                    set = function(info, val) WCCCAD.db.profile.debugMode = val end,
                    get = function() return WCCCAD.db.profile.debugMode end,
                    disabled = function() return WCCCAD:IsPlayerOfficer() == false end,
                    hidden = function() return WCCCAD:IsPlayerOfficer() == false end,
                    order = 10.1
                },
            }
        },
    },
}


LibStub("AceConfig-3.0"):RegisterOptionsTable("WCCCAD", WCCC_UI_CONFIG)
WCCCAD_UI.optionsFrameRoot = AceConfigDialog:AddToBlizOptions("WCCCAD", "Worgen Cub Clubbing Club", nil)
WCCCAD.UI = WCCCAD_UI
-- Profiles options
--WCCC_UI_CONFIG.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(WCCCAD.db)
--LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WCCCAD", "Profiles", "WCCCAD", "profiles")


---
--- Creates a sub panel for the module using the specified UI config and creates and returns an object for the UI.
--- This object will be set to the UI field in the specified module (wcccModule.UI)
--- Usage example:
---     local module = WCCCAD:GetModule("ModuleName")
---     local moduleUI = WCCCAD.UI:LoadModule(module, "Module Name", UIConfig)
--      module.UI == moduleUI
---
function WCCCAD_UI:LoadModuleUI(wcccModule, moduleDisplayName, moduleUIConfig)
    wcccModule.UI = {}

    LibStub("AceConfig-3.0"):RegisterOptionsTable(wcccModule.moduleName, moduleUIConfig)
    wcccModule.UI.optionsFrameRoot = AceConfigDialog:AddToBlizOptions(wcccModule.moduleName, moduleDisplayName, "Worgen Cub Clubbing Club")

    wcccModule.UI.Show = function() 
        AceConfigDialog:Open(wcccModule.moduleName)
    end

    return wcccModule.UI
end

function WCCCAD_UI:Show() 
    InterfaceOptionsFrame_OpenToCategory(WCCCAD.UI.optionsFrameRoot)
end

function WCCCAD_UI:PrintAddOnMessage(msg, type)
    local outputStr = "|cFFE97300 [WCCC]|r "
    if type == ns.consts.MSG_TYPE.WARN then
        outputStr = outputStr .. "|cFFE9D500"
    elseif type == ns.consts.MSG_TYPE.ERROR then
        outputStr = outputStr .. "|cFFE91100[ERROR] "
    elseif type == ns.consts.MSG_TYPE.GUILD then
        outputStr = outputStr .. "|cFF00D42D "    
    end

    outputStr = outputStr .. msg .. "|r"

    print(outputStr)
end

function WCCCAD_UI:PrintDebugMessage(msg, debuggingEnabled) 
    if debuggingEnabled == false then
        return
    end

    WCCCAD_UI:PrintAddOnMessage("[DEBUG] "..msg, ns.consts.MSG_TYPE.WARN)
end

---
--- Prints a notification saying the addon has been disabled.
--- If addonActive is true, this does nothing.
---
function WCCCAD_UI:PrintAddonDisabledMessage()    
    if WCCCAD.addonActive == true then
        return
    end
    WCCCAD:PrintAddOnMessage("Character not in the WCCC, addon commands will be disabled on this character.", ns.consts.MSG_TYPE.WARN)
end