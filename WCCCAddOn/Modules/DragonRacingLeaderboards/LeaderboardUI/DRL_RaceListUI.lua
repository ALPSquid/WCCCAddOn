--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD
local DRL = WCCCAD:GetModule("WCCC_DragonRacingLeaderboards")

-- Most of this is based on the Professions Recipe List UI: Blizzard_ProfessionsTemplates/Blizzard_ProfessionsRecipeList.lua/xml

--region Zone Category Button
DRL_RaceListZoneButtonMixin = {}

function DRL_RaceListZoneButtonMixin:Init(node)
    local elementData = node:GetData()
    local zoneID = elementData.zoneCategoryData.zoneID
    self.Label:SetText(C_Map.GetMapInfo(zoneID).name)
    self.Label:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())

    self:SetCollapseState(node:IsCollapsed())
end

function DRL_RaceListZoneButtonMixin:SetCollapseState(collapsed)
    local atlas = collapsed and "Professions-recipe-header-expand" or "Professions-recipe-header-collapse"
    self.CollapseIcon:SetAtlas(atlas, TextureKitConstants.UseAtlasSize)
    self.CollapseIconAlphaAdd:SetAtlas(atlas, TextureKitConstants.UseAtlasSize)
end

function DRL_RaceListZoneButtonMixin:Refresh()

end

function DRL_RaceListZoneButtonMixin:OnEnter()
    self.Label:SetFontObject(GameFontHighlight_NoShadow)
end

function DRL_RaceListZoneButtonMixin:OnLeave()
    self.Label:SetFontObject(GameFontNormal_NoShadow)
end
--endregion

--region Race Entry Button
DRL_RaceListRaceButtonMixin = {}

function DRL_RaceListRaceButtonMixin:Init(node)
    -- TODO: Show bronze/silver/gold coin in the entry based on the player's rank?
    local elementData = node:GetData()
    local raceData = elementData.raceData
    self.raceData = raceData
    self.Label:SetText(DRL:GetRaceName(raceData.raceID))
    self:Refresh()
end

function DRL_RaceListRaceButtonMixin:Refresh()
    -- Set font colour based on whether the player has logged a time.
    local playerLeaderboardEntry = DRL:GetPlayerAccountBest(UnitGUID("player"), self.raceData.raceID)
    local hasLoggedTime = playerLeaderboardEntry ~= nil and playerLeaderboardEntry.time > 0
    self.fontColour = hasLoggedTime and NORMAL_FONT_COLOR or DISABLED_FONT_COLOR
    self.Label:SetVertexColor(self.fontColour:GetRGB())
end

function DRL_RaceListRaceButtonMixin:OnEnter()
    self.Label:SetVertexColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    if not self.GetElementData then return end
    local elementData = self:GetElementData()
    if self.Label:IsTruncated() then
        GameTooltip:SetOwner(self.Label, "ANCHOR_RIGHT")
        local wrap = false
        GameTooltip_AddHighlightLine(GameTooltip, DRL:GetRaceName(elementData.raceData.raceID), wrap)
        GameTooltip:Show()
    end
end

function DRL_RaceListRaceButtonMixin:OnLeave()
    self.Label:SetVertexColor((self.fontColour or NORMAL_FONT_COLOR):GetRGB())
    GameTooltip:Hide()
end
function DRL_RaceListRaceButtonMixin:SetSelected(selected)
    self.SelectedOverlay:SetShown(selected)
    self.HighlightOverlay:SetShown(not selected)
end
--endregion

--region Race Type Tabs
DRL_RaceTabMixin = CreateFromMixins(MinimalTabMixin)

function DRL_RaceTabMixin:OnLoad()
    MinimalTabMixin:OnLoad(self)
    self:SetWidth(self.Text:GetStringWidth() + 40)
end
--endregion


--region Race List
DRL_RaceListMixin = {}
DRL_RaceListMixin.DRL = DRL
DRL_RaceListMixin.selectedRaceType = DRL.RACE_TYPE.NORMAL

function DRL_RaceListMixin:OnLoad()
    -- Tabs
    self.tabsGroup = CreateRadioButtonGroup()
    self.tabsGroup:AddButtons({self.TabBar.NormalTab, self.TabBar.AdvancedTab, self.TabBar.ReverseTab})
    local selectedTab = self.tabsGroup:FindButtonByPredicate(function(tab) return tab.raceType == self.selectedRaceType end)
    self.tabsGroup:Select(selectedTab)
    self.tabsGroup:RegisterCallback(ButtonGroupBaseMixin.Event.Selected, self.OnTabSelected, self)
    -- Resize tabs to either fill width of the race list, if possible, otherwise use the minimum tab width based on label length + padding.
    local longestTabStringLength = ns.utils.MaxAttribute(self.tabsGroup:GetButtons(), function(tab)
        return tab.Text:GetStringWidth()
    end)
    local _, _, _, tabMargin = self.tabsGroup:GetButtons()[2]:GetPointByName("BOTTOMLEFT")
    local numTabs = #self.tabsGroup:GetButtons()
    local tabWidth = max((self.TabBar:GetWidth() - (numTabs * tabMargin)) / numTabs, longestTabStringLength + 16)
    for _, tab in ipairs(self.tabsGroup:GetButtons()) do
        tab:SetWidth(tabWidth)
    end

    -- Overall Leaderboard Button
    self.OverallLeaderboardBtn:SetScript("OnClick", function()
        DRL.LeaderboardUI:SelectRace(nil)
    end)

    -- List View
    local indent = 20
    local padLeft = 5
    local pad = 5
    local spacing = 1
    self.view = CreateScrollBoxListTreeListView(indent, pad, pad, padLeft, pad, spacing)
    self.view:SetElementFactory(function(factory, node)
        local elementData = node:GetData()
        if elementData.zoneCategoryData then
            local function Initializer(button, node)
                button:Init(node)
                button:SetScript("OnClick", function(button, buttonName)
                    node:ToggleCollapsed()
                    button:SetCollapseState(node:IsCollapsed())
                end)
            end
            factory("DRL_RaceListZoneButtonTemplate", Initializer)
        elseif elementData.raceData then
            local function Initializer(button, node)
                button:Init(node);
                local selected = self.selectionBehavior:IsElementDataSelected(node)
                button:SetSelected(selected)
                button:SetScript("OnClick", function(button, buttonName, down)
                    self.selectionBehavior:Select(button)
                    PlaySound(SOUNDKIT.UI_90_BLACKSMITHING_TREEITEMCLICK)
                end)
            end
            factory("DRL_RaceListRaceButtonTemplate", Initializer)
        else
            WCCCAD.UI:PrintAddOnMessage("Invalid race node", ns.consts.MSG_TYPE.ERROR)
        end
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, self.view)

    -- Race select behaviour
    self.selectionBehavior = ScrollUtil.AddSelectionBehavior(self.ScrollBox)
    self.selectionBehavior:RegisterCallback(SelectionBehaviorMixin.Event.OnSelectionChanged, self.OnRaceSelectionChanged, self)
end

function DRL_RaceListMixin:OnRaceSelectionChanged(elementData, selected)
    local button = self.ScrollBox:FindFrame(elementData)
    if button then
        button:SetSelected(selected)
    end
    if selected then
        local data = elementData:GetData()
        assert(data.raceData)
        if data.raceData.raceID ~= DRL.LeaderboardUI.selectedRaceID then
            DRL.LeaderboardUI:SelectRace(data.raceData.raceID)
        end
    end
end

function DRL_RaceListMixin:OnTabSelected(tab, tabIndex)
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
    self.selectedRaceType = tab.raceType
    self:BuildRaceList()
end

function DRL_RaceListMixin:OnShow()
    self:Refresh()
end

---
--- Refreshes the selected state of items in the race list to reflect the selected race.
---
function DRL_RaceListMixin:Refresh()
    if not self.initialLoadComplete then
        self:BuildRaceList()
    end
    -- Update selected state.
    local raceNode = self:GetNodeForRace(DRL.LeaderboardUI.selectedRaceID)
    if raceNode == nil then
        self.selectionBehavior:DeselectSelectedElements()
        return
    end
    self.selectionBehavior:SelectElementData(raceNode)
    -- Update each race entry.
    self.view:ForEachFrame(function(frame, elementData)
        frame:Refresh()
    end)
end

---
--- @return table @Scroll list element node for the specified raceID, if it exists.
---
function DRL_RaceListMixin:GetNodeForRace(raceID)
    local nodeIndex, raceNode = self.ScrollBox:FindByPredicate(function(node)
        return node:GetData().raceData and node:GetData().raceData.raceID == raceID
    end)
    return raceNode
end

---
--- Builds the list of races for the currently selected tab.
---
function DRL_RaceListMixin:BuildRaceList()
    local dataProvider = CreateTreeDataProvider()

    -- Removes a leading "the" from a string.
    local function StripLeadingThe(str)
        local firstWord = str:match("(%w+%s+)")
        if firstWord and firstWord:gsub("%s", ""):lower() == "the" then
            str = str:gsub(firstWord, "", 1)
        end
        return str
    end
    -- Insert race entries with each location as a category header.
    local function SortComparator(a, b)
        local aData, bData = a:GetData(), b:GetData()
        if aData.zoneCategoryData then
            -- Strip "The" to sort by main zone name.
            local aMapName = StripLeadingThe(C_Map.GetMapInfo(aData.zoneCategoryData.zoneID).name)
            local bMapName = StripLeadingThe(C_Map.GetMapInfo(bData.zoneCategoryData.zoneID).name)
            return aMapName < bMapName
        end
        return DRL:GetRaceName(aData.raceData.raceID) < DRL:GetRaceName(bData.raceData.raceID)
    end

    local selectedNode
    local categoryNode
    local zoneDataProviders = {}
    for _, raceData in pairs(DRL.races) do
        -- Create category for the zone if there isn't one yet
        categoryNode = zoneDataProviders[raceData.zoneID]
        if categoryNode == nil then
            categoryNode = dataProvider:Insert({zoneCategoryData = {zoneID = raceData.zoneID}})
            zoneDataProviders[raceData.zoneID] = categoryNode
        end
        if raceData.raceType == self.selectedRaceType then
            local node = categoryNode:Insert({raceData = raceData})
            sortAffectChildren = false
            if raceData.raceID == DRL.LeaderboardUI.selectedRaceID then
                selectedNode = node
                node:SetCollapsed(false)
            end
        end
    end
    local addSortToChildren = true
    local skipSort = false
    dataProvider:SetSortComparator(SortComparator, addSortToChildren, skipSort)
    self.ScrollBox:SetDataProvider(dataProvider)
    if selectedNode then
        self.ScrollBox:ScrollToElementData(selectedNode)
        self.selectionBehavior:SelectElementData(selectedNode)
    end
    self.initialLoadComplete = true
    self:Refresh()
end
--endregion