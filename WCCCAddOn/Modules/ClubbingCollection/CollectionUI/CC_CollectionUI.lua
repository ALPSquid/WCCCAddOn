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

ClubbingCollection.CollectionUI.DEFAULT_ICON = "Interface\\Icons\\INV_HOLIDAY_BEERFEST_BEERFESTTROPHY"


function ClubbingCollection.CollectionUI:Show()
    CC_COLLECTION_UI_FRAME:Show()
end

function ClubbingCollection.CollectionUI:IsShown()
    return CC_COLLECTION_UI_FRAME:IsShown()
end

---
--- Select the zone to filter by. If nil, all entries will be shown.
--- UI is refreshed automatically as part of this function.
---
function ClubbingCollection.CollectionUI:SelectZone(zoneID)
    self.selectedZoneID = zoneID
    self:Refresh()
end

---
--- Scrolls to a specific collection entry in the UI.
---
function ClubbingCollection.CollectionUI:ScrollToEntry(unitID)
    if not self:IsShown() then
        return
    end

    local collectionEntry = ClubbingCollection:GetCollectionEntryForUnit(unitID)
    -- Disable the current filter if the achievement is hidden.
    if self.selectedZoneID ~= nil then
        if collectionEntry.restrictions == nil or #collectionEntry.restrictions.zones <= 0 then
            self:SelectZone(nil)
        else
            if not ns.utils.TableContains(collectionEntry.restrictions.zones, self.selectedZoneID) then
                self.SelectZone(nil)
            end
        end
    end
    -- Scroll to the entry.
    CC_COLLECTION_UI_FRAME.EntriesListFrame:ScrollToEntry(unitID)
end

function ClubbingCollection.CollectionUI:Refresh()
    if CC_COLLECTION_UI_FRAME:IsVisible() then
        CC_COLLECTION_UI_FRAME.ZoneListFrame:Refresh()
        CC_COLLECTION_UI_FRAME.EntriesListFrame:Refresh()
    end
end

function ClubbingCollection.CollectionUI:PostCollectionTo(channel)
    local totalEntries = 0
    local collectedEntries = 0
    for _, collectionEntry in pairs(ClubbingCollection:GetCollectionEntries()) do
        totalEntries = totalEntries + 1
        if ClubbingCollection:IsCollected(collectionEntry.unitID) then
            collectedEntries = collectedEntries + 1
        end
    end

    if collectedEntries >= totalEntries then
        C_ChatInfo.SendChatMessage(format("I've clubbed all %i targets in my Clubbing Collection! I am the mightiest clubber of them all!", totalEntries), channel)
    else
        C_ChatInfo.SendChatMessage(format("I've clubbed %i/%i targets in my Clubbing Collection!", collectedEntries, totalEntries), channel)
    end
end

CC_CollectionUIMixin = {}

function CC_CollectionUIMixin:OnLoad()
    self.TitleContainer.TitleText:SetText("Clubbing Collection")
    self:RegisterForDrag("LeftButton")
    tinsert(UISpecialFrames, self:GetName())

    self.PostToGuildBtn:SetScript("OnClick", function()
        ClubbingCollection.CollectionUI:PostCollectionTo(ns.consts.CHAT_CHANNEL.GUILD)
    end)
end

function CC_CollectionUIMixin:OnShow()
    ClubbingCollection.CollectionUI:SelectZone(ClubbingCollection.CollectionUI.selectedZoneID)
end