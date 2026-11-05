--
-- Zone list to filter the Clubbing Collection by.
--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD
local ClubbingCollection = WCCCAD:GetModule("WCCC_ClubbingCollection")

local INCOMPLETE_FONT_COLOUR = NORMAL_FONT_COLOR
--local INCOMPLETE_HIGHLIGHT_FONT_COLOUR = HIGHLIGHT_FONT_COLOR
local COMPLETE_FONT_COLOUR = CreateColor(83/255, 202/255, 60/255)
--local COMPLETE_HIGHLIGHT_FONT_COLOUR = CreateColor(123/255, 226/255, 103/255)

--region Zone Entry Button

CC_ZoneEntryMixin = {}

function CC_ZoneEntryMixin:Init(elementData)
    self.data = elementData
    self.CountLabel:SetJustifyH("RIGHT")
    self:Refresh()
end

function CC_ZoneEntryMixin:Refresh()
    local entries = ClubbingCollection:GetZoneCollectionEntries(self.data.zoneID)
    local collectedCount = 0
    for _, collectionEntry in ipairs(entries) do
        if ClubbingCollection:IsCollected(collectionEntry.unitID) then
            collectedCount = collectedCount + 1
        end
    end
    self.Label:SetText(self.data.zoneName)
    self.CountLabel:SetText(format("(%d/%d)", collectedCount, #entries))
    -- Colour based on complete
    self.isComplete = false
    if collectedCount >= #entries then
        self.isComplete = true
        self.Label:SetVertexColor(COMPLETE_FONT_COLOUR:GetRGB())
        self.CountLabel:SetVertexColor(COMPLETE_FONT_COLOUR:GetRGB())
    else
        self.Label:SetVertexColor(INCOMPLETE_FONT_COLOUR:GetRGB())
        self.CountLabel:SetVertexColor(INCOMPLETE_FONT_COLOUR:GetRGB())
    end
end

function CC_ZoneEntryMixin:SetSelected(selected)
    if selected then
        self:LockHighlight()
    else
        self:UnlockHighlight()
    end
end

function CC_ZoneEntryMixin:OnEnter()
    --self.HighlightOverlay:SetShown(true)
end

function CC_ZoneEntryMixin:OnLeave()
    --self.HighlightOverlay:SetShown(false)
end

--endregion

--region Zone List

CC_ZoneListMixin = {}
CC_ZoneListMixin.ClubbingCollection = ClubbingCollection

function CC_ZoneListMixin:OnLoad()
    local indent = 0
    local padLeft = 0
    local pad = 0
    local spacing = 0
    self.view = CreateScrollBoxListLinearView(indent, pad, pad, padLeft, pad, spacing)
    self.view:SetElementInitializer("CC_ZoneEntryTemplate", function(button, elementData)
        button:Init(elementData)
        local selected = self.selectionBehavior:IsElementDataSelected(elementData)
        button:SetSelected(selected)
        button:SetScript("OnClick", function(button, buttonName, down)
            self.selectionBehavior:Select(button)
            PlaySound(SOUNDKIT.UI_90_BLACKSMITHING_TREEITEMCLICK)
        end)

    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.Container.ScrollBox, self.Container.ScrollBar, self.view)
    self.selectionBehavior = ScrollUtil.AddSelectionBehavior(self.Container.ScrollBox)
    self.selectionBehavior:RegisterCallback(SelectionBehaviorMixin.Event.OnSelectionChanged, self.OnZoneSelectionChanged, self)
end

function CC_ZoneListMixin:OnZoneSelectionChanged(elementData, selected)
    local button = self.Container.ScrollBox:FindFrame(elementData)
    if button then
        button:SetSelected(selected)
    end
    if selected and ClubbingCollection.CollectionUI.selectedZoneID ~= elementData.zoneID then
        self.ClubbingCollection.CollectionUI:SelectZone(elementData.zoneID)
    end
end


function CC_ZoneListMixin:OnShow()
    self:Refresh()
end

---
--- Refreshes the selected state of items in the zone list to reflect the selected zone.
---
function CC_ZoneListMixin:Refresh()
    if not self:IsVisible() then return end
    if not self.initialLoadComplete then
        self:BuildZoneList()
    end
    -- Update selected state.
    local zoneElementData = self:GetElementDataForZone(self.ClubbingCollection.CollectionUI.selectedZoneID)
    if zoneElementData == nil then
        self.selectionBehavior:DeselectSelectedElements()
        return
    end
    self.selectionBehavior:SelectElementData(zoneElementData)
    -- Update each entry
    self.view:ForEachFrame(function(frame)
        frame:Refresh()
    end)
end

---
--- @return table @Scroll list element data for the specified zoneID, if it exists.
---
function CC_ZoneListMixin:GetElementDataForZone(zoneID)
    local _, zoneElementData = self.Container.ScrollBox:FindByPredicate(function(elementData)
        return elementData.zoneID == zoneID
    end)
    return zoneElementData
end

---
--- Builds list of zone buttons.
---
function CC_ZoneListMixin:BuildZoneList()
    local dataProvider = CreateDataProvider()

    local function SortComparator(a, b)
        return a.sortName < b.sortName
    end

    local addedZones = {}
    local zoneEntries =
    {
        -- "All" entry
        {
            zoneID = nil,
            zoneName = "All",
            sortName = "_1"
        }
    }

    for _, collectionEntry in pairs(ClubbingCollection:GetCollectionEntries()) do
        if collectionEntry.restrictions then
            for _, zoneID in ipairs(collectionEntry.restrictions.zones) do
                if addedZones[zoneID] == nil then
                    local zoneName = C_Map.GetMapInfo(zoneID).name
                    addedZones[zoneID] = true
                    tinsert(zoneEntries, {
                        zoneID = zoneID,
                        zoneName = zoneName,
                        sortName = ns.utils.StripLeadingWord("the", zoneName)
                    })
                end
            end
        end
    end
    local addSortToChildren = true
    local skipSort = false
    dataProvider:Init(zoneEntries)
    dataProvider:SetSortComparator(SortComparator, addSortToChildren, skipSort)
    self.Container.ScrollBox:SetDataProvider(dataProvider)

    local selectedNode = self:GetElementDataForZone(ClubbingCollection.CollectionUI.selectedZoneID)
    self.Container.ScrollBox:ScrollToElementData(selectedNode)
    self.selectionBehavior:SelectElementData(selectedNode)
    self.initialLoadComplete = true
end

--endregion
