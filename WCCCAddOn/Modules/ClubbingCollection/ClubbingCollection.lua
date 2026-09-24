--
-- Module for tracking a collection of specific targets players have clubbed.
--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
CLUBBINGCOLLECTION_GOLD_BORDER_COLOR = CreateColor(1, 0.675, 0.125)

local _, ns = ...
local WCCCAD = ns.WCCCAD
local ClubbingComp = WCCCAD:GetModule("WCCC_ClubbingCompetition")


local COMM_KEY_GUILDY_COLLECTED_ENTRY = "guildyCollectedNPC"

local collectionData =
{
    profile =
    {
        ---@class CollectedEntryData
        ---@field collectedTimestamp number @Timestamp when the entry was collected.
        ---
        ---@type table<number, CollectedEntryData>
        collection =
        {
            -- [unitID] = { collectedTimestamp = <timestamp> }
        }
    }
}

local ClubbingCollection = WCCCAD:CreateModule("WCCC_ClubbingCollection", collectionData)
LibStub("AceEvent-3.0"):Embed(ClubbingCollection)
ClubbingCollection.COLLECTION_UPDATED_EVENT = ClubbingCollection.moduleName .. "COLLECTION_UPDATED_EVENT"

function ClubbingCollection:InitializeModule()
    self:RegisterModuleSlashCommand("cc", self.CCCommand)
    self:RegisterModuleComm(COMM_KEY_GUILDY_COLLECTED_ENTRY, ClubbingCollection.OnGuildyCollectedEntryCommReceived)
    self:PrintDebugMessage("Clubbing Collection module loaded.")
end

function ClubbingCollection:OnEnable()
    self:RegisterMessage(ClubbingComp.UNIT_CLUBBED_EVENT, self.OnUnitClubbed, self)
end

function ClubbingCollection:OnDisable()
    self:UnregisterMessage(ClubbingComp.UNIT_CLUBBED_EVENT)
end

---
--- Generic chat command, opens the config panel when the wccc command is entered.
---
function ClubbingCollection:CCCommand(args)
    if args ~= nil and args[1] ~= nil then
        if args[1] == "info" or args[1] == "settings" then
            self.UI:Show()
        end
        return
    end
    self.CollectionUI:Show()
end

---region Data Accessors
---
--- @returns static collections DB
---
function ClubbingCollection:GetCollectionEntries()
    return ClubbingCollection.CollectionEntries
end

---
--- @returns CollectionEntry|nil collection entry for the unit if one exists.
---
function ClubbingCollection:GetCollectionEntryForUnit(unit)
    return self:GetCollectionEntries()[ns.utils.GetUnitID(unit)]
end

---
--- @returns table<CollectionEntry> collection entries for the zone if any exist.
---
function ClubbingCollection:GetZoneCollectionEntries(zoneID)
    local entries = {}
    for _, collectionEntry in pairs(self:GetCollectionEntries()) do
        if zoneID == nil then
            tinsert(entries, collectionEntry)
        elseif collectionEntry.restrictions then
            for _, entryZoneID in ipairs(collectionEntry.restrictions.zones) do
                if entryZoneID == zoneID then
                    tinsert(entries, collectionEntry)
                    break
                end
            end
        end
    end
    return entries
end

---
--- @return CollectedEntryData|nil collected data for the entry or nil if it hasn't been collected.
---
function ClubbingCollection:GetCollectedEntryData(unitID)
    return self.moduleDB.collection[unitID]
end

---
--- @return boolean True if the specified unit has been collected by the player.
---
function ClubbingCollection:IsCollected(unitID)
    return self:GetCollectedEntryData(unitID) ~= nil
end
---endregion


function ClubbingCollection:OnUnitClubbed(event, unit)
    local collectionEntry = self:GetCollectionEntryForUnit(unit)
    if not collectionEntry then return end

    if self:IsCollected(collectionEntry.unitID) then
        return
    end

    if not self:CanCollectUnit(collectionEntry, unit) then
        -- TODO: If this becomes a regular occurrence, come up with a nice succinct way of showing the requirements here as well.
        WCCCAD.UI:PrintAddOnMessage("That target is certainly worthy, but you don't meet the requirements.")
        return
    end

    -- We can collect it!
    self:SetEntryCollected(collectionEntry)
end

---
--- Sets a CollectionEntry as collected at the current time and dispatches relevant messages.
---
function ClubbingCollection:SetEntryCollected(collectionEntry)
    if not collectionEntry then return end
    if self:IsCollected(collectionEntry.unitID) then return end
    self.moduleDB.collection[collectionEntry.unitID] =
    {
        collectedTimestamp = GetServerTime()
    }

    -- TODO: SFX
    WCCCAD.UI:PrintAddOnMessage(format("Congratulations! You've added %s to your collection!", collectionEntry.targetName))
    local data =
    {
        targetName = collectionEntry.targetName,
        playerName = UnitName("player"),
    }
    self:SendMessage(self.COLLECTION_UPDATED_EVENT)
    self:SendModuleComm(COMM_KEY_GUILDY_COLLECTED_ENTRY, data, ns.consts.CHAT_CHANNEL.GUILD)
    -- TODO: Queue toast
    self.CollectionUI:Refresh()
end

function ClubbingCollection:OnGuildyCollectedEntryCommReceived(data)
    local message = format("%s has added %s to their Clubbing Collection!", data.playerName, data.targetName)
    WCCCAD.UI:PrintAddOnMessage(message, ns.consts.MSG_TYPE.GUILD)
end

---
--- Returns true if the player meets the requirements for the specified collection.
--- @param unit string Unit in focus. Usually "target".
--- @param collectionEntry CollectionEntry Collection entry the unit belongs to obtained via GetCollectionEntryForUnit
---
function ClubbingCollection:CanCollectUnit(collectionEntry, unit)
    if not collectionEntry then return false end

    if UnitPlayerControlled(unit) == true then
        return false
    end

    local unitLevel = UnitLevel(unit)

    local restrictions = collectionEntry.restrictions
    if not restrictions then
        return true
    end

    -- Min level
    if restrictions.minLevel ~= nil and unitLevel > 0 and unitLevel < restrictions.minLevel then
        return false
    end
    -- Max level
    if restrictions.maxLevel ~= nil and unitLevel > 0 and unitLevel > restrictions.maxLevel then
        return false
    end
    -- Zone
    if #restrictions.zones > 0 and not ns.utils.TableContains(restrictions.zones, C_Map.GetBestMapForUnit("player")) then
        return false
    end
    -- Dynamic restrictions
    if restrictions.bespokeCondition ~= nil and not restrictions.bespokeCondition() then
        return false
    end

    return true
end