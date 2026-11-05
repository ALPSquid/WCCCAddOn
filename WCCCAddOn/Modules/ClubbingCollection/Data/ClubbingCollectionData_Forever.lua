--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--

local _, ns = ...
local WCCCAD = ns.WCCCAD
local ClubbingCollection = WCCCAD:GetModule("WCCC_ClubbingCollection")

-- TODO: Update schema to match new restriction format
---@type table<number, CollectionEntry>
ClubbingCollection.CollectionEntries =
{
    [0] =
    {
        unitID = 0,
        targetName = "Coming Soon!",
        clue = "Clubbing Collection is coming soon!",
        --restrictions =
        --{
        --    maxLevel = 20,
        --    zones = { 10 },
        --}
    }
}