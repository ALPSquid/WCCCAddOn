--
-- Earned collection item popup, based on AchievementAlertFrameTemplate.
--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD
local ClubbingCollection = WCCCAD:GetModule("WCCC_ClubbingCollection")

function ClubbingCollectionAlertFrame_SetUp(frame, unitID)
    local collectionEntry = ClubbingCollection:GetCollectionEntryForUnit(unitID)
    if not collectionEntry then
        ClubbingCollection:PrintDebugMessage("CCAlertFrame: No entry found for unit " .. unitID)
        return
    end
    frame.Name:SetText(collectionEntry.targetName)
    frame.Icon.Texture:SetTexture(ClubbingCollection.CollectionUI.DEFAULT_ICON)
    frame.id = unitID
    return true
end

function ClubbingCollectionAlertFrame_OnClick(self, button, down)
    if AlertFrame_OnClick(self, button, down) then
        return
    end

    if not self.id then
        return
    end

    if not ClubbingCollection.CollectionUI:IsShown() then
        CloseAllWindows()
        ClubbingCollection.CollectionUI:Show()
    end
    ClubbingCollection.CollectionUI.ScrollToEntry(self.id)
end

ClubbingCollectionAlertSystem = AlertFrame:AddQueuedAlertFrameSubSystem("ClubbingCollectionAlertFrameTemplate", ClubbingCollectionAlertFrame_SetUp, 2, 6)