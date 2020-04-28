--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
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
                        tabSelectDropdown =
                        {
                            type = "select",  
                            name = "Select Tab",   
                            desc = "Select tab to send to.",
                            descStyle = "inline",
                            order = 10.111,                            
                            values = function() 
                                local tabOptions = {}
                                for tabName, v in pairs(InfoHUD.moduleDB.activeMessages) do
                                    tabOptions[tabName] = tabName
                                end
                                return tabOptions
                            end,
                            get = function() return InfoHUD.UI.OC_SelectedTabKey end,
                            set = function(options, key) InfoHUD.UI.OC_SelectedTabKey = key end 
                        },                        

                        clearMessageBtn = 
                        {
                            type = "execute",
                            name = "Clear Message",
                            desc = "Clear the currently selected tab message.",
                            func = function() InfoHUD:OC_SetMessage(InfoHUD.UI.OC_SelectedTabKey , nil) end,
                            confirm = function() return "Clear ".. InfoHUD.UI.OC_SelectedTabKey .. " message?" end,
                            order = 10.112
                        },                        

                        tabSelectDropdownDesc = 
                        {
                            type = "description",
                            name = "Select tab to edit, or enter a new tab name to create.",
                            order = 10.113,
                            width = "full"
                        },

                        tabName =
                        {
                            type = "input",
                            order = 10.121,
                            name = "Tab Name",
                            desc = "Name of new tab to create. Leave blank if using an existing one.",
                            width = "full",
                            descStyle = "inline",
                            set = function(info, val) InfoHUD.UI.OC_SelectedTabKey = val end,
                            get = function() return InfoHUD.UI.OC_SelectedTabKey end,
                        },

                        tabNameDesc =
                        {
                            type = "description",
                            order = 10.122,
                            name = "Name of tab to use. Select from above or enter a new one to create a tab.",
                            width = "full"
                        },

                        tabButtonsDivider = 
                        {
                            type = "description",
                            name = " -- ",
                            order = 10.13,
                            width = "full"
                        },                        

                        messageSelectDropdown =
                        {
                            type = "select",  
                            name = "Load Saved Message",   
                            desc = "Select message to edit, or start writing with no message selected to create new or send without saving.",
                            descStyle = "inline",
                            order = 10.14,                            
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
                            order = 10.141,
                            desc = "Delete the selected message.",
                            disabled = function() return InfoHUD.UI.OC_SelectedMessageDataKey == nil end,
                            func = function() InfoHUD.UI:OC_DeleteMessage(InfoHUD.UI.OC_SelectedMessageDataKey) end,
                            confirm = function() return format("Delete '%s'?", InfoHUD.UI.OC_SelectedMessageData.name) end
                        },

                        messageSelectDropdownDesc = 
                        {
                            type = "description",
                            name = "Select message to edit, or start writing with no message selected to create new or send without saving.",
                            order = 10.142,
                            width = "full"
                        },

                        messageNameDivider = 
                        {
                            type = "description",
                            name = " ",
                            order = 10.15,
                            width = "full"
                        },

                        messageClear =
                        {
                            type = "execute",
                            name = "Clear/Create New",
                            order = 10.151,
                            desc = "Clear entered message data to add a new one.",
                            func = function() InfoHUD.UI:OC_ClearSelectedMessage() end
                        },     

                        loadActiveMessageDataBtn =
                        {
                            type = "execute",
                            name = "Load Active Message Data",
                            order = 10.152,
                            desc = "Load message data currently active in the selected tab, if there is any.",
                            disabled = function() return InfoHUD.moduleDB.activeMessages[InfoHUD.UI.OC_SelectedTabKey] == nil or InfoHUD.moduleDB.activeMessages[InfoHUD.UI.OC_SelectedTabKey].content == nil end,
                            func = function() InfoHUD.UI:OC_LoadActiveMessageForTab(InfoHUD.UI.OC_SelectedTabKey) end
                        },  

                        messageName =
                        {
                            type = "input",
                            order = 10.16,
                            name = "Message Name",
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
                            order = 10.161,
                            width = "full"
                        },

                        messageContent =
                        {
                            type = "input",
                            order = 10.17,
                            name = "Content",
                            desc = "Message content to show in the Info HUD.",
                            width = "full",
                            multiline = 15,
                            set = function(info, val) InfoHUD.UI:OC_SetMessageContent(val) end,
                            get = function()
                                return InfoHUD.UI.OC_SelectedMessageData.content 
                            end,
                        }, 

                        messageSendToTabBtn =
                        {
                            type = "execute",
                            name = "Send to Selected Tab",
                            order = 10.18,
                            desc = "Send message to selected tab.",
                            validate = function()
                                if InfoHUD.UI.OC_SelectedTabKey == nil then
                                    return "Select a tab or enter a new tab name before sending the message."
                                end
                                return true
                            end,
                            confirm = function()
                                local isNewTab = true
                                for tabName, v in pairs(InfoHUD.moduleDB.activeMessages) do
                                    if tabName == InfoHUD.UI.OC_SelectedTabKey then
                                        isNewTab = false
                                        break
                                    end
                                end

                                if isNewTab then
                                    return "Create new tab: " .. InfoHUD.UI.OC_SelectedTabKey
                                end

                                return false
                            end,
                            disabled = function() return InfoHUD.UI.OC_SelectedMessageData.content == nil end,
                            func = function() InfoHUD:OC_SetMessage(InfoHUD.UI.OC_SelectedTabKey, InfoHUD.UI.OC_SelectedMessageData.content) end
                        }
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
InfoHUD_UI.OC_SelectedTabKey = "guild"

function InfoHUD_UI:OC_LoadActiveMessageForTab(tabName)
    self:OC_ClearSelectedMessage()

    local activeMsgData = InfoHUD.moduleDB.activeMessages[tabName]
    if activeMsgData == nil or activeMsgData.content == nil then
        return    
    end

    -- See if we have a saved message with the same content.
    for key, msgData in pairs(InfoHUD.moduleDB.savedMessages) do
        if msgData.content == activeMsgData.content then
            self:OC_SelectMessage(key)
            return
        end
    end

    -- If there was no saved message, just set the content.
    self:OC_SetMessageContent(activeMsgData.content)
end

---
--- Updates the selected message name, or creates a new entry if one doesn't exist.
---
function InfoHUD_UI:OC_SetMessageName(name)
    self.OC_SelectedMessageData.name = name

    self.OC_SelectedMessageDataKey = self:OC_SaveSelectedMessage()
end

---
--- Updates the selected message content. Has no persistent effect if the message has no name (hasn't been saved)
---
function InfoHUD_UI:OC_SetMessageContent(content)
    self.OC_SelectedMessageData.content = content

    self.OC_SelectedMessageDataKey = self:OC_SaveSelectedMessage()
end

---
--- Returns the selected message if one is selected, otherwise a empty message data.
---
function InfoHUD_UI:OC_GetSelectedMessage()
    if self.OC_SelectedMessageData == nil then
        return 
        {
            name = nil,
            content = nil
        }
    end

    return InfoHUD.moduleDB.savedMessages[self.OC_SelectedMessageData]
end

function InfoHUD_UI:OC_SelectMessage(key)
    self.OC_SelectedMessageDataKey = key
    self.OC_SelectedMessageData = InfoHUD.moduleDB.savedMessages[key] or {}
end

function InfoHUD_UI:OC_ClearSelectedMessage()
    self.OC_SelectedMessageData = {}
    self.OC_SelectedMessageDataKey = nil
end

---
--- Saves InfoHUD_UI.OC_SelectedMessageData, creating a new entry if current doesn't exist, and returns the key.
---
function InfoHUD.UI:OC_SaveSelectedMessage()
    if self.OC_SelectedMessageData.name == nil then
        return
    end

    if self.OC_SelectedMessageDataKey == nil then 
        table.insert(InfoHUD.moduleDB.savedMessages,self. OC_SelectedMessageData)

        for k, v in pairs(InfoHUD.moduleDB.savedMessages) do
            if v.name == self.OC_SelectedMessageData.name and v.content == self.OC_SelectedMessageData.content then
                return k
            end
        end
        WCCCAD.UI:PrintAddOnMessage("Couldn't find the added message in the table.", ns.consts.MSG_TYPE.ERROR)
    end 

    return self.OC_SelectedMessageDataKey
end

function InfoHUD_UI:OC_DeleteMessage(key)
    table.remove(InfoHUD.moduleDB.savedMessages, key)
    if key == self.OC_SelectedMessageDataKey then
        self:OC_ClearSelectedMessage()
    end
end
--

function InfoHUD_UI:SetHUDShown(showHUD) 
    if self.hudFrame == nil then
        self:CreateHUD()
    end

    if showHUD then
        self.hudFrame:Show()
    else
        self.hudFrame:Hide()
    end

    InfoHUD.moduleDB.hudData.shown = showHUD
end

function InfoHUD_UI:ToggleHUD()
    self:SetHUDShown(not self.hudFrame:IsShown())
end

function InfoHUD_UI:RestoreHUDShownState()
    local showHUD = InfoHUD.moduleDB.hudData.shown

    self:SetHUDShown(showHUD)
end

function InfoHUD_UI:CreateHUD()
    self.hudFrame = ns.utils.CreateHUDPanel(
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

            self.hudFrame.tabDivider:SetWidth(self.hudFrame:GetWidth() - 3)
        end
    )

    self.hudFrame:SetScript("OnMouseWheel", function(hudFrameSelf, delta)
        if InfoHUD.moduleDB.hudData.enableScroll then
            for frameName, frameData in pairs(hudFrameSelf.messageFrames) do
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


    self.hudFrame.messageFrames = {}
    function self.hudFrame.CreateMessageFrame(hudFrameSelf, frameName) 
        if hudFrameSelf.messageFrames[frameName] ~= nil then
            WCCCAD.UI:PrintAddOnMessage("InfoHUD:CreateMessageFrame, ".. frameName.. " already exists!", ns.consts.MSG_TYPE.ERROR)
            return
        end

        WCCCAD.UI:PrintDebugMessage("InfoHUD:CreateMessageFrame, creating tab: ".. frameName, InfoHUD.moduleDB.debugMode)
        local tabName = string.gsub(frameName, "^%l", string.upper)
        local messageFrame = CreateFrame("ScrollingMessageFrame", nil, hudFrameSelf)
        messageFrame:SetPoint("TOPLEFT", 5, -50)
        messageFrame:SetPoint("RIGHT", -5, 0)
        messageFrame:SetPoint("BOTTOM", 0, 5)
        messageFrame:SetSize(hudFrameSelf:GetWidth() - 5, hudFrameSelf:GetHeight() - 20)
        messageFrame:SetIndentedWordWrap(true)
        messageFrame:SetJustifyH("LEFT")
        messageFrame:SetFading(false)
        messageFrame:SetMaxLines(50)
        messageFrame:SetHyperlinksEnabled(false)
        messageFrame:SetFontObject(GameFontNormal)
        messageFrame:SetTextColor(1, 1, 1, 1)
        messageFrame:SetInsertMode(SCROLLING_MESSAGE_FRAME_INSERT_MODE_TOP)
        messageFrame:Hide()

        local tabButton = CreateFrame("Button", frameName.."_tab", hudFrameSelf, "OptionsFrameTabButtonTemplate")
        tabButton:SetText(tabName)
        PanelTemplates_TabResize(tabButton, 2, nil, 30, 50, tabButton:GetFontString():GetStringWidth())
        tabButton:SetScript("OnClick", function()
            hudFrameSelf:SwitchTab(frameName)
        end)

        hudFrameSelf.messageFrames[frameName] = 
        {
            messageFrame = messageFrame,
            tabButton = tabButton,
            hidden = false
        }      

        hudFrameSelf:LayoutTabs()
    end

    --- Relayout shown tab buttons
    function self.hudFrame.LayoutTabs(hudFrameSelf) 
        local tabOffset = 0
        for frameName, frameData in pairs(hudFrameSelf.messageFrames) do
            if frameData.hidden == false then
                tabOffset = tabOffset + frameData.tabButton:GetWidth() - 10
            end

            frameData.tabButton:ClearAllPoints()
            frameData.tabButton:SetPoint("TOPLEFT", 3 + (tabOffset - frameData.tabButton:GetWidth()), -20)  
        end   
    end

    --- Get the config data for the specified frame (messageFrame, tabButton, hiddenState etc)
    function self.hudFrame.GetMessageFrameData(hudFrameSelf, frameName)
        if hudFrameSelf.messageFrames[frameName] == nil then
            hudFrameSelf:CreateMessageFrame(frameName)
        end

        return hudFrameSelf.messageFrames[frameName]
    end

    function self.hudFrame.SwitchTab(hudFrameSelf, targetFrame)
        if hudFrameSelf.messageFrames[targetFrame] == nil then
            hudFrameSelf:CreateMessageFrame(targetFrame)
        end

        for frameName, frameData in pairs(hudFrameSelf.messageFrames) do
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

        hudFrameSelf:LayoutTabs()        
    end

    function self.hudFrame.DoAutoSize(hudFrameSelf)
        if not InfoHUD.moduleDB.hudData.autoResize then
            return
        end

        -- Resize HUD to largest message
        local msgLines = 0
        for frameName, frameData in pairs(hudFrameSelf.messageFrames) do
            local lines = frameData.messageFrame:GetMaxLines()
            if InfoHUD.moduleDB.activeMessages[frameName].content == nil then
                lines = 1
            end
            frameData.messageFrame:SetHeight(lines * 20)

            if lines > msgLines then
                WCCCAD.UI:PrintDebugMessage("InfoHUD more lines on "..frameName, InfoHUD.moduleDB.debugMode)
                msgLines = lines
            end
        end

        if msgLines > 0 then
            WCCCAD.UI:PrintDebugMessage("InfoHUD Resizing to fit "..msgLines.." lines", InfoHUD.moduleDB.debugMode)
            local newHeight = msgLines * 16
            local minWidth, minHeight = hudFrameSelf:GetMinResize()
            if newHeight < minHeight then
                newHeight = minHeight
            end
            hudFrameSelf:SetHeight(newHeight)
        end
    end

    function self.hudFrame.HideTab(hudFrameSelf, targetFrame) 
        local frameData = hudFrameSelf:GetMessageFrameData(targetFrame)
        frameData.hidden = true

        hudFrameSelf:LayoutTabs()
        -- If the frame is currently shown, try and show an active tab.
        if frameData.messageFrame:IsShown() then         
            for frameName, frameData in pairs(hudFrameSelf.messageFrames) do
                if frameData.hidden == false then
                    hudFrameSelf:SwitchTab(frameName)
                    break
                end
            end 
        end

        frameData.messageFrame:Hide()
        frameData.tabButton:Hide()
    end

    function self.hudFrame.SetTabMessage(hudFrameSelf, targetFrame, message)
        local frameData = hudFrameSelf:GetMessageFrameData(targetFrame)

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

        hudFrameSelf:DoAutoSize()
    end    

    self.hudFrame.tabDivider = CreateFrame("Frame", nil, self.hudFrame)
    self.hudFrame.tabDivider:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
        tile = false, tileSize = 6, edgeSize = 6, 
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    self.hudFrame.tabDivider:SetFrameLevel(99)
    self.hudFrame.tabDivider:SetBackdropBorderColor(1, 0.62, 0, 0.8)
    self.hudFrame.tabDivider:SetPoint("TOPLEFT", 2, -45)
    self.hudFrame.tabDivider:SetPoint("RIGHT", -2, 0)
    self.hudFrame.tabDivider:SetHeight(3)
    self.hudFrame.tabDivider:SetWidth(self.hudFrame:GetWidth() -3)

    --local scrollBar = CreateFrame("Frame", nil, self.hudFrame, "MinimalScrollBarTemplate")
    --scrollBar:SetPoint("TOPRIGHT",0, 0)
    --scrollBar:SetHeight(self.hudFrame:GetHeight())
end