--
-- UI displaying the Clubbing Collection DB, similar to the Achievements UI.
--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD
local ClubbingCollection = WCCCAD:GetModule("WCCC_ClubbingCollection")
ClubbingCollection.CollectionUI = {}
ClubbingCollection.CollectionUI.selectedZoneID = nil


function ClubbingCollection.CollectionUI:Show()
    CC_COLLECTION_UI_FRAME:Show()
end

---
--- Select the zone to filter by. If nil, all entries will be shown.
--- UI is refreshed automatically as part of this function.
---
function ClubbingCollection.CollectionUI:SelectZone(zoneID)
    self.selectedZoneID = zoneID
    self:Refresh()
end

function ClubbingCollection.CollectionUI:Refresh()
    if CC_COLLECTION_UI_FRAME:IsVisible() then
        CC_COLLECTION_UI_FRAME.ZoneListFrame:Refresh()
        CC_COLLECTION_UI_FRAME.EntriesListFrame:Refresh()
    end
end

CC_CollectionUIMixin = {}

function CC_CollectionUIMixin:OnLoad()
    self.TitleContainer.TitleText:SetText("Clubbing Collection")
    self:RegisterForDrag("LeftButton")
    tinsert(UISpecialFrames, self:GetName())
end

function CC_CollectionUIMixin:OnShow()
    ClubbingCollection.CollectionUI:SelectZone(ClubbingCollection.CollectionUI.selectedZoneID)
end