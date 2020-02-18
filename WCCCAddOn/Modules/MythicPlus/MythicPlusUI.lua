--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD

local MythicPlus = WCCCAD:GetModule("WCCC_MythicPlus")

local MYTHICPLUS_UI_CONFIG = 
{
    name = "Mythic Plus",
    handler = MythicPlus,
    type = "group",
    childGroups = "tab",    
    args = 
    {
        logo = 
        {
            type = "description",
            name = "",
            image ="Interface\\AddOns\\WCCCAddOn\\assets\\wccc-header-mythicplus.tga",
            imageWidth=256,
            imageHeight=64,
            order = 0
        },

        helpPanel = 
        {
            type = "group",
            name = "How to Use",
            order = 1,
            args =
            {
                helpText = 
                {
                    type = "description",
                    fontSize = "medium",
                    name = "The Guild Mythic Plus Window shows what keystones each Guildy has and their current weekly best. \
The window can be opened from the guild roster and the button below.",
                    order = 1.01
                },

                showWindowBtn =
                {
                    type = "execute",
                    name = "Open Window",
                    desc = "Open Guild Mythic Plus Window.",
                    func = function() MythicPlus.UI:ShowWindow() end,
                    order = 1.02,
                }, 
            }
        },

        settingsPanel = 
        {
            type = "group",
            name = "Settings",
            order = 2,
            args =
            {
                keyStoneNotifications = 
                {
                    type = "group",
                    name = "Keystone Notifications",
                    inline = true,
                    order = 2.1,
                    args =
                    {
                        toggleGuildyReceievedKeystoneNotification  =
                        {
                            type = "toggle",
                            name = "Show guild chat notification when Guildy receives a keystone.",
                            width = "full",
                            desc = "Show guild chat notification when a guildy receives a keystone.",
                            set = function(info, val) MythicPlus.moduleDB.showGuildMemberReceivedKeystoneNotification = val end,
                            get = function() return MythicPlus.moduleDB.showGuildMemberReceivedKeystoneNotification end,
                            order = 2.11,
                        },     

                        toggleSendGuildyReceievedKeystoneNotification  =
                        {
                            type = "toggle",
                            name = "Send guild chat notification when you receive a keystone.",
                            width = "full",
                            desc = "Send a guild chat notification when you receive a keystone.",
                            set = function(info, val) MythicPlus.moduleDB.sendGuildReceivedKeystoneNotification = val end,
                            get = function() return MythicPlus.moduleDB.sendGuildReceivedKeystoneNotification end,
                            order = 2.12,
                        }, 
                    }
                },

                weeklyBestNotifications = 
                {
                    type = "group",
                    name = "Weekly Best Notifications",
                    inline = true,
                    order = 2.2,
                    args =
                    {
                        toggleGuildyNewRecordNotification  =
                        {
                            type = "toggle",
                            name = "Show guild chat notification when Guildy achieves a new weekly best.",
                            width = "full",
                            desc = "Show guild chat notification when a guildy achieves a new weekly best mythic+ run.",
                            set = function(info, val) MythicPlus.moduleDB.showGuildmemberNewRecordNotification = val end,
                            get = function() return MythicPlus.moduleDB.showGuildmemberNewRecordNotification end,
                            order = 2.21,
                        },     

                        toggleSendNewRecordNotification  =
                        {
                            type = "toggle",
                            name = "Send guild chat notification when you achieve a new weekly best.",
                            width = "full",
                            desc = "Send a guild chat notification when you achieve a new weekly best.",
                            set = function(info, val) MythicPlus.moduleDB.sendGuildNewRecordNotification = val end,
                            get = function() return MythicPlus.moduleDB.sendGuildNewRecordNotification end,
                            order = 2.22,
                        }, 
                    }
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
                    set = function(info, val) MythicPlus.moduleDB.debugMode = val  end,
                    get = function() return MythicPlus.moduleDB.debugMode end,
                    order = 10.0
                },
            }
        }
    }
}

local MythicPlus_UI = WCCCAD.UI:LoadModuleUI(MythicPlus, "Mythic+", MYTHICPLUS_UI_CONFIG)

MythicPlus_UI.SortMethod =
{
    NAME = "name",
    DUNGEON = "dungeon",
    LEVEL = "level",
    BEST = "best",
    LAST_UPDATED = "last_updated"
}

MythicPlus_UI.COLUMN_INFO = 
{
    [1] = 
    {
		title = "Name",
		width = 150,
		sortMethod = MythicPlus_UI.SortMethod.NAME,
	},
    [2] = 
    {
		title = "Dungeon",
		width = 150,
		sortMethod = MythicPlus_UI.SortMethod.DUNGEON,
	},
    [3] = 
    {
		title = "Level",
		width = 60,
		sortMethod = MythicPlus_UI.SortMethod.LEVEL,
	},
    [4] = 
    {
		title = "Weekly Best",
		width = 80,
		sortMethod = MythicPlus_UI.SortMethod.BEST,
    },
    [5] = 
    {
		title = "Last Updated",
		width = 100,
		sortMethod = MythicPlus_UI.SortMethod.LAST_UPDATED,
	}
}

function MythicPlus_UI:ShowWindow()
    WCCC_MythicPlus_Frame:Show()
end

function MythicPlus_UI:OnDataUpdated() 
    WCCC_MythicPlus_Frame:UpdateData(MythicPlus.moduleDB.guildKeys, MythicPlus.moduleDB.leaderboardData)
end

WCCCAD.UI:AddGuildControlButton("Guild Keystones", "View Guild Mythic+ Keystones", MythicPlus_UI.ShowWindow) 


--#region Mythic Plus Frame Mixin
WCCC_MythicPlusFrameMixin = {}

-- A merged copy of MythicPlus guildKeys and leaderboardData sorted using the current sort method.
WCCC_MythicPlusFrameMixin.orderedGuildKeys = {}

function WCCC_MythicPlusFrameMixin:OnLoad()
    self:RegisterForDrag("LeftButton")
    self.ColumnDisplay:LayoutColumns(MythicPlus_UI.COLUMN_INFO)

    HybridScrollFrame_CreateButtons(self.ListScrollFrame, "WCCC_MythicPlusEntryTemplate", 0, 0)
    HybridScrollFrame_SetDoNotHideScrollBar(self.ListScrollFrame, true)
    self.ListScrollFrame.update = self.RefreshLayout

    tinsert(UISpecialFrames, self:GetName())
end

function WCCC_MythicPlusFrameMixin:OnShow()
    C_GuildInfo.GuildRoster()
    self:ResetColumnSort()
    self:RefreshLayout()
end

function WCCC_MythicPlusFrameMixin:OpenSettings()
    MythicPlus_UI:Show()
end
---
--- Update frame with the MythicPlus guildKeys and leaderboardData tables.
---
function WCCC_MythicPlusFrameMixin:UpdateData(guildKeys, leaderboardData)
    self.orderedGuildKeys = {}

    local idx = 1
    for _, entryData in pairs(guildKeys) do        
        if entryData then
            local leaderboardEntry = leaderboardData[entryData.GUID]
            self.orderedGuildKeys[idx] =
            {
                GUID = entryData.GUID,
                playerName = entryData.playerName,
                classID = entryData.classID,
                mapID = entryData.mapID,
                level = entryData.level,
                bestLevel = leaderboardEntry and leaderboardEntry.level or 0,
                updateTimestamp = entryData.lastUpdateTimestamp
            }
            idx = idx + 1
        end
    end    

    --- Reapply active sort.
    if self.activeColumnSortMethod then
        self:SortDataByColumn(self.activeColumnSortMethod, false)
    end
    self:RefreshLayout()
end

function WCCC_MythicPlusFrameMixin:RefreshLayout()
    local scrollFrame = self.ListScrollFrame

    local offset = HybridScrollFrame_GetOffset(scrollFrame)
    local shownEntries = 0
    local idx

    if #self.orderedGuildKeys == 0 then
        return
    end

    for i = 1, #scrollFrame.buttons do
        idx = offset + i
        local entryData = self.orderedGuildKeys[idx]
        if entryData then
            scrollFrame.buttons[i]:UpdateData(entryData)
            scrollFrame.buttons[i]:Show()

            shownEntries = shownEntries + 1
        else 
            scrollFrame.buttons[i]:Hide()
        end
    end    

    local buttonHeight = scrollFrame.buttons[1]:GetHeight()
    local displayedHeight = shownEntries * buttonHeight
    local totalHeight = #self.orderedGuildKeys * buttonHeight

    HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight)
end

-- global KeyValue
function WCCC_MythicPlus_OnColumnClick(self, columnIdx)
    local sortMethod = MythicPlus_UI.COLUMN_INFO[columnIdx] and MythicPlus_UI.COLUMN_INFO[columnIdx].sortMethod or nil
    if sortMethod == nil then
        return
    end
    WCCC_MythicPlus_Frame:SortDataByColumn(sortMethod, true)
    WCCC_MythicPlus_Frame:RefreshLayout()
end

function WCCC_MythicPlusFrameMixin:ResetColumnSort()
	self.reverseColumnSort = false
	self.activeColumnSortMethod = nil
end

---
--- Sorts local data by the specified sort method.
--- @param reverseOnSameSort boolean @Whether to reverse the sort if the specified method is the same as the active sort.
---
function WCCC_MythicPlusFrameMixin:SortDataByColumn(sortMethod, reverseOnSameSort)
    if sortMethod == nil or not self.orderedGuildKeys then
        return
    end

    if reverseOnSameSort then
        self.reverseColumnSort = sortMethod ~= self.activeColumnSortMethod and false or not self.reverseColumnSort
    end
    self.activeColumnSortMethod = sortMethod

    if sortMethod == MythicPlus_UI.SortMethod.NAME then
        table.sort(self.orderedGuildKeys, function(a, b)
            return self:SortFunction(self.reverseColumnSort, a.playerName:upper(), b.playerName:upper())
        end)

    elseif sortMethod == MythicPlus_UI.SortMethod.DUNGEON then
        table.sort(self.orderedGuildKeys, function(a, b)
            return self:SortFunction(self.reverseColumnSort, a.mapID, b.mapID)
        end)

    elseif sortMethod == MythicPlus_UI.SortMethod.LEVEL then
        table.sort(self.orderedGuildKeys, function(a, b)
            return self:SortFunction(self.reverseColumnSort, a.level, b.level)
        end)

    elseif sortMethod == MythicPlus_UI.SortMethod.BEST then
        table.sort(self.orderedGuildKeys, function(a, b)
            return self:SortFunction(self.reverseColumnSort, a.bestLevel, b.bestLevel)
        end)

    elseif sortMethod == MythicPlus_UI.SortMethod.LAST_UPDATED then
        table.sort(self.orderedGuildKeys, function(a, b)
            return self:SortFunction(self.reverseColumnSort, a.updateTimestamp, b.updateTimestamp)
        end)
    end
end

function WCCC_MythicPlusFrameMixin:SortFunction(shouldReverse, firstValue, secondValue)
	if shouldReverse then 
		return firstValue < secondValue
	else 
		return firstValue > secondValue
	end
end 
--#endregion


--#region Mythic Plus Entry Mixin
WCCC_MythicPlusEntryMixin = {}

WCCC_MythicPlusEntryMixin.Data = nil -- { GUID, playerName, classID, mapID, level, bestLevel, updateTimestamp}


function WCCC_MythicPlusEntryMixin:PlayerEntryRightClickOptionsMenuInitialise(level)
    local info = UIDropDownMenu_CreateInfo()

    info.text = self:GetParent():GetPlayerName()
    info.isTitle = true
    info.notCheckable = true
    UIDropDownMenu_AddButton(info, level)

    info.text = WHISPER
    info.colorCode = HIGHLIGHT_FONT_COLOR_CODE
    info.isTitle = false
    info.notCheckable = true
    info.disabled = nil
    info.func = function () ChatFrame_SendTell(self:GetParent():GetPlayerName()) end
    UIDropDownMenu_AddButton(info, level)

    info.text = INVITE
    info.colorCode = HIGHLIGHT_FONT_COLOR_CODE
    info.isTitle = false
    info.notCheckable = true
    info.disabled = nil
    info.func = function () InviteUnit(self:GetParent():GetPlayerName()) end
    UIDropDownMenu_AddButton(info, level)
end

function WCCC_MythicPlusEntryMixin:OnMouseDown(button)
    if button == "RightButton" and self.Data.isOnline then
		ToggleDropDownMenu(1, nil, self.RightClickDropdown, self, 100, 0)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end
end 

function WCCC_MythicPlusEntryMixin:GetPlayerName()
    return self.Data.playerName
end

function WCCC_MythicPlusEntryMixin:IsOnline()
    return self.Data.isOnline
end

function WCCC_MythicPlusEntryMixin:UpdateData(keyData)
    self.Data = keyData
    if not self.Data then
        return
    end

    self.Data.isOnline = false
    local _, numMembersOnline = GetNumGuildMembers()
    for i=1, numMembersOnline do
        local _, _, _, _, _, _, _, _, isOnline, _, _, _, _, _, _, _, memberGUID = GetGuildRosterInfo(i)
        if memberGUID == self.Data.GUID then
            self.Data.isOnline = isOnline
            break;
        end
    end

    local textColour = self.Data.isOnline and CreateColor(1, 1, 1) or CreateColor(0.4, 0.4, 0.4)

    local _, classTag = GetClassInfo(self.Data.classID)
    local classColour = CreateColor(GetClassColor(classTag))
    self.NameLabel:SetText(self.Data.playerName)
    if self.Data.isOnline then
        self.NameLabel:SetTextColor(classColour.r, classColour.g, classColour.b)
    else 
        self.NameLabel:SetTextColor(textColour.r, textColour.g, textColour.b)
    end

    local dungeonName = C_ChallengeMode.GetMapUIInfo(self.Data.mapID)
    self.DungeonLabel:SetText(dungeonName)
    self.DungeonLabel:SetTextColor(textColour.r, textColour.g, textColour.b)

    self.LevelLabel:SetText("+"..self.Data.level)
    self.LevelLabel:SetTextColor(textColour.r, textColour.g, textColour.b)

    self.BestLevelLabel:SetText("+"..self.Data.bestLevel)
    self.BestLevelLabel:SetTextColor(textColour.r, textColour.g, textColour.b)

    self.UpdatedLabel:SetText(ns.utils.GetTimeSinceString(self.Data.updateTimestamp))
    self.UpdatedLabel:SetTextColor(textColour.r, textColour.g, textColour.b)

    UIDropDownMenu_Initialize(self.RightClickDropdown, self.PlayerEntryRightClickOptionsMenuInitialise, "MENU")
end
--#endregion