--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD
local WCCCADCore = WCCCAD:GetModule("WCCC_Core")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local WCCCAD_UI = {}

local WCCC_UI_CONFIG = 
{
    name = "WCCC Clubbing Companion",
    handler = WCCCAD,
    type = "group",
    args = 
    {
        logo = 
        {
            type = "description",
            name = "",
            image ="Interface\\AddOns\\WCCCAddOn\\assets\\wccc-header.tga",
            imageWidth=256,
            imageHeight=64,
            order = 0
        },

        wcccVersion = 
        {
            type = "description",
            fontSize = "small",
            name = function() return "Version " .. WCCCAD.versionString .. " - " .. WCCCAD.versionType.name end,
            order = 1
        },

        wcccNewVersionNotice = 
        {
            type = "description",
            fontSize = "medium",
            name = function() return "New version available, please update." end,
            hidden = function() return WCCCAD.newVersionAvailable == false end,
            order = 2
        },

        wcccDesc =
        {
            type = "description",
            fontSize = "medium",
            name = "\nOfficial AddOn of the <Worgen Cub Clubbing Club>.\
Participate in the Clubbing Competition along with more features to come!\
\
Accessing Modules:\
Click the '+' on the left hand panel next to 'WCCC Clubbing Companion' to access module windows such as the Clubbing Competition.\
\
Use the 'WCCC Companion' escape menu button or type '/wccc' to open this window.\
\
Happy Clubbing!\n\n",
            order = 3
        },

        mainSelect =
        {
            type = "select",
            name = "Select Main",
            hidden = function() return WCCCAD:CheckAddonActive(false) == false end,
            order = 4,
            values = function()
                local characterOptions = {}
                for GUID, characterData in pairs(WCCCADCore.moduleDB.localPlayerCharacters and WCCCADCore.moduleDB.localPlayerCharacters.characters or {}) do
                    characterOptions[GUID] = characterData.name
                end
                return characterOptions
            end,
            get = function()
                return WCCCADCore.moduleDB.localPlayerCharacters and WCCCADCore.moduleDB.localPlayerCharacters.main or "No characters found."
            end,
            set = function(options, key)
                WCCCADCore:SetPlayerCharacterMain(key)
            end
        },

        officerControlsPanel =
        {
            type = "group",
            name = "Officer Controls",
            inline = true,
            disabled = function() return WCCCAD:IsPlayerOfficer() == false end,
            hidden = function() return WCCCAD:IsPlayerOfficer() == false end,
            args =
            {
                toggleDebugMode =
                {
                    type = "toggle",
                    name = "Debug Mode",
                    desc = "Enable verbose debug logging.",
                    set = function(info, val)
                        WCCCADCore.moduleDB.debugMode = val
                    end,
                    get = function() return WCCCADCore.moduleDB.debugMode end,
                    disabled = function() return WCCCAD:IsPlayerOfficer() == false end,
                    hidden = function() return WCCCAD:IsPlayerOfficer() == false end,
                    order = 10.1
                },
            }
        }
    },
}


LibStub("AceConfig-3.0"):RegisterOptionsTable("WCCCAD", WCCC_UI_CONFIG)
WCCCAD_UI.optionsFrameRoot = AceConfigDialog:AddToBlizOptions("WCCCAD", "WCCC Clubbing Companion", nil)
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
    wcccModule.UI.optionsFrameRoot = AceConfigDialog:AddToBlizOptions(wcccModule.moduleName, moduleDisplayName, "WCCC Clubbing Companion")

    wcccModule.UI.Show = function() 
        AceConfigDialog:Open(wcccModule.moduleName)
    end

    return wcccModule.UI
end

function WCCCAD_UI:Show() 
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrameRoot)
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

    self:PrintAddOnMessage("[DEBUG] "..msg, ns.consts.MSG_TYPE.WARN)
end

---
--- Prints a notification saying the addon has been disabled.
---
function WCCCAD_UI:PrintAddonDisabledMessage()
    self:PrintAddOnMessage("Character not in the WCCC, addon commands will be disabled on this character.", ns.consts.MSG_TYPE.WARN)
end


--region Guild Controls Panel
function WCCCAD_UI:AddGuildControlButton(text, tooltipText, onClickAction) 
    if self.GuildControlFrame == nil then
        self:CreateGuildControlFrame()
    end

    local buttonsArray = self.GuildControlFrame.buttons
    local prevButton = buttonsArray and buttonsArray[#buttonsArray] or nil
    local buttonWidth = 150
    local leftMargin = 30
    local buttonPadding = 5

    local controlButton = CreateFrame("Button", nil, self.GuildControlFrame, "UIPanelButtonTemplate");
    controlButton:SetText(text)
    controlButton.tooltipText = tooltipText
    controlButton:SetSize(buttonWidth, 20)

    if prevButton then
        controlButton:SetPoint("LEFT", prevButton, "RIGHT", buttonPadding, 0)
    else
        controlButton:SetPoint("LEFT", self.GuildControlFrame, "LEFT", leftMargin, 0)
    end

    controlButton:RegisterForClicks("AnyUp")
    controlButton:SetScript("OnClick", onClickAction)

    tinsert(buttonsArray, controlButton)

    -- Adjust panel size.
    local totalButtonWidth = leftMargin
    for i=1, #buttonsArray do
        totalButtonWidth = totalButtonWidth + buttonsArray[i]:GetWidth() + buttonPadding
    end
    self.GuildControlFrame:SetWidth(totalButtonWidth)

    self.GuildControlFrame.buttons = buttonsArray
end

function WCCCAD_UI:CreateGuildControlFrame()
    local rootFrame = CreateFrame("Frame", nil, CommunitiesFrame, BackdropTemplateMixin and "BackdropTemplate")
    self.GuildControlFrame = rootFrame
    self.GuildControlFrame.buttons = {}

    rootFrame:SetPoint("TOPRIGHT", CommunitiesFrame, "BOTTOMRIGHT", 0, 0)
    rootFrame:SetWidth(300)
    rootFrame:SetHeight(35)
    rootFrame:SetMovable(false)
    rootFrame:SetResizable(false)
    rootFrame:SetBackdrop(
    {
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
        tile = true, tileSize = 16, edgeSize = 16, 
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    rootFrame:SetBackdropColor(0, 0, 0, 0.7)
    rootFrame:SetBackdropBorderColor(1, 0.62, 0, 0.8)

    rootFrame:SetScript("OnShow", function(frameSelf)
        if not WCCCAD:CheckAddonActive(false) then
            frameSelf:Hide()
        end
    end)

    --- Guild Logo
    local guildLogo = CreateFrame("Button", nil, rootFrame)
	guildLogo:SetNormalTexture("Interface\\AddOns\\WCCCAddOn\\assets\\wccc-logo.tga")
	guildLogo:SetPoint("TOPLEFT", 5, -5)
	guildLogo:SetWidth(24)
	guildLogo:SetHeight(24)
    guildLogo:SetScript("OnClick", function()
        WCCCAD.UI:Show() 
    end) 
end
--endregion