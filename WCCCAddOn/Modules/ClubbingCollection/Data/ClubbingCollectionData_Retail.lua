--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--

---@class CollectionEntryRestrictions
---@field minLevel number|nil @Target must be at least this level.
---@field maxLevel number|nil @Target must be at or below this level.
---@field zones table<number>|nil @Array of Zone IDs from C_Map.GetBestMapForUnit the target must be clubbed in.
---@field bespokeCondition fun():boolean|nil @Dynamic availability/restriction conditions.
---@field bespokeDesc string @Player-facing description of the bespoke restrictions.

---@class CollectionEntry
---@field unitID number @ID of the unit obtained via UnitGUID("target") or WoWHead etc.
---@field targetName string @Name of the target to club. Must match the NPC/object name exactly.
---@field clue string @A cryptic hint to the target.
---@field restrictions CollectionEntryRestrictions @Restrictions that must be met to collect the target.

local _, ns = ...
local WCCCAD = ns.WCCCAD
local ClubbingCollection = WCCCAD:GetModule("WCCC_ClubbingCollection")

---@type table<number, CollectionEntry>
ClubbingCollection.CollectionEntries =
{
    [3248] =
    {
        unitID = 3248,
        targetName = "Barrens Giraffe",
        clue = "Towers in the heat.",
        restrictions =
        {
            maxLevel = 20,
            zones = { 10 },
        }
    },

    [111] =
    {
        unitID = 111,
        targetName = "Test Entry",
        clue = "Towers in the heat.",
    }
}