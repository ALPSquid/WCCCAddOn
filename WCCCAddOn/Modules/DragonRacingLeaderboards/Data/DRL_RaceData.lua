--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--

local _, ns = ...
local WCCCAD = ns.WCCCAD
local DRL = WCCCAD:GetModule("WCCC_DragonRacingLeaderboards")
DRL.races = {}

DRL.RACE_TYPE = {
    NORMAL = 0,
    ADVANCED = 1,
    REVERSE = 2
}


---
--- Register a race and its advanced version in the race data table.
--- @param questID number @Quest ID of the normal race WoW uses to track the race.
--- @param advancedQuestID number optional @Quest ID of the advanced race WoW uses to track the race, if an advanced version exists.
--- @param zoneID number @ID of the zone where the race is situated. Obtain with C_Map.GetBestMapForUnit("player").
--- @param timekeeperX number @X coord of the Timekeeper Assistant that outputs player times. Obtain with /run print(C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player"):GetXY())
--- @param timekeeperY number @Y coord of the Timekeeper Assistant that outputs player times. Obtain with /run print(C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player"):GetXY())
---
function DRL:RegisterRace(questID, advancedQuestID, reverseQuestID, zoneID, timekeeperX, timekeeperY)
    if self.races[questID] ~= nil then
        WCCCAD.UI:PrintAddOnMessage(format("Race id '%s' already registered!", questID), ns.consts.MSG_TYPE.ERROR)
        return
    end

    -- Normal
    self.races[questID] = {
        raceID = questID,
        questID = questID,
        zoneID = zoneID,
        coordX = timekeeperX,
        coordY = timekeeperY,
        raceType = DRL.RACE_TYPE.NORMAL
    }

    -- Advanced
    if advancedQuestID then
        self.races[advancedQuestID] = {
            raceID = advancedQuestID,
            questID = advancedQuestID,
            zoneID = zoneID,
            coordX = timekeeperX,
            coordY = timekeeperY,
            raceType = DRL.RACE_TYPE.ADVANCED
        }
    end

    -- REVERSE
    if reverseQuestID then
        self.races[reverseQuestID] = {
            raceID = reverseQuestID,
            questID = reverseQuestID,
            zoneID = zoneID,
            coordX = timekeeperX,
            coordY = timekeeperY,
            raceType = DRL.RACE_TYPE.REVERSE
        }
    end
end

---
--- @param raceID number @ID of the race used with DRL:RegisterRace.
--- @return string @Localised name for the specified race.
---
function DRL:GetRaceName(raceID)
    return self.Locale["RACE_NAME_"..raceID]
end

-- Obtain coords with /run print(C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player"):GetXY())
-- DRL:RegisterRace("emerald_gardens", 2023, "name", 0.000, 0.000)

-- Waking Shores
-- Apex Canopy River Run
DRL:RegisterRace(66732, 66733, 72734, 2022, 0.232, 0.842)
-- Emberflow Flight
DRL:RegisterRace(66727, 66728, 72707, 2022, 0.419, 0.673)
-- Flashfrost Flyover
DRL:RegisterRace(66710, 66712, 72700, 2022, 0.627, 0.739)
-- Ruby Lifeshrine Loop
DRL:RegisterRace(66679, 66692, 72052, 2022, 0.632, 0.708)
-- Uktulut Coaster
DRL:RegisterRace(66777, 66778, 72739, 2022, 0.554, 0.411)
-- Wild Preserve Circuit
DRL:RegisterRace(66725, 66726, 72706, 2022, 0.427, 0.941)
-- Wild Preserve Slalom
DRL:RegisterRace(66721, 66722, 72705, 2022, 0.470, 0.855)
-- Wingrest Roundabout
DRL:RegisterRace(66786, 66787, 72740, 2022, 0.731, 0.339)

-- Ohn'ahran Plain
-- Emerald Garden Ascent
DRL:RegisterRace(66885, 66886, 72805, 2023, 0.257, 0.550)
-- Fen Flythrough
DRL:RegisterRace(66877, 66878, 72802, 2023, 0.862, 0.358)
-- Maruukai Dash
DRL:RegisterRace(66921, nil, nil, 2023, 0.602, 0.355)
-- Mirror of the Sky Dash
DRL:RegisterRace(66933, nil, nil, 2023, 0.474, 0.706)
-- Ravine River Run
DRL:RegisterRace(66880, 66881, 72803, 2023, 0.808, 0.721)
-- River Rapids Route
DRL:RegisterRace(70710, 70711, 72807, 2023, 0.437, 0.668)
-- Sundapple Copse Circuit
DRL:RegisterRace(66835, 66836, 72801, 2023, 0.637, 0.305)

-- Azure Span
-- Archive Ambit
DRL:RegisterRace(67741, 67742, 72797, 2024, 0.422, 0.567)
-- Azure Span Slalom
DRL:RegisterRace(67002, 67003, 72799, 2024, 0.209, 0.226)
-- Azure Span Sprint
DRL:RegisterRace(66946, 66947, 72796, 2024, 0.479, 0.407)
-- Frostland Flyover
DRL:RegisterRace(67565, 67566, 72795, 2024, 0.484, 0.358)
-- Iskaara Tour
DRL:RegisterRace(67296, 67297, 72800, 2024, 0.165, 0.493)
-- Vakthros Ascent
DRL:RegisterRace(67031, 67032, 72794, 2024, 0.713, 0.246)

-- Thaldraszus
-- Academy Ascent
DRL:RegisterRace(70059, 70060, 72754, 2025, 0.603, 0.416)
-- Caverns Criss-Cross
DRL:RegisterRace(70161, 70163, 72750, 2025, 0.580, 0.336)
-- Cliffside Circuit
DRL:RegisterRace(70051, 70052, 72760, 2025, 0.376, 0.489)
-- Flowing Forest Flight
DRL:RegisterRace(67095, 67096, 72793, 2025, 0.577, 0.750)
-- Garden Gallivant
DRL:RegisterRace(70157, 70158, 72769, 2025, 0.395, 0.761)
-- Tyrhold Trial
DRL:RegisterRace(69957, 69958, 72792, 2025, 0.572, 0.668)


