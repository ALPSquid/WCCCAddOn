--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local name, ns = ...
local WCCCAD = ns.WCCCAD

local HIT_COOLDOWN = 15 * 60; -- 15 mins between hitting the same target.
--local SEASON_MULTIPLIER = 1.5;
local SEASON_MULTIPLIER = 1;

local RACES = 
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
};
RACES["LightforgedDraenei"] = RACES["Draenei"];
RACES["VoidElf"] = RACES["NightElf"];
RACES["KulTiran"] = RACES["Human"];
RACES["DarkIronDwarf"] = RACES["Dwarf"];
RACES["Mechagnome"] = RACES["Gnome"];

local HIT_SOUNDS =
{
    [1] = 567750, --"Sound\Item\Weapons\Mace1H\1hMaceHitFlesh1a.ogg",
    [2] = 567741, -- "Sound\Item\Weapons\Mace1H\1hMaceHitFlesh1b.ogg",
    [3] = 567738, -- "Sound\Item\Weapons\Mace1H\1hMaceHitFlesh1c.ogg",
    [4] = 567724, -- "Sound\Item\Weapons\Mace1H\1hMaceHitFleshCrit.ogg"
}
local SWING_SOUND = 567935 -- "Sound\Item\Weapons\WeaponSwings\mWooshMedium2.ogg";
local SUCCESS_HIT_SOUND = 567724 -- "Sound\Item\Weapons\Mace1H\1hMaceHitFleshCrit.ogg";

local SUCCESS_HIT_MESSAGES =
{
    [1] = "What a hit! I hope someone saw that!",
    [2] = "And MY club!",
    [3] = "Skadoosh!",
    [4] = "Begone, pest!",
    [5] = "Have at ye!",
    [6] = "That's for the good of the realm!",
    [7] = "Begone, vile beast, before I vanquish thee for good!",
    [8] = "Bonk!"
}

local GUILDY_CLUBBED_MESSAGES = 
{
    [1] = "{playerName} just clubbed {worgenName} the Worgen in {playerLoc}!",
    [2] = "{worgenName} the Worgen has been driven from {playerLoc} by {playerName}!",
    [3] = "Another Worgen clubbed by {playerName}!",
    [4] = "{playerName} just showed {worgenName} the Worgen what it means to be in the <WCCC>!",
}

local COMM_KEY_GUILDY_CLUBBED_WORGEN = "guildyClubbedWorgen"

local clubbingCompData = 
{
    profile =
    {
        showGuildMemberClubNotification = true,
        sayEmotesEnabled = true,
        score = 0,

        hudData = 
        {
            framePoint = "CENTER",
            offsetX = 0,
            offsetY = 0,
            showHUD = true,
            showClubBtn = true,
        },

        seasonData = 
        {
            lastUpdateTimestamp = 0,
            currentSeasonRace = nil
        },

        hitTable =
        {
            -- [raceScoreType] = { [name] = { actualRace, hits = {time} }
        },

        frenzyData =
        {
            startTimestamp = 0,
            race = nil,
            multiplier = 0,
            duration = 0,
        },

        topClubbers = 
        {
            lastUpdateTimestamp = 0,
            clubbers = {} -- [idx] = {name, score}
        }
    }
}

local ClubbingComp = WCCCAD:CreateModule("WCCC_ClubbingCompetition", clubbingCompData)
ClubbingComp.activeFrenzyTimerID = nil

function ClubbingComp:InitializeModule()
    ClubbingComp:RegisterModuleSlashCommand("club", ClubbingComp.ClubCommand)
    WCCCAD.UI:PrintAddOnMessage("Clubbing Competition module loaded.")

    ClubbingComp:RegisterModuleComm(COMM_KEY_GUILDY_CLUBBED_WORGEN, ClubbingComp.OnGuildyClubbedWorgenCommReceieved)
end

function ClubbingComp:OnEnable()
    ClubbingComp:InitiateSync()
    ClubbingComp:UpdateActiveFrenzy()

    ClubbingComp.UI:ShowHUDIfEnabled()
end

function ClubbingComp:GetRaceScoreData(race)
    return RACES[race]
end

function ClubbingComp:GetRaceScoreDataTable()
    return RACES
end

---
--- Returns the score for clubbing the specified race including season multiplier if in season and frenzy multiplier if in frenzy.
---
function ClubbingComp:GetRaceScore(race)
    local raceScoreData = ClubbingComp:GetRaceScoreData(race)
    local score = raceScoreData.score

    if self.moduleDB.seasonData.currentSeasonRace ~= nil and self.moduleDB.seasonData.currentSeasonRace == raceScoreData.type then
        score = score * SEASON_MULTIPLIER
    end

    if self.moduleDB.frenzyData.race ~= nil and self.moduleDB.frenzyData.race == raceScoreData.type then
        score = score * self.moduleDB.frenzyData.multiplier
    end

    return math.floor(score)
end

function ClubbingComp:ClubCommand(args)
    if args ~= nil and args[1] ~= nil then
        if args[1] == "info" then
            self.UI:Show()
        end
        return 
    end

    if not WCCCAD.addonActive then
        WCCCAD.UI:PrintAddonDisabledMessage()
        return
    end

    -- Standard club command
    local targetRace, targetRaceEn = UnitRace("target")
    local targetFaction, targetFactionEn = UnitFactionGroup("target")
    local targetName = UnitName("target")

    local raceScoreData = RACES[targetRaceEn]
 
    if targetName == nil then
        ClubbingComp:PlayEmote(format("swings %s [Worgen Cub Clubbing Club] wildly around in front of %s.", 
            ns.utils.Pronoun(ns.consts.TENSE.POS),  
            ns.utils.Pronoun(ns.consts.TENSE.OBJ)))
        PlaySoundFile(SWING_SOUND, "SFX")

    elseif ClubbingComp:IsTargetInRange() then
        -- If there was a valid target, then it's a success hit!
        if targetFactionEn == "Alliance" and raceScoreData ~= nil and ClubbingComp:IsRaceClubbable(targetRaceEn) then
            ClubbingComp:PlayEmote("very forcefully clubs %t with " .. ns.utils.Pronoun(ns.consts.TENSE.POS) .. " [Worgen Cub Clubbing Club].",
            SUCCESS_HIT_MESSAGES[math.random(1, #SUCCESS_HIT_MESSAGES)])
            PlaySoundFile(SUCCESS_HIT_SOUND, "SFX")

            -- If the target is clubbable.
            if ClubbingComp:HasRecentlyHit(targetName, targetRaceEn) == false then
                -- Update score
                local raceScore = ClubbingComp:GetRaceScore(targetRaceEn)
                self.moduleDB.score = self.moduleDB.score + raceScore
                WCCCAD.UI:PrintAddOnMessage(format("You earned %s points! Current score: %s ", raceScore, self.moduleDB.score))
                
                ClubbingComp:RegisterHit(targetName, targetRaceEn)
                ClubbingComp.UI:UpdateHUD()

                if raceScoreData.type == "Worgen" then
                    ClubbingComp:SendGuildyClubbedWorgenComm(targetName)
                end
            else
                WCCCAD.UI:PrintAddOnMessage("You've already clubbed "..targetName.." recently, so won't earn any points.");
            end

         -- Otherwise, if there wasn't a valid target but the target is in range, then it's a bog standard emote hit.
        else
            if targetName == UnitName("player") then
                ClubbingComp:PlayEmote("flails ".. ns.utils.Pronoun(ns.consts.TENSE.POS)  .." [Worgen Cub Clubbing Club] around and hits ".. ns.utils.Pronoun(ns.consts.TENSE.OBJ) .. "self. It makes the most satisfying 'thwack'.");    
            else
                ClubbingComp:PlayEmote("clubs %t with ".. ns.utils.Pronoun(ns.consts.TENSE.POS) .. " [Worgen Cub Clubbing Club]. It makes the most satisfying 'thwack'.");    
            end
            PlaySoundFile(HIT_SOUNDS[math.random(1, #HIT_SOUNDS)]);
        end
    end   
end

--#region Clubbing Hit Funcs

---
--- Saves a hit on the specified target to the hit table. 
---
function ClubbingComp:RegisterHit(targetName, targetRaceEn)
    local raceScoreType = RACES[targetRaceEn].type

    if self.moduleDB.hitTable[raceScoreType] == nil then
        self.moduleDB.hitTable[raceScoreType] = {}
    end

    targetHitData = self.moduleDB.hitTable[raceScoreType][targetName]
    if targetHitData == nil or targetHitData.race ~= targetRaceEn then
        targetHitData = 
        {
            race = targetRaceEn,
            hits = {}
        }
    end

    table.insert(targetHitData.hits, GetServerTime())

    self.moduleDB.hitTable[raceScoreType][targetName] = targetHitData
end

---
--- Get number of hits for the specified race. This is total scored hits, not unique hits.
---
function ClubbingComp:GetRaceHitCount(raceScoreType)
    local raceHitTable = self.moduleDB.hitTable[raceScoreType]
    if raceHitTable == nil then
        return 0
    end

    local hitCount = 0
    for k, v in pairs(raceHitTable) do
        hitCount = hitCount + #v.hits
    end

    return hitCount
end

-- 
--- Checks to see if the target has been recently hit.
---
function ClubbingComp:HasRecentlyHit(targetName, targetRaceEn)
    if RACES[targetRaceEn] == nil then
        return false
    end
    local raceScoreType = RACES[targetRaceEn].type

    -- If there's no entry, then it's a valid target!
    if self.moduleDB.hitTable[raceScoreType] == nil then
        return false
    end

    local targetHitData = self.moduleDB.hitTable[raceScoreType][targetName]
    if targetHitData == nil or targetHitData.hits == nil or #targetHitData.hits == 0 then
        return false;
    end

    local lastHitTime = targetHitData.hits[#targetHitData.hits]
	-- Check current time and time the target was last hit.
	if GetServerTime() > lastHitTime + HIT_COOLDOWN then
		return false;
	end

    return true;
end

function ClubbingComp:IsRaceClubbable(targetRaceEn)
    local raceData = ClubbingComp:GetRaceScoreData(targetRaceEn)
    if raceData == nil then
        return false
    end

    if raceData.type == "Worgen" 
        or raceData.type == ClubbingComp.moduleDB.seasonData.currentSeasonRace
        or raceData.type == ClubbingComp.moduleDB.frenzyData.race
    then
        return true
    end

    return false
end

function ClubbingComp:IsTargetInRange()
    if CheckInteractDistance("target", 3) then
        return true
    else
        WCCCAD.UI:PrintAddOnMessage("Target not in range.")
    end

    return false
end

--#endregion

function ClubbingComp:PlayEmote(emote, chatMsg) 
    SendChatMessage(emote, ns.consts.CHAT_CHANNEL.EMOTE)

    -- Random chance to /say something.
    if chatMsg ~= nil and ClubbingComp.moduleDB.sayEmotesEnabled == true then
        if random() <= 0.5 then
            SendChatMessage(chatMsg, ns.consts.CHAT_CHANNEL.SAY)
        end
    end
end

---
--- Guildy clubbed notification
---
function ClubbingComp:SendGuildyClubbedWorgenComm(worgenName)
    local playerName = UnitName("player")
    local playerLoc = C_Map.GetMapInfo(C_Map.GetBestMapForUnit("player")).name
    local messageIndex = random(1, #GUILDY_CLUBBED_MESSAGES)
    local data = 
    {
        messageIndex = messageIndex,
        worgenName = worgenName,
        playerName = playerName,
        playerLoc = playerLoc
    }

    ClubbingComp:SendModuleComm(COMM_KEY_GUILDY_CLUBBED_WORGEN, data, ns.consts.CHAT_CHANNEL.GUILD)
end

function ClubbingComp:OnGuildyClubbedWorgenCommReceieved(data)
    if ClubbingComp.moduleDB.showGuildMemberClubNotification == false then
        return
    end    

    local message = GUILDY_CLUBBED_MESSAGES[data.messageIndex]
    message = message:gsub("{playerName}", data.playerName)
    message = message:gsub("{worgenName}", data.worgenName)
    message = message:gsub("{playerLoc}", data.playerLoc)

    WCCCAD.UI:PrintAddOnMessage(message, ns.consts.MSG_TYPE.GUILD)
end


--#region Seasons

function ClubbingComp:OC_SetSeason(raceKey)
    if WCCCAD.addonActive == false or WCCCAD:IsPlayerOfficer() == false then
        return
    end

    ClubbingComp:StartNewSeason(raceKey, GetServerTime())
    ClubbingComp:BroadcastSyncData()
end
---
--- Sends local season data to the target, or whole guild if target is null.
---
function ClubbingComp:StartNewSeason(seasonRace, updateTimestamp)
    -- If current timestamp and race are same as the new, we have the latest data.
    if updateTimestamp < ClubbingComp.moduleDB.seasonData.lastUpdateTimestamp 
        or (updateTimestamp == ClubbingComp.moduleDB.seasonData.lastUpdateTimestamp 
            and seasonRace == ClubbingComp.moduleDB.seasonData.currentSeasonRace)
    then
        WCCCAD.UI:PrintDebugMessage("Already have equal or newer data, skipping season update.", ClubbingComp.moduleDB.debugMode)
        return
    end

    WCCCAD.UI:PrintDebugMessage("Starting new season.", ClubbingComp.moduleDB.debugMode)

    ClubbingComp.moduleDB.seasonData.lastUpdateTimestamp = updateTimestamp
    ClubbingComp.moduleDB.seasonData.currentSeasonRace = seasonRace
    ClubbingComp.moduleDB.score = 0;

    -- Prune last season clubbings and update score.
    for scoreRaceType, players in pairs(self.moduleDB.hitTable) do
        for playerName, playerEntry in pairs(players) do
            if playerEntry.hits ~= nil then
                local newSeasonPlayerHits = {}
                for idx, hitTime in pairs(playerEntry.hits) do
                    if hitTime >= updateTimestamp then
                        table.insert(newSeasonPlayerHits, playerEntry.hits[i])
                    end
                end
                playerEntry.hits = newSeasonPlayerHits

                local playerScore = #playerEntry.hits * ClubbingComp:GetRaceScore(scoreRaceType)
                ClubbingComp.moduleDB.score = ClubbingComp.moduleDB.score + playerScore;
            end
        end
    end
    WCCCAD.UI:PrintDebugMessage("Pruned hit table, new score: "..ClubbingComp.moduleDB.score, ClubbingComp.moduleDB.debugMode)

    ClubbingComp.UI:UpdateHUD()
    WCCCAD.UI:PrintAddOnMessage("A new season has started! Good luck in " .. ClubbingComp:GetRaceScoreData(seasonRace).name .. " Season!")
end

--#endregion

--#region Frenzy

--- @duration  Duration in seconds.
function ClubbingComp:OC_StartFrenzy(raceKey, multiplier, duration)
    if WCCCAD.addonActive == false or WCCCAD:IsPlayerOfficer() == false then
        return
    end

    ClubbingComp:UpdateFrenzyData(raceKey, multiplier, GetServerTime(), duration)
    ClubbingComp:BroadcastSyncData()
end

---
--- Called when new data is received from a client.
---
function ClubbingComp:UpdateFrenzyData(race, multiplier, startTime, duration) 
    if startTime < ClubbingComp.moduleDB.frenzyData.startTimestamp
        or (startTime == ClubbingComp.moduleDB.frenzyData.startTimestamp 
            and race == ClubbingComp.moduleDB.frenzyData.race
            and multiplier == ClubbingComp.moduleDB.frenzyData.multiplier
            and duration == ClubbingComp.moduleDB.frenzyData.duration)
    then
        WCCCAD.UI:PrintDebugMessage("Already have equal or newer data, skipping frenzy update.", ClubbingComp.moduleDB.debugMode)
        return
    end

    if GetServerTime() > startTime + duration then
        WCCCAD.UI:PrintDebugMessage("UpdateFrenzyData: Frenzy has ended, clearing data.", ClubbingComp.moduleDB.debugMode)
        ClubbingComp.moduleDB.frenzyData.startTimestamp = 0
        ClubbingComp.moduleDB.frenzyData.race = nil
        ClubbingComp.moduleDB.frenzyData.multiplier = 0
        ClubbingComp.moduleDB.frenzyData.duration = 0
        ClubbingComp:UpdateActiveFrenzy()
        return
    end

    ClubbingComp.moduleDB.frenzyData.startTimestamp = startTime
    ClubbingComp.moduleDB.frenzyData.race = race
    ClubbingComp.moduleDB.frenzyData.multiplier = multiplier
    ClubbingComp.moduleDB.frenzyData.duration = duration

    WCCCAD.UI:PrintAddOnMessage(format("A %sx %s frenzy has started for %smins, get clubbing!", multiplier, ClubbingComp:GetRaceScoreData(race).name, duration / 60))
    ClubbingComp:UpdateActiveFrenzy()
end

function ClubbingComp:GetFrenzyTimeRemaining() 
    return (ClubbingComp.moduleDB.frenzyData.startTimestamp + ClubbingComp.moduleDB.frenzyData.duration) - GetServerTime()
end

---
--- Called internally to update frenzy timers.
---
function ClubbingComp:UpdateActiveFrenzy()
    local frenzyDurationRemaining = ClubbingComp:GetFrenzyTimeRemaining()
    local frenzyEnded = frenzyDurationRemaining <= 0
    WCCCAD.UI:PrintDebugMessage(format("UpdateActiveFrenzy - Remaining duration %s, ended=%s", frenzyDurationRemaining, tostring(frenzyEnded)), ClubbingComp.moduleDB.debugMode)

    if frenzyEnded == true then
        if ClubbingComp.activeFrenzyTimerID ~= nil then
            WCCCAD:CancelTimer(ClubbingComp.activeFrenzyTimerID)
            ClubbingComp.activeFrenzyTimerID = nil
            WCCCAD.UI:PrintAddOnMessage(format("%s frenzy has ended.", ClubbingComp:GetRaceScoreData(ClubbingComp.moduleDB.frenzyData.race).name))
        end

        WCCCAD.UI:PrintDebugMessage("UpdateActiveFrenzy - Cleared frenzy data.", ClubbingComp.moduleDB.debugMode)

        ClubbingComp.moduleDB.frenzyData.startTimestamp = 0
        ClubbingComp.moduleDB.frenzyData.race = nil
        ClubbingComp.moduleDB.frenzyData.multiplier = 0
        ClubbingComp.moduleDB.frenzyData.duration = 0
    end

    --- Start timer ticker if it's not running.
    if frenzyEnded == false and ClubbingComp.activeFrenzyTimerID == nil then
        local tickIntervalSecs = 5
        ClubbingComp.activeFrenzyTimerID = WCCCAD:ScheduleRepeatingTimer(function() ClubbingComp:UpdateActiveFrenzy() end, tickIntervalSecs)
        WCCCAD.UI:PrintDebugMessage("Started frenzy timer for " .. (frenzyDurationRemaining/60) .. "mins.", ClubbingComp.moduleDB.debugMode)    
    end    
    
    ClubbingComp.UI:UpdateHUD()
end

--#endregion

--#region Top Clubbers

function ClubbingComp:OC_SetTopClubbers(clubberEntries)
    if WCCCAD.addonActive == false or WCCCAD:IsPlayerOfficer() == false then
        return
    end

    ClubbingComp:UpdateTopClubbers(clubberEntries, GetServerTime())
    ClubbingComp:BroadcastSyncData()
end

function ClubbingComp:UpdateTopClubbers(clubberEntries, updateTime)
    if ClubbingComp.moduleDB.topClubbers.lastUpdateTimestamp > updateTime then
        return
    end

    ClubbingComp.moduleDB.topClubbers.lastUpdateTimestamp = updateTime
    ClubbingComp.moduleDB.topClubbers.clubbers = clubberEntries
end

--#endregion

--#region Sync functions

function ClubbingComp:GetSyncData() 
    local syncData =
    {
        seasonData =
        {
            seasonRace = ClubbingComp.moduleDB.seasonData.currentSeasonRace,
            updateTime = ClubbingComp.moduleDB.seasonData.lastUpdateTimestamp
        },

        frenzyData = 
        {
            startTimestamp = ClubbingComp.moduleDB.frenzyData.startTimestamp,
            race = ClubbingComp.moduleDB.frenzyData.race,
            multiplier = ClubbingComp.moduleDB.frenzyData.multiplier,
            duration = ClubbingComp.moduleDB.frenzyData.duration
        },

        topClubbers =
        {
            lastUpdateTimestamp = ClubbingComp.moduleDB.topClubbers.lastUpdateTimestamp,
            clubbers = ClubbingComp.moduleDB.topClubbers.clubbers
        }
    }

    return syncData
end

function ClubbingComp:CompareSyncData(remoteData)
    -- Season
    local seasonComparison = ns.consts.DATA_SYNC_RESULT.LOCAL_NEWER
    if remoteData.seasonData.updateTime > ClubbingComp.moduleDB.seasonData.lastUpdateTimestamp then
        seasonComparison = ns.consts.DATA_SYNC_RESULT.REMOTE_NEWER

    elseif remoteData.seasonData.updateTime == ClubbingComp.moduleDB.seasonData.lastUpdateTimestamp 
        and remoteData.seasonData.seasonRace == ClubbingComp.moduleDB.seasonData.currentSeasonRace 
    then
        seasonComparison = ns.consts.DATA_SYNC_RESULT.EQUAL
    end

    -- Frenzy
    local frenzyComparison = ns.consts.DATA_SYNC_RESULT.LOCAL_NEWER
    if remoteData.frenzyData.startTimestamp > ClubbingComp.moduleDB.frenzyData.startTimestamp then
        frenzyComparison = ns.consts.DATA_SYNC_RESULT.REMOTE_NEWER

    elseif remoteData.frenzyData.startTimestamp == ClubbingComp.moduleDB.frenzyData.startTimestamp
        and remoteData.frenzyData.race == ClubbingComp.moduleDB.frenzyData.race
        and remoteData.frenzyData.multiplier == ClubbingComp.moduleDB.frenzyData.multiplier
        and remoteData.frenzyData.duration == ClubbingComp.moduleDB.frenzyData.duration
    then
        frenzyComparison = ns.consts.DATA_SYNC_RESULT.EQUAL
    end

    -- Top Clubbers
    local topClubbersComparison = ns.consts.DATA_SYNC_RESULT.LOCAL_NEWER
    if remoteData.topClubbers.lastUpdateTimestamp > ClubbingComp.moduleDB.topClubbers.lastUpdateTimestamp then
        topClubbersComparison = ns.consts.DATA_SYNC_RESULT.REMOTE_NEWER

    elseif remoteData.topClubbers.lastUpdateTimestamp == ClubbingComp.moduleDB.topClubbers.lastUpdateTimestamp then
        topClubbersComparison = ns.consts.DATA_SYNC_RESULT.EQUAL
    end

    -- Result
    return ClubbingComp:GetTotalSyncResult(seasonComparison, frenzyComparison, topClubbersComparison)
end

function ClubbingComp:OnSyncDataReceived(data)
    ClubbingComp:StartNewSeason(data.seasonData.seasonRace, data.seasonData.updateTime)
    ClubbingComp:UpdateFrenzyData(data.frenzyData.race, data.frenzyData.multiplier, data.frenzyData.startTimestamp, data.frenzyData.duration)
end

--#endregion