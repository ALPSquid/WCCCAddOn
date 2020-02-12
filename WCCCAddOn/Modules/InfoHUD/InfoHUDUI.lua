--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local name, ns = ...
local WCCCAD = ns.WCCCAD

local InfoHUD = WCCCAD:GetModule("WCCC_InfoHUD")

local INFOHUD_UI_CONFIG = 
{
    name = "Info HUD",
    handler = InfoHUD,
    type = "group",
    childGroups = "tab",    
    args = 
    {
        logo = 
        {
            type = "description",
            name = "",
            image ="Interface\\AddOns\\WCCCAddOn\\assets\\wccc-header-infohud.tga",
            imageWidth=256,
            imageHeight=64,
            order = 0
        },

        helpPanel = 
        {
            type = "group",
            name = "How to Use",
            order = 8,
            args =
            {
                helpText = 
                {
                    type = "description",
                    fontSize = "medium",
                    name = "The WCCC Info HUD is an overlay window for showing guild-wide and raid-wide messages from officers. This is used for showing info during events and tactics during raids. \
The HUD can be hidden from the Settings tab, as well as toggling auto-height and mouse wheel scrolling. The HUD can be moved and resized by pressing the lock icon in the top right and locked again by pressing the move icon in the top right.",
                    order = 1.01
                },
            }
        },

        settingsPanel = 
        {
            type = "group",
            name = "Settings",
            order = 9,
            args =
            {
                toggleHUDAutoShow =
                {
                    type = "toggle",
                    name = "Auto-Show when Guild Message Updated",
                    width = "full",
                    desc = "Auto-show the HUD if it's hidden when guild message is updated.",
                    set = function(info, val) InfoHUD.moduleDB.hudData.autoShow = val end,
                    get = function() return InfoHUD.moduleDB.hudData.autoShow end,
                    order = 9.1,
                }, 

                toggleScrolling =
                {
                    type = "toggle",
                    name = "Mouse-wheel Scroll",
                    width = "full",
                    desc = "Allow scrolling the info HUD with the mouse wheel.",
                    set = function(info, val) InfoHUD.moduleDB.hudData.enableScroll = val end,
                    get = function() return InfoHUD.moduleDB.hudData.enableScroll end,
                    order = 9.2,
                },

                toggleAutoResize =
                {
                    type = "toggle",
                    name = "Auto Set Height to Fit",
                    width = "full",
                    desc = "Automatically set the HUD height to fit the largest shown message.",
                    set = function(info, val) InfoHUD.moduleDB.hudData.autoResize = val end,
                    get = function() return InfoHUD.moduleDB.hudData.autoResize end,
                    order = 9.3,
                },

                toggleHUDBtn =
                {
                    type = "execute",
                    name = function() if InfoHUD.UI.hudFrame:IsShown() then return "Hide HUD" else return "Show HUD" end end,
                    desc = "Toggle the Info HUD.",
                    func = function() InfoHUD.UI:ToggleHUD() end,
                    order = 9.5,
                },            
            }
        },
        
        officerControlsPanel = 
        {
            type = "group",
            name = "Officer Controls",
            order = 10,
            disabled = function() return WCCCAD:IsPlayerOfficer() == false end,
            hidden = function() return WCCCAD:IsPlayerOfficer() == false end,
            args =
            {
                toggleDebugMode = 
                {
                    type = "toggle",
                    name = "Debug Mode",
                    width = "full",
                    desc = "Enables verbose printing of events and AddOn functions.",
                    set = function(info, val) InfoHUD.moduleDB.debugMode = val  end,
                    get = function() return InfoHUD.moduleDB.debugMode end,
                    order = 10.0
                },

                messageOfficerControls = 
                {
                    type = "group",
                    name = "Message Controls",
                    inline = true,
                    order = 10.1,
                    args =
                    {
                        
                        clearGuildBtn = 
                        {
                            type = "execute",
                            name = "Clear Guild Message",
                            desc = "Clear the currently set guild message.",
                            func = function() InfoHUD:OC_SetMessage("guild", nil) end,
                            confirm = function() return "Clear guild message?" end,
                            order = 10.1
                        },

                        clearRaidBtn = 
                        {
                            type = "execute",
                            name = "Clear Raid Message",
                            desc = "Clear the currently set raid message.",
                            func = function() InfoHUD:OC_SetMessage("raid", nil) end,
                            confirm = function() return "Clear raid message?" end,
                            order = 10.1
                        },

                        clearButtonsDivider = 
                        {
                            type = "description",
                            name = " -- ",
                            order = 10.12,
                            width = "full"
                        },                        

                        messageSelectDropdown =
                        {
                            type = "select",  
                            name = "Load Saved Message",   
                            desc = "Select message to edit, or start writing with no message selected to create new or send without saving.",
                            descStyle = "inline",
                            order = 10.12,                            
                            values = function() 
                                local messageOptions = {}
                                for k, v in pairs(InfoHUD.moduleDB.savedMessages) do
                                    messageOptions[k] = v.name
                                end
                                return messageOptions
                            end,
                            get = function() return InfoHUD.UI.OC_SelectedMessageDataKey end,
                            set = function(options, key) InfoHUD.UI:OC_SelectMessage(key) end 
                        },                        

                        messageDeleteBtn =
                        {
                            type = "execute",
                            name = "Delete",
                            order = 10.121,
                            desc = "Delete the selected message.",
                            disabled = function() return InfoHUD.UI.OC_SelectedMessageDataKey == nil end,
                            func = function() InfoHUD.UI:OC_DeleteMessage(InfoHUD.UI.OC_SelectedMessageDataKey) end,
                            confirm = function() return format("Delete '%s'?", InfoHUD.UI.OC_SelectedMessageData.name) end
                        },

                        messageSelectDropdownDesc = 
                        {
                            type = "description",
                            name = "Select message to edit, or start writing with no message selected to create new or send without saving.",
                            order = 10.122,
                            width = "full"
                        },                        

                        messageNameDivider = 
                        {
                            type = "description",
                            name = " ",
                            order = 10.13,
                            width = "full"
                        },

                        messageClear =
                        {
                            type = "execute",
                            name = "Clear/Add New",
                            order = 10.131,
                            desc = "Clear entered message data to add a new one.",
                            func = function() InfoHUD.UI:OC_ClearSelectedMessage() end
                        },     
                        
                        loadActiveGuildDataBtn =
                        {
                            type = "execute",
                            name = "Load Active Guild Data",
                            order = 10.132,
                            desc = "Load message data currently active in the guild tab, if there is any.",
                            disabled = function() return InfoHUD.moduleDB.activeMessages["guild"] == nil or InfoHUD.moduleDB.activeMessages["guild"].content == nil end,
                            func = function() InfoHUD.UI:OC_LoadActiveMessageForTab("guild") end
                        }, 

                        loadActiveRaidDataBtn =
                        {
                            type = "execute",
                            name = "Load Active Raid Data",
                            order = 10.133,
                            desc = "Load message data currently active in the raid tab, if there is any.",
                            disabled = function() return InfoHUD.moduleDB.activeMessages["raid"] == nil or InfoHUD.moduleDB.activeMessages["raid"].content == nil end,
                            func = function() InfoHUD.UI:OC_LoadActiveMessageForTab("raid") end
                        }, 

                        messageName =
                        {
                            type = "input",
                            order = 10.14,
                            name = "Name",
                            desc = "Name to save the message as. Leave blank if you don't want to save the message.",
                            width = "full",
                            descStyle = "inline",
                            set = function(info, val) InfoHUD.UI:OC_SetMessageName(val) end,
                            get = function() return InfoHUD.UI.OC_SelectedMessageData.name end,
                        },    

                        messageNameDesc = 
                        {
                            type = "description",
                            name = "Name to save the message as. Leave blank if you don't want to save the message.",
                            order = 10.141,
                            width = "full"
                        },
                        
                        messageContent =
                        {
                            type = "input",
                            order = 10.15,
                            name = "Content",
                            desc = "Message content to show in the Info HUD.",
                            width = "full",
                            multiline = 15,
                            set = function(info, val) InfoHUD.UI:OC_SetMessageContent(val) end,
                            get = function()
                                return InfoHUD.UI.OC_SelectedMessageData.content 
                            end,
                        }, 

                        messageSendToGuildBtn =
                        {
                            type = "execute",
                            name = "Send to Guild",
                            order = 10.16,
                            desc = "Send message to guild HUD.",
                            disabled = function() return InfoHUD.UI.OC_SelectedMessageData.content == nil end,
                            func = function() InfoHUD:OC_SetMessage("guild", InfoHUD.UI.OC_SelectedMessageData.content) end
                        },

                        messageSendToRaidBtn =
                        {
                            type = "execute",
                            name = "Send to Raid",
                            order = 10.17,
                            desc = "Send message to raid HUD.",
                            disabled = function() return InfoHUD.UI.OC_SelectedMessageData.content == nil end,
                            func = function() InfoHUD:OC_SetMessage("raid", InfoHUD.UI.OC_SelectedMessageData.content) end
                        },
                    }
                },
            }
        },
    }
}

local InfoHUD_UI = WCCCAD.UI:LoadModuleUI(InfoHUD, "Info HUD", INFOHUD_UI_CONFIG)
WCCCAD.UI:AddGuildControlButton("Info HUD Settings", "View Info HUD settings, toggle the HUD and more", InfoHUD_UI.Show) 

-- Officer controls
InfoHUD_UI.OC_SelectedMessageData = {}
InfoHUD_UI.OC_SelectedMessageDataKey = nil

function InfoHUD_UI:OC_LoadActiveMessageForTab(tabName)
    InfoHUD_UI:OC_ClearSelectedMessage()

    local activeMsgData = InfoHUD.moduleDB.activeMessages[tabName]
    if activeMsgData == nil or activeMsgData.content == nil then
        return    
    end

    -- See if we have a saved message with the same content.
    for key, msgData in pairs(InfoHUD.moduleDB.savedMessages) do
        if msgData.content == activeMsgData.content then
            InfoHUD_UI:OC_SelectMessage(key)
            return
        end
    end

    -- If there was no saved message, just set the content.
    InfoHUD_UI:OC_SetMessageContent(activeMsgData.content)
end

---
--- Updates the selected message name, or creates a new entry if one doesn't exist.
---
function InfoHUD_UI:OC_SetMessageName(name)
    InfoHUD_UI.OC_SelectedMessageData.name = name

    InfoHUD_UI.OC_SelectedMessageDataKey = InfoHUD_UI:OC_SaveSelectedMessage()
end

---
--- Updates the selected message content. Has no persistent effect if the message has no name (hasn't been saved)
---
function InfoHUD_UI:OC_SetMessageContent(content)
    InfoHUD_UI.OC_SelectedMessageData.content = content

    InfoHUD_UI.OC_SelectedMessageDataKey = InfoHUD_UI:OC_SaveSelectedMessage()
end

--- 
--- Returns the selected message if one is selected, otherwise a empty message data.
---
function InfoHUD_UI:OC_GetSelectedMessage()
    if InfoHUD_UI.OC_SelectedMessageData == nil then
        return 
        {
            name = nil,
            content = nil
        }
    end

    return InfoHUD.moduleDB.savedMessages[InfoHUD_UI.OC_SelectedMessageData]
end

function InfoHUD_UI:OC_SelectMessage(key)
    InfoHUD_UI.OC_SelectedMessageDataKey = key
    InfoHUD_UI.OC_SelectedMessageData = InfoHUD.moduleDB.savedMessages[key] or {}
end

function InfoHUD_UI:OC_ClearSelectedMessage()
    InfoHUD_UI.OC_SelectedMessageData = {}
    InfoHUD_UI.OC_SelectedMessageDataKey = nil
end

---
--- Saves InfoHUD_UI.OC_SelectedMessageData, creating a new entry if current doesn't exist, and returns the key.
---
function InfoHUD.UI:OC_SaveSelectedMessage()
    if InfoHUD_UI.OC_SelectedMessageData.name == nil then
        return
    end

    if InfoHUD_UI.OC_SelectedMessageDataKey == nil then 
        table.insert(InfoHUD.moduleDB.savedMessages,InfoHUD_UI. OC_SelectedMessageData)

        for k, v in pairs(InfoHUD.moduleDB.savedMessages) do
            if v.name == InfoHUD_UI.OC_SelectedMessageData.name and v.content == InfoHUD_UI.OC_SelectedMessageData.content then
                return k
            end
        end
        WCCCAD.UI:PrintAddOnMessage("Couldn't find the added message in the table.", ns.consts.MSG_TYPE.ERROR)
    end 
    
    return InfoHUD_UI.OC_SelectedMessageDataKey
end

function InfoHUD_UI:OC_DeleteMessage(key)
    table.remove(InfoHUD.moduleDB.savedMessages, key)
    if key == InfoHUD_UI.OC_SelectedMessageDataKey then
        InfoHUD_UI:OC_ClearSelectedMessage()
    end
end
-- 

function InfoHUD_UI:SetHUDShown(showHUD) 
    if InfoHUD.UI.hudFrame == nil then
        InfoHUD_UI:CreateHUD()
    end

    if showHUD then
        InfoHUD.UI.hudFrame:Show()
    else
        InfoHUD.UI.hudFrame:Hide()
    end

    InfoHUD.moduleDB.hudData.shown = showHUD
end

function InfoHUD_UI:ToggleHUD()
    InfoHUD_UI:SetHUDShown(not InfoHUD.UI.hudFrame:IsShown())
end

function InfoHUD_UI:RestoreHUDShownState()
    local showHUD = InfoHUD.moduleDB.hudData.shown

    InfoHUD_UI:SetHUDShown(showHUD)
end

function InfoHUD_UI:CreateHUD()
    InfoHUD.UI.hudFrame = ns.utils.CreateHUDPanel(
        "Info HUD",
        function() 
            return InfoHUD.moduleDB.hudData.point, InfoHUD.moduleDB.hudData.offsetX, InfoHUD.moduleDB.hudData.offsetY 
        end,

        function(point, offsetX, offsetY)
            InfoHUD.moduleDB.hudData.point = point
            InfoHUD.moduleDB.hudData.offsetX = offsetX
            InfoHUD.moduleDB.hudData.offsetY = offsetY
         end,

        function() 
            InfoHUD.UI:Show()
        end,

        function()
            InfoHUD.UI:SetHUDShown(false)
        end,
        
        -- Resizing
        true,

        function()
            return InfoHUD.moduleDB.hudData.width, InfoHUD.moduleDB.hudData.height
        end,

        function(width, height)
            InfoHUD.moduleDB.hudData.width = width
            InfoHUD.moduleDB.hudData.height = height

            InfoHUD.UI.hudFrame.tabDivider:SetWidth(InfoHUD.UI.hudFrame:GetWidth() - 3)
        end
    )

    InfoHUD.UI.hudFrame:SetScript("OnMouseWheel", function(frame, delta)
        if InfoHUD.moduleDB.hudData.enableScroll then
            for frameName, frameData in pairs(InfoHUD.UI.hudFrame.messageFrames) do
                if frameData.messageFrame:IsShown() then                    
                    if delta > 0 then
                        frameData.messageFrame:ScrollDown()
                    else 
                        frameData.messageFrame:ScrollUp()
                    end

                    return
                end
            end  
        end
    end)


    InfoHUD.UI.hudFrame.messageFrames = {}
    InfoHUD.UI.hudFrame.CreateMessageFrame = function(self, frameName) 
        if InfoHUD.UI.hudFrame.messageFrames[frameName] ~= nil then
            WCCCAD.UI:PrintAddOnMessage("InfoHUD:CreateMessageFrame, ".. frameName.. " already exists!", ns.consts.MSG_TYPE.ERROR)
            return
        end

        WCCCAD.UI:PrintDebugMessage("InfoHUD:CreateMessageFrame, creating tab: ".. frameName, InfoHUD.moduleDB.debugMode)
        local tabName = string.gsub(frameName, "^%l", string.upper)
        local messageFrame = CreateFrame("ScrollingMessageFrame", nil, InfoHUD.UI.hudFrame)
        messageFrame:SetPoint("TOPLEFT", 5, -50)
        messageFrame:SetPoint("RIGHT", -5, 0)
        messageFrame:SetPoint("BOTTOM", 0, 5)
        messageFrame:SetSize(InfoHUD.UI.hudFrame:GetWidth() - 5, InfoHUD.UI.hudFrame:GetHeight() - 20)
        messageFrame:SetIndentedWordWrap(true)
        messageFrame:SetJustifyH("LEFT")
        messageFrame:SetFading(false)
        messageFrame:SetMaxLines(50)
        messageFrame:SetHyperlinksEnabled(false)
        messageFrame:SetFontObject(GameFontNormal)
        messageFrame:SetTextColor(1, 1, 1, 1)
        messageFrame:SetInsertMode(SCROLLING_MESSAGE_FRAME_INSERT_MODE_TOP)
        messageFrame:Hide()

        local tabButton = CreateFrame("Button", frameName.."_tab", InfoHUD.UI.hudFrame, "OptionsFrameTabButtonTemplate")--"UIPanelButtonTemplate")
        tabButton:SetText(tabName)
        PanelTemplates_TabResize(tabButton, 2, nil, 30, 30, tabButton:GetFontString():GetStringWidth())
        tabButton:SetScript("OnClick", function()
            InfoHUD.UI.hudFrame:SwitchTab(frameName)
        end)

        InfoHUD.UI.hudFrame.messageFrames[frameName] = 
        {
            messageFrame = messageFrame,
            tabButton = tabButton,
            hidden = false
        }      
        
        InfoHUD.UI.hudFrame:LayoutTabs()
    end

    --- Relayout shown tab buttons
    InfoHUD.UI.hudFrame.LayoutTabs = function(self) 
        local tabOffset = 0
        for frameName, frameData in pairs(InfoHUD.UI.hudFrame.messageFrames) do
            if frameData.hidden == false then
                tabOffset = tabOffset + frameData.tabButton:GetWidth() - 10
            end

            frameData.tabButton:ClearAllPoints()
            frameData.tabButton:SetPoint("TOPLEFT", 3 + (tabOffset - frameData.tabButton:GetWidth()), -20)  
        end   
    end

    --- Get the config data for the specified frame (messageFrame, tabButton, hiddenState etc)
    InfoHUD.UI.hudFrame.GetMessageFrameData = function(self, frameName)
        if InfoHUD.UI.hudFrame.messageFrames[frameName] == nil then
            InfoHUD.UI.hudFrame:CreateMessageFrame(frameName)
        end

        return InfoHUD.UI.hudFrame.messageFrames[frameName]
    end

    InfoHUD.UI.hudFrame.SwitchTab = function(self, targetFrame)
        if InfoHUD.UI.hudFrame.messageFrames[targetFrame] == nil then
            InfoHUD.UI.hudFrame:CreateMessageFrame(targetFrame)
        end

        for frameName, frameData in pairs(InfoHUD.UI.hudFrame.messageFrames) do
            if frameName == targetFrame then
                frameData.tabButton:LockHighlight()
                frameData.messageFrame:Show()
                frameData.tabButton:Show()
                frameData.hidden = false
            else
                frameData.tabButton:UnlockHighlight()
                frameData.messageFrame:Hide()
            end
        end

        InfoHUD.UI.hudFrame:LayoutTabs()        
    end

    InfoHUD.UI.hudFrame.DoAutoSize = function(self)
        if not InfoHUD.moduleDB.hudData.autoResize then
            return
        end

        -- Resize HUD to largest message
        local msgLines = 0
        for frameName, frameData in pairs(InfoHUD.UI.hudFrame.messageFrames) do
            local lines = frameData.messageFrame:GetMaxLines()
            frameData.messageFrame:SetHeight(lines * 20)

            if lines > msgLines then
                msgLines = lines
            end
        end

        if msgLines > 0 then
            WCCCAD.UI:PrintDebugMessage("InfoHUD Resizing to fit "..msgLines.." lines", InfoHUD.moduleDB.debugMode)
            local newHeight = msgLines * 16
            local minWidth, minHeight = InfoHUD.UI.hudFrame:GetMinResize()
            if newHeight < minHeight then
                newHeight = minHeight
            end
            InfoHUD.UI.hudFrame:SetHeight(newHeight)
        end
    end

    InfoHUD.UI.hudFrame.HideTab = function(self, targetFrame) 
        local frameData = InfoHUD.UI.hudFrame:GetMessageFrameData(targetFrame)
        frameData.hidden = true

        InfoHUD.UI.hudFrame:LayoutTabs()
        -- If the frame is currently shown, try and show an active tab.
        if frameData.messageFrame:IsShown() then         
            for frameName, frameData in pairs(InfoHUD.UI.hudFrame.messageFrames) do
                if frameData.hidden == false then
                    InfoHUD.UI.hudFrame:SwitchTab(frameName)
                    break
                end
            end 
        end

        frameData.messageFrame:Hide()
        frameData.tabButton:Hide()
    end

    InfoHUD.UI.hudFrame.SetTabMessage = function(self, targetFrame, message)
        local frameData = InfoHUD.UI.hudFrame:GetMessageFrameData(targetFrame)

        frameData.messageFrame:Clear()

        local parsedMessage = ns.utils.FormatSpecialString(message)
        local lines = { strsplit("\n", parsedMessage) }
        local numLines = #lines
        frameData.messageFrame:SetMaxLines(numLines + 1)
        for i=1, numLines do
            local line = lines[numLines - i + 1]
            if line == "" then
                line = " "
            end
            frameData.messageFrame:AddMessage(line)            
        end

        InfoHUD.UI.hudFrame:DoAutoSize()
    end    

    InfoHUD.UI.hudFrame.tabDivider = CreateFrame("Frame", nil, InfoHUD.UI.hudFrame)
    InfoHUD.UI.hudFrame.tabDivider:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
        tile = false, tileSize = 6, edgeSize = 6, 
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    InfoHUD.UI.hudFrame.tabDivider:SetFrameLevel(99)
    InfoHUD.UI.hudFrame.tabDivider:SetBackdropBorderColor(1, 0.62, 0, 0.8)
    InfoHUD.UI.hudFrame.tabDivider:SetPoint("TOPLEFT", 2, -45)
    InfoHUD.UI.hudFrame.tabDivider:SetPoint("RIGHT", -2, 0)
    InfoHUD.UI.hudFrame.tabDivider:SetHeight(3)
    InfoHUD.UI.hudFrame.tabDivider:SetWidth(InfoHUD.UI.hudFrame:GetWidth() -3)

    --local scrollBar = CreateFrame("Frame", nil, InfoHUD.UI.hudFrame, "MinimalScrollBarTemplate")
    --scrollBar:SetPoint("TOPRIGHT",0, 0)
    --scrollBar:SetHeight(InfoHUD.UI.hudFrame:GetHeight())
end