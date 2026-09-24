--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD
local ClubbingComp = WCCCAD:GetModule("WCCC_ClubbingCompetition")

---@type table<number, boolean> @Table of restricted zones.
ClubbingComp.RESTRICTED_ZONES =
{
    -- Chamber of Heart
    [1473] = true,
    -- Oribos (all floors)
    [1670] = true,
    [1671] = true,
    [1672] = true,
    [1673] = true,
    -- Valdrakken
    [2112] = true,
    -- Stormwind
    [84] = true,
    -- Ironforge
    [87] = true,
    -- Darnassus
    [89] = true,
    -- The Exodar
    [103] = true,
    -- Boralus
    [1161] = true,
    -- Dornagol
    [2339] = true
}

---@class RaceData
---@field type string @Race type to register hits under
---@field name string @Front-facing singular name
---@field pluralName string @Front-facing plural name
---@field score number @Number of points to award when clubbed

---@type table<string, RaceData> @Table of in-game race IDs to RaceData.
ClubbingComp.RACES =
{
    ["Human"] =
    {
        type = "Human",
        name = "Human",
        pluralName = "Humans",
        score = 1
    },

    ["Draenei"] =
    {
        type = "Draenei",
        name = "Draenei",
        pluralName = "Draenei",
        score = 1
    },

    ["Dwarf"] =
    {
        type = "Dwarf",
        name = "Dwarf",
        pluralName = "Dwarves",
        score = 1
    },

    ["NightElf"] =
    {
        type = "NightElf",
        name = "Elf",
        pluralName = "Elves",
        score = 1
    },

    ["Dracthyr"] =
    {
        type = "Dracthyr",
        name = "Dracthyr",
        pluralName = "Dracthyr",
        score = 1,
    },

    ["Gnome"] =
    {
        type = "Gnome",
        name = "Gnome",
        pluralName = "Gnomes",
        score = 2
    },

    ["Pandaren"] =
    {
        type = "Pandaren",
        name = "Pandaren",
        pluralName = "Pandaren",
        score = 2
    },

    ["Worgen"] =
    {
        type = "Worgen",
        name = "Worgen",
        pluralName = "Worgen",
        score = 3,
    },

    ["Orc"] =
    {
        type = "Orc",
        name = "Orc",
        pluralName = "Orcs",
        score = 1,
    },

    ["Scourge"] =
    {
        type = "Scourge",
        name = "Undead",
        pluralName = "Undead",
        score = 1,
    },

    ["Tauren"] =
    {
        type = "Tauren",
        name = "Tauren",
        pluralName = "Tauren",
        score = 1,
    },

    ["Troll"] =
    {
        type = "Troll",
        name = "Troll",
        pluralName = "Trolls",
        score = 1,
    },

    ["Goblin"] =
    {
        type = "Goblin",
        name = "Goblin",
        pluralName = "Goblins",
        score = 2,
    },

    ["Vulpera"] =
    {
        type = "Vulpera",
        name = "Vulpera",
        pluralName = "Vulpera",
        score = 2,
    },

    ["BloodElf"] =
    {
        type = "BloodElf",
        name = "Blood Elf",
        pluralName = "Blood Elves",
        score = 2,
    }
}
ClubbingComp.RACES["LightforgedDraenei"] = ClubbingComp.RACES["Draenei"]
ClubbingComp.RACES["VoidElf"] = ClubbingComp.RACES["NightElf"]
ClubbingComp.RACES["KulTiran"] = ClubbingComp.RACES["Human"]
ClubbingComp.RACES["DarkIronDwarf"] = ClubbingComp.RACES["Dwarf"]
ClubbingComp.RACES["Earthen"] = ClubbingComp.RACES["Dwarf"]
ClubbingComp.RACES["Mechagnome"] = ClubbingComp.RACES["Gnome"]
ClubbingComp.RACES["Nightborne"] = ClubbingComp.RACES["BloodElf"]
ClubbingComp.RACES["MagharOrc"] = ClubbingComp.RACES["Orc"]
ClubbingComp.RACES["HighmountainTauren"] = ClubbingComp.RACES["Tauren"]
ClubbingComp.RACES["ZandalariTroll"] = ClubbingComp.RACES["Troll"]

ClubbingComp.PRIMARY_RACE = ClubbingComp.RACES["Worgen"]