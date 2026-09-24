--
-- List of CollectionEntry in the Collection UI
--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD
local ClubbingCollection = WCCCAD:GetModule("WCCC_ClubbingCollection")

local UNCOLLECTED_FONT_COLOUR = CreateColor(230/255, 230/255, 230/255)
local COLLECTED_FONT_COLOUR = CreateColor(255/255, 156/255, 21/255)

--region Collection Entry
CC_EntryMixin = {}

function CC_EntryMixin:Init(collectionEntry)
    self.collectionEntry = collectionEntry
    self:Refresh()
end

function CC_EntryMixin:Refresh()
    local isCollected = ClubbingCollection:IsCollected(self.collectionEntry.unitID)
    self.ClueLabel:SetVertexColor(UNCOLLECTED_FONT_COLOUR:GetRGB())
    if isCollected then
        self.NameLabel:SetText(self.collectionEntry.targetName)
        self.NameLabel:SetVertexColor(COLLECTED_FONT_COLOUR:GetRGB())
        -- TODO: Replace with Achievement style short date.
        --self.DescText:SetText(format("Collected %s", ns.utils.LongDate()))
        self.ClueLabel:SetText(self.collectionEntry.clue)
        self.RestrictionsPrompt:SetShown(false)
        self.Background:SetColorTexture(1, 0.82, 0, 0.10)
        self.IconBorder:SetVertexColor(1, 0.82, 0)
        self.Icon:SetTexture("Interface\\Icons\\INV_HOLIDAY_BEERFEST_BEERFESTTROPHY")
    else
        self.NameLabel:SetText("???")
        self.NameLabel:SetVertexColor(UNCOLLECTED_FONT_COLOUR:GetRGB())
        self.ClueLabel:SetText(self.collectionEntry.clue)
        self.RestrictionsPrompt:SetShown(self.collectionEntry.restrictions ~= nil)
        self.Background:SetColorTexture(0, 0, 0, 0.15)
        self.IconBorder:SetVertexColor(0.4, 0.4, 0.4)
        self.Icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
end

function CC_EntryMixin:OnEnter()
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
