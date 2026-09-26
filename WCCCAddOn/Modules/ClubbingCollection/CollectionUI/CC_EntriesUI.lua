--
-- List of CollectionEntry in the Collection UI
--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD
local ClubbingCollection = WCCCAD:GetModule("WCCC_ClubbingCollection")

local UNCOLLECTED_FONT_COLOUR = CreateColor(200/255, 200/255, 200/255)
local COLLECTED_FONT_COLOUR = CreateColor(255/255, 197/255, 53/255)

--region Collection Entry
CC_EntryMixin = {}

function CC_EntryMixin:Init(collectionEntry)
    self.collectionEntry = collectionEntry
    self:Refresh()
end

function CC_EntryMixin:Refresh()
    local isCollected = ClubbingCollection:IsCollected(self.collectionEntry.unitID)
    if isCollected then
        local collectedEntryData = ClubbingCollection:GetCollectedEntryData(self.collectionEntry.unitID)
        self.NameLabel:SetText(self.collectionEntry.targetName)
        self.NameLabel:SetVertexColor(COLLECTED_FONT_COLOUR:GetRGB())
        self.DateCompletedLabel:Show()
        self.DateCompletedLabel:SetText(ns.utils.ShortDate(collectedEntryData.collectedTimestamp))
        self.ClueLabel:SetText(self.collectionEntry.clue)
        self.ClueLabel:SetTextColor(0, 0, 0, 1);
        self.ClueLabel:SetShadowOffset(0, 0);
        self.RestrictionsPrompt:SetShown(true)
        -- BG
        self.Background:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal");
        self:SetBackdropBorderColor(1, 0.675, 0.125);
        -- Title Bar
        self.TitleBar:SetTexture("Interface\\AchievementFrame\\AccountLevel-AchievementHeader");
        self.TitleBar:SetTexCoord(0, 1, 0, 0.375);
        -- Icon
        self.Icon.texture:SetTexture(ClubbingCollection.CollectionUI.DEFAULT_ICON)
        self.Icon.bling:SetVertexColor(1, 1, 1, 1);
        self.Icon.frame:SetVertexColor(1, 1, 1, 1);
        self.Icon.texture:SetVertexColor(1, 1, 1, 1);
    else
        self.NameLabel:SetText("???")
        self.NameLabel:SetVertexColor(UNCOLLECTED_FONT_COLOUR:GetRGB())
        self.ClueLabel:SetText(self.collectionEntry.clue)
        self.ClueLabel:SetTextColor(1, 1, 1, 1);
        self.ClueLabel:SetShadowOffset(1, -1);
        self.RestrictionsPrompt:SetShown(self.collectionEntry.restrictions ~= nil)
        self.DateCompletedLabel:Hide()
        -- BG
        self.Background:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal-Desaturated");
        self:SetBackdropBorderColor(.5, .5, .5);
        -- Title Bar
        self.TitleBar:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Borders");
        self.TitleBar:SetTexCoord(0, 1, 0.91796875, 0.99609375);
        -- Icon
        self.Icon.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        self.Icon.bling:SetVertexColor(.6, .6, .6, 1);
        self.Icon.frame:SetVertexColor(.75, .75, .75, 1);
        self.Icon.texture:SetVertexColor(.55, .55, .55, 1);
    end
end

function CC_EntryMixin:OnEnter()
    self.Highlight:Show()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT")
    GameTooltip:SetText(ClubbingCollection:IsCollected(self.collectionEntry.unitID) and self.collectionEntry.targetName or "???")
    GameTooltip:AddLine(self.collectionEntry.clue, 0.8, 0.8, 0.8, true)
    if self.collectionEntry.restrictions then
        GameTooltip:AddLine("Requirements:", 0.6, 0.6, 0.6, false)
        if self.collectionEntry.restrictions.minLevel and self.collectionEntry.restrictions.minLevel > 0 then
            GameTooltip:AddLine("  - Min Level: " .. self.collectionEntry.restrictions.minLevel, 0.6, 0.6, 0.6, false)
        end
        if self.collectionEntry.restrictions.maxLevel and self.collectionEntry.restrictions.maxLevel > 0 then
            GameTooltip:AddLine("  - Max Level: " .. self.collectionEntry.restrictions.maxLevel, 0.6, 0.6, 0.6, false)
        end
        if self.collectionEntry.restrictions.bespokeDesc ~= nil then
            GameTooltip:AddLine("  - " .. self.collectionEntry.bespokeDesc, 0.6, 0.6, 0.6, false)
        end
        if #self.collectionEntry.restrictions.zones > 0 then
            GameTooltip:AddLine("  - Zones:", 0.6, 0.6, 0.6, false)
            for _, zoneID in ipairs(self.collectionEntry.restrictions.zones) do
                GameTooltip:AddLine("    - " .. C_Map.GetMapInfo(zoneID).name, 0.6, 0.6, 0.6, false)
            end
        end
    end
    GameTooltip:Show()
end

function CC_EntryMixin:OnLeave()
    self.Highlight:Hide()
    GameTooltip:Hide()
end

--endregion

--region Collection Entry List
CC_EntriesListMixin = {}

function CC_EntriesListMixin:OnLoad()
    local indent = 0
    local padLeft = 0
    local pad = 0
    local spacing = 0
    self.view = CreateScrollBoxListLinearView(indent, pad, pad, padLeft, pad, spacing)
    self.view:SetElementInitializer("CC_EntryTemplate", function(button, node)
        button:Init(node)
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.Container.ScrollBox, self.Container.ScrollBar, self.view)
end

function CC_EntriesListMixin:OnShow()
    self:Refresh()
end

---
--- @return table @Scroll list element data for the specified unitID, if it exists.
---
function CC_ZoneListMixin:GetElementDataForUnit(unitID)
    local nodeIndex, entryElementData = self.Container.ScrollBox:FindByPredicate(function(elementData)
        return elementData.unitID == unitID
    end)
    return entryElementData
end

---
--- Scrolls to a specific collection entry in the UI if visible.
---
function CC_EntriesListMixin:ScrollToEntry(unitID)
    local dataProvider = self.Container.ScrollBox:GetDataProvider()
    if not dataProvider then return end

    local elementData = self:GetElementDataForUnit(unitID)
    if not elementData then return end
    self.Container.ScrollBox:ScrollToElementData(elementData, ScrollBoxConstants.AlignCenter)
end

---
--- Rebuilds the entries list for the selected zone.
---
function CC_EntriesListMixin:Refresh()
    if not self:IsVisible() then return end
    local entries = ClubbingCollection:GetZoneCollectionEntries(ClubbingCollection.CollectionUI.selectedZoneID)
    -- Not a very meaningful sort but at least keeps it consistent.
    -- We want to avoid sorting alphabetically since that gives away the name.
    local function SortComparator(a, b)
        return a.unitID < b.unitID
    end

    local dataProvider = CreateDataProvider()
    dataProvider:Init(entries)
    local skipSort = false
    dataProvider:SetSortComparator(SortComparator, skipSort)
    self.Container.ScrollBox:SetDataProvider(dataProvider)
end

--endregion
