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
--- @param currencyID number @Currency ID the normal race used to store personal best time.
--- @param advancedQuestID number optional @Quest ID of the advanced race WoW uses to track the race, if an advanced version exists.
--- @param advancedCurrencyID number @Currency ID the advanced race used to store personal best time.
--- @param reverseQuestID number optional @Quest ID of the reverse race WoW uses to track the race, if an advanced version exists.
--- @param reverseCurrencyID number @Currency ID the reverse race used to store personal best time.
--- @param zoneID number @ID of the zone where the race is situated. Obtain with C_Map.GetBestMapForUnit("player").
--- @param timekeeperX number @X coord of the Timekeeper Assistant that outputs player times. Obtain with /run print(C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player"):GetXY())
--- @param timekeeperY number @Y coord of the Timekeeper Assistant that outputs player times. Obtain with /run print(C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player"):GetXY())
---
function DRL:RegisterRace(questID, currencyID, advancedQuestID, advancedCurrencyID, reverseQuestID, reverseCurrencyID, zoneID, timekeeperX, timekeeperY)
    if self.races[questID] ~= nil then
        WCCCAD.UI:PrintAddOnMessage(format("Race id '%s' already registered!", questID), ns.consts.MSG_TYPE.ERROR)
        return
    end

    -- Normal
    self.races[questID] = {
        raceID = questID,
        questID = questID,
        currencyID = currencyID,
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
            currencyID = advancedCurrencyID,
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
            currencyID = reverseCurrencyID,
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
DRL:RegisterRace(66732, 2054, 66733, 2055, 72734, 2178, 2022, 0.232, 0.842)
-- Emberflow Flight
DRL:RegisterRace(66727, 2052, 66728, 2053, 72707, 2177, 2022, 0.419, 0.673)
-- Flashfrost Flyover
DRL:RegisterRace(66710, 2046, 66712, 2047, 72700, 2181, 2022, 0.627, 0.739)
-- Ruby Lifeshrine Loop
DRL:RegisterRace(66679, 2042, 66692, 2044, 72052, 2154, 2022, 0.632, 0.708)
-- Uktulut Coaster
DRL:RegisterRace(66777, 2056, 66778, 2057, 72739, 2179, 2022, 0.554, 0.411)
-- Wild Preserve Circuit
DRL:RegisterRace(66725, 2050, 66726, 2051, 72706, 2182, 2022, 0.427, 0.941)
-- Wild Preserve Slalom
DRL:RegisterRace(66721, 2048, 66722, 2049, 72705, 2176, 2022, 0.470, 0.855)
-- Wingrest Roundabout
DRL:RegisterRace(66786, 2058, 66787, 2059, 72740, 2180, 2022, 0.731, 0.339)

-- Ohn'ahran Plain
-- Emerald Garden Ascent
DRL:RegisterRace(66885, 2066, 66886, 2067, 72805, 2186, 2023, 0.257, 0.550)
-- Fen Flythrough
DRL:RegisterRace(66877, 2062, 66878, 2063, 72802, 2184, 2023, 0.862, 0.358)
-- Maruukai Dash
DRL:RegisterRace(66921, 2069, nil, nil, nil, nil, 2023, 0.602, 0.355)
-- Mirror of the Sky Dash
DRL:RegisterRace(66933, 2070, nil, nil, nil, nil, 2023, 0.474, 0.706)
-- Ravine River Run
DRL:RegisterRace(66880, 2064, 66881, 2065, 72803, 2185, 2023, 0.808, 0.721)
-- River Rapids Route
DRL:RegisterRace(70710, 2119, 70711, 2120, 72807, 2187, 2023, 0.437, 0.668)
-- Sundapple Copse Circuit
DRL:RegisterRace(66835, 2060, 66836, 2061, 72801, 2183, 2023, 0.637, 0.305)

-- Azure Span
-- Archive Ambit
DRL:RegisterRace(67741, 2089, 67742, 2090, 72797, 2193, 2024, 0.422, 0.567)
-- Azure Span Slalom
DRL:RegisterRace(67002, 2076, 67003, 2077, 72799, 2189, 2024, 0.209, 0.226)
-- Azure Span Sprint
DRL:RegisterRace(66946, 2074, 66947, 2075, 72796, 2188, 2024, 0.479, 0.407)
-- Frostland Flyover
DRL:RegisterRace(67565, 2085, 67566, 2086, 72795, 2192, 2024, 0.484, 0.358)
-- Iskaara Tour
DRL:RegisterRace(67296, 2083, 67297, 2084, 72800, 2191, 2024, 0.165, 0.493)
-- Vakthros Ascent
DRL:RegisterRace(67031, 2078, 67032, 2079, 72794, 2190, 2024, 0.713, 0.246)

-- Thaldraszus
-- Academy Ascent
DRL:RegisterRace(70059, 2098, 70060, 2099, 72754, 2197, 2025, 0.603, 0.416)
-- Caverns Criss-Cross
DRL:RegisterRace(70161, 2103, 70163, 2104, 72750, 2199, 2025, 0.580, 0.336)
-- Cliffside Circuit
DRL:RegisterRace(70051, 2096, 70052, 2097, 72760, 2196, 2025, 0.376, 0.489)
-- Flowing Forest Flight
DRL:RegisterRace(67095, 2080, 67096, 2081, 72793, 2194, 2025, 0.577, 0.750)
-- Garden Gallivant
DRL:RegisterRace(70157, 2101, 70158, 2102, 72769, 2198, 2025, 0.395, 0.761)
-- Tyrhold Trial
DRL:RegisterRace(69957, 2092, 69958, 2093, 72792, 2195, 2025, 0.572, 0.668)


