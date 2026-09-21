--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local ClubbingComp = WCCCAD:GetModule("WCCC_ClubbingCompetition")

---@type table<number, boolean> @Table of restricted zones.
ClubbingComp.RESTRICTED_ZONES =
{
}

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

    ["Gnome"] =
    {
        type = "Gnome",
        name = "Gnome",
        pluralName = "Gnomes",
        score = 3
    },
}
-- Leaving these out for now since they're cross faction.
--ClubbingComp.RACES["Skyborne"] = ClubbingComp.RACES["NightElf"]

ClubbingComp.PRIMARY_RACE = ClubbingComp.RACES["Gnome"]