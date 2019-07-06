--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local name, ns = ...
local WCCCAD = ns.WCCCAD

local ClubbingComp = WCCCAD:GetModule("WCCC_ClubbingCompetition")

local CLUBBINGCOMP_UI_CONFIG = 
{
    name = "Clubbing Competition",
    handler = ClubbingComp,
    type = "group",
    childGroups = "tab",    
    args = 
    {
        logo = 
        {
            type = "description",
            name = "",
            image ="Interface\\AddOns\\WCCCAddOn\\assets\\wccc-header-clubbingcomp.tga",
            imageWidth=256,
            imageHeight=64,
            order = 0
        },

        homePanel = 
        {
            name = "Home",
            type = "group",
            order = 1,
            args = 
            {               

                scoreInfo = 
                {
                    type = "group",
                    name = "",
                    inline = true,
                    order = 1.0,
                    args =
                    {
                        currentScoreInfo =
                        {
                            type = "header",
                            name = function() 
                                local score = ClubbingComp.moduleDB.score
                                return "Score: "..score
                            end,
                            order = 1.01
                        },     

                        hitCountWorgen =
                        {
                            type = "description",
                            fontSize = "medium",
                            name = function() return ClubbingComp.UI:GetRaceClubbedCountDisplayString("Worgen") end,
                            order = 1.02
                        },
                        hitCountHuman =
                        {
                            type = "description",
                            fontSize = "medium",
                            name = function() return ClubbingComp.UI:GetRaceClubbedCountDisplayString("Human") end,
                            order = 1.03
                        },
                        hitCountDraenei =
                        {
                            type = "description",
                            fontSize = "medium",
                            name = function() return ClubbingComp.UI:GetRaceClubbedCountDisplayString("Draenei") end,
                            order = 1.04
                        },
                        hitCountDwarf =
                        {
                            type = "description",
                            fontSize = "medium",
                            name = function() return ClubbingComp.UI:GetRaceClubbedCountDisplayString("Dwarf") end,
                            order = 1.05
                        },
                        hitCountElves =
                        {
                            type = "description",
                            fontSize = "medium",
                            name = function() return ClubbingComp.UI:GetRaceClubbedCountDisplayString("NightElf") end,
                            order = 1.06
                        },
                        hitCountGnome =
                        {
                            type = "description",
                            fontSize = "medium",
                            name = function() return ClubbingComp.UI:GetRaceClubbedCountDisplayString("Gnome") end,
                            order = 1.07
                        },
                        hitCountPandaren =
                        {
                            type = "description",
                            fontSize = "medium",
                            name = function() return ClubbingComp.UI:GetRaceClubbedCountDisplayString("Pandaren") end,
                            order = 1.08
                        },     
                        
                        reportSeasonButtons = 
                        {
                            type = "group",
                            name = "Post score to...",
                            inline = true,
                            order = 1.09,
                            args =
                            {
                                reportScoreGuildBtn =
                                {
                                    type = "execute",
                                    name = "Guild",
                                    desc = "Post your score to guild chat.",
                                    func = function() ClubbingComp.UI:PostScoreTo(ns.consts.CHAT_CHANNEL.GUILD) end,
                                    order = 1.091,
                                },
                                reportScorePartyBtn =
                                {
                                    type = "execute",
                                    name = "Party",
                                    desc = "Post your score to party chat.",
                                    func = function() ClubbingComp.UI:PostScoreTo(ns.consts.CHAT_CHANNEL.PARTY) end,
                                    order = 1.092,
                                },
                                reportScoreSayBtn =
                                {
                                    type = "execute",
                                    name = "Say",
                                    desc = "Post your score to say.",
                                    func = function() ClubbingComp.UI:PostScoreTo(ns.consts.CHAT_CHANNEL.SAY) end,
                                    order = 1.093,
                                },
                            },
                        },
                    }
                },

                seasonInfo = 
                {
                    type = "group",
                    name = "Season",
                    inline = true,
                    order = 1.1,
                    args =
                    {
                        seasonCurrentRace =
                        {
                            type = "header",
                            name = function() 
                                local seasonRace = ClubbingComp.moduleDB.seasonData.currentSeasonRace
                                if seasonRace == nil then
                                    return "Sync Required"
                                end
                                return seasonRace .. " Season (1.5x)"
                            end,
                            order = 1.11          
                        },

                        seasonOCLastUpdateDate =
                        {
                            type = "description",     
                            order = 1.12,
                            fontSize = "medium",
                            name = function() 
                                return format("Season started on %s (%i days ago).", ns.utils.LongData(ClubbingComp.moduleDB.seasonData.lastUpdateTimestamp), ns.utils.DaysSince(ClubbingComp.moduleDB.seasonData.lastUpdateTimestamp))
                            end,        
                            hidden = function() return ClubbingComp.moduleDB.seasonData.currentSeasonRace == nil end,
                        },

                        seasonSyncInstructions = 
                        {
                            type = "description",
                            fontSize = "medium",
                            name = "Syncing will happen automatically when a guildy with updated season data comes online. You can still club in the meantime and your progress will be saved!",
                            descStyle = "inline",
                            hidden = function() return ClubbingComp.moduleDB.seasonData.currentSeasonRace ~= nil end,
                            order = 1.13
                        },
                        seasonDesc = 
                        {
                            type = "description",
                            fontSize = "medium",
                            name = "Seasons reset monthly after each Clubbing Ceremony when prizes are awarded for the top clubbers.\nPoints for clubbing a player of the current season's race will be multiplied by the above multiplier.",
                            descStyle = "inline",
                            hidden = function() return ClubbingComp.moduleDB.seasonData.currentSeasonRace == nil end,
                            order = 1.14
                        },

                        reportSeasonButtons = 
                        {
                            type = "group",
                            name = "Post season info to...",
                            inline = true,
                            hidden = true,
                            order = 1.15,
                            args =
                            {
                                reportSeasonGuildBtn =
                                {
                                    type = "execute",
                                    name = "Guild",
                                    desc = "Post the current season to guild chat.",
                                    func = function() ClubbingComp.UI:PostSeasonTo(ns.consts.CHAT_CHANNEL.GUILD) end,
                                    order = 1.151,
                                    hidden = function() return ClubbingComp.moduleDB.seasonData.currentSeasonRace == nil end,
                                },
                                reportSeasonPartyBtn =
                                {
                                    type = "execute",
                                    name = "Party",
                                    desc = "Post the current season to party chat.",
                                    func = function() ClubbingComp.UI:PostSeasonTo(ns.consts.CHAT_CHANNEL.PARTY) end,
                                    order = 1.152,
                                    hidden = function() return ClubbingComp.moduleDB.seasonData.currentSeasonRace == nil end,
                                },
                                reportSeasonSayBtn =
                                {
                                    type = "execute",
                                    name = "Say",
                                    desc = "Post the current season to say.",
                                    func = function() ClubbingComp.UI:PostSeasonTo(ns.consts.CHAT_CHANNEL.SAY) end,
                                    order = 1.153,
                                    hidden = function() return ClubbingComp.moduleDB.seasonData.currentSeasonRace == nil end,
                                },
                            },
                        },    
                    },
                },         
                
                frenzyInfo = 
                {
                    type = "group",
                    name = "Frenzy",
                    inline = true,
                    order = 1.2,
                    args =
                    {
                        frenzyRace =
                        {
                            type = "header",
                            name = function() 
                                local frenzyRace = ClubbingComp.moduleDB.frenzyData.race
                                if frenzyRace == nil then
                                    return "No Frenzy Active"
                                end

                                local timeRemaining = math.floor(ClubbingComp:GetFrenzyTimeRemaining() / 60) + 1
                                local minString = "min"
                                if timeRemaining > 1 then minString = "mins" end
                                return format("%sx %s Frenzy for %s"..minString.."!", 
                                    ClubbingComp.moduleDB.frenzyData.multiplier,
                                    ClubbingComp:GetRaceScoreData(ClubbingComp.moduleDB.frenzyData.race).name,
                                    timeRemaining)
                            end,
                            order = 1.21         
                        },

                        frenzyDesc = 
                        {
                            type = "description",
                            fontSize = "medium",
                            name = "Clubbing Frenzies are short periods where clubbing a particular race awards a large point multiplier. Frenzies are started by officers for social events, look out for the next one on the calendar!",
                            descStyle = "inline",
                            order = 1.22
                        },                           
                    },
                },  
            },
        },

        helpPanel = 
        {
            type = "group",
            name = "How to Use",
            order = 8,
            args =
            {
                helpText = 
                {
                    type = "description",
                    fontSize = "medium",
                    name = "Welcome to the Clubbing Competition, a spectacle of excitement and social clubbing!\
\
Using your club (commands):\
'/wccc club' - Use your club on the target.\
'/wccc club info' - Open the Clubbing Compeition Window.\
Below is a handy macro script to paste into a new macro which makes using your club much easier!\
\
Seasons:\
Each month, a new season will start focussing on a different race. Clubbing that race awards 1.5x the normal points.\
At the end of each season, we'll hold a Clubbing Ceremony to share scores and award prize to the top 3 clubbers! These clubbers will be shown in the Clubbing Competition window for all to see.\
\
Happy Clubbing!",
                    order = 1.01
                },

                wcccMacroDesc = 
                {
                    type = "description",
                    fontSize = "medium",
                    name = "\nMacro:\nA useful macro for using the addon and the commands you can use. Simply copy and paste into a new macro: \n Left click: Use club.\n Ctrl+click: Open Clubbing Competition window.\n Alt+click: Open WCCC AddOn window.",
                    order = 1.02
                },

                wcccMacro = 
                {
                    type = "input",
                    name = "",
                    width = "full",
                    multiline = 2,
                    get = function() return "/run if IsControlKeyDown() then hash_SlashCmdList[\"/WCCC\"](\"club info\") elseif IsAltKeyDown() then hash_SlashCmdList[\"/WCCC\"](\"\") else hash_SlashCmdList[\"/WCCC\"](\"club\") end" 
                    end,
                    order = 1.03
                },
            }
        },

        settingsPanel = 
        {
            type = "group",
            name = "Settings",
            order = 9,
            args =
            {
                toggleGuildMemberNotifications = 
                {
                    type = "toggle",
                    name = "Guildy Clubbed a Worgen Notification",
                    desc = "Whether to show a chat message when a guild member clubs a Worgen.",
                    width = "full",
                    set = function(info, val) ClubbingComp.moduleDB.showGuildMemberClubNotification = val end,
                    get = function() return ClubbingComp.moduleDB.showGuildMemberClubNotification end,
                    order = 9.1
                },

                toggleSayEmotes = 
                {
                    type = "toggle",
                    name = "Clubbing /say Emotes",
                    desc = "Whether to enable /say emotes when successfully clubbing something.",
                    width = "full",
                    set = function(info, val) ClubbingComp.moduleDB.sayEmotesEnabled = val end,
                    get = function() return ClubbingComp.moduleDB.sayEmotesEnabled end,
                    order = 9.1
                },
            }
        },
        
        officerControlsPanel = 
        {
            type = "group",
            name = "Officer Controls",
            order = 10,
            disabled = function() return WCCCAD:IsPlayerOfficer() == false end,
            hidden = function() return WCCCAD:IsPlayerOfficer() == false end,
            args =
            {
                toggleDebugMode = 
                {
                    type = "toggle",
                    name = "Debug Mode",
                    desc = "Enables verbose printing of events and AddOn functions.",
                    set = function(info, val) ClubbingComp.moduleDB.debugMode = val  end,
                    get = function() return ClubbingComp.moduleDB.debugMode end,
                    order = 10.0
                },

                seasonOfficerControls = 
                {
                    type = "group",
                    name = "Season Controls",
                    order = 10.1,
                    args =
                    {
                        seasonOCLastUpdateDate =
                        {
                            type = "description",     
                            order = 10.11,
                            fontSize = "medium",
                            name = function() 
                                return format("Last season update on %s %s (%i days ago).", ns.utils.LongData(ClubbingComp.moduleDB.seasonData.lastUpdateTimestamp), date("%H:%M", ClubbingComp.moduleDB.seasonData.lastUpdateTimestamp), ns.utils.DaysSince(ClubbingComp.moduleDB.seasonData.lastUpdateTimestamp))
                            end,        
                        },

                        seasonOCNewSeasonSelect =
                        {
                            type = "select",
                            name = "New Season",
                            order = 10.12,
                            values = function()
                                local raceOptions = {}
                                for k,v in pairs(ClubbingComp:GetRaceScoreDataTable()) do
                                    if raceOptions[v.type] == nil then
                                        raceOptions[v.type] = v.name
                                    end
                                end
                                return raceOptions
                            end,
                            get = function()
                                return ClubbingComp.UI.OC_SelectedSeason
                            end,
                            set = function(options, key)
                                ClubbingComp.UI.OC_SelectedSeason = key
                            end                         
                        },

                        seasonOCSetSeasonBtn =
                        {
                            type = "execute",     
                            order = 10.13,                       
                            name = "Start New Season",
                            desc = "Reset the season and change to the selected race.",                            
                            func = function() ClubbingComp:OC_SetSeason(ClubbingComp.UI.OC_SelectedSeason) end,        
                            confirm = function() return format( "Start new %s season? This will wipe all player's progress!", ClubbingComp.UI.OC_SelectedSeason) end,
                        },                        
                    }
                },

                frenzyOfficerControls = 
                {
                    type = "group",
                    name = "Frenzy Controls",
                    order = 10.2,
                    args =
                    {
                        frenzyOCStartTime =
                        {
                            type = "description",
                            fontSize = "medium",
                            order = 10.2,
                            hidden = function() return ClubbingComp.moduleDB.frenzyData.startTimestamp <= 0 end,
                            name = function() 
                                return format("Frenzy started on %s %s.", ns.utils.LongData(ClubbingComp.moduleDB.frenzyData.startTimestamp), date("%H:%M", ClubbingComp.moduleDB.frenzyData.startTimestamp))
                            end,        
                        },

                        frenzyOCRaceSelect =
                        {
                            type = "select",
                            name = "Frenzy Race",
                            order = 10.21,
                            values = function()
                                local raceOptions = {}
                                for k,v in pairs(ClubbingComp:GetRaceScoreDataTable()) do
                                    if raceOptions[v.type] == nil then
                                        raceOptions[v.type] = v.name
                                    end
                                end
                                return raceOptions
                            end,
                            get = function()
                                return ClubbingComp.UI.OC_FrenzySelectedRace
                            end,
                            set = function(options, key)
                                ClubbingComp.UI.OC_FrenzySelectedRace = key
                            end                         
                        },

                        frenzyOCMultiplierSelect =
                        {
                            type = "select",
                            name = "Frenzy Multiplier",
                            order = 10.22,
                            values = function()
                                return ClubbingComp.UI.OC_FrenzyMultiplierOptions
                            end,
                            get = function()
                                return ClubbingComp.UI.OC_FrenzySelectedMultiplier
                            end,
                            set = function(options, key)
                                ClubbingComp.UI.OC_FrenzySelectedMultiplier = key
                            end                         
                        },

                        frenzyOCDurationSelect =
                        {
                            type = "select",
                            name = "Frenzy Duration (mins)",
                            order = 10.23,
                            values = function()
                                return ClubbingComp.UI.OC_FrenzyDurationOptions
                            end,
                            get = function()
                                return ClubbingComp.UI.OC_FrenzySelectedDuration
                            end,
                            set = function(options, key)
                                ClubbingComp.UI.OC_FrenzySelectedDuration = key
                            end                         
                        },

                        frenzyOCStartFrenzyBtn =
                        {
                            type = "execute",     
                            order = 10.24,
                            name = "Start Frenzy",
                            desc = "Start a new frenzy for the selected race, multiplier and duration.",                            
                            func = function() ClubbingComp:OC_StartFrenzy(
                                ClubbingComp.UI.OC_FrenzySelectedRace, 
                                ClubbingComp.UI.OC_FrenzyMultiplierOptions[ClubbingComp.UI.OC_FrenzySelectedMultiplier], 
                                ClubbingComp.UI.OC_FrenzyDurationOptions[ClubbingComp.UI.OC_FrenzySelectedDuration] * 60) 
                            end,        
                            confirm = function() return format( "Start new %s frenzy?", ClubbingComp.UI.OC_FrenzySelectedRace) end,
                        },
                    }
                },
            }
        },
    }
}

local ClubbingComp_UI = WCCCAD.UI:LoadModuleUI(ClubbingComp, "Clubbing Competition", CLUBBINGCOMP_UI_CONFIG)

-- Officer control vars
ClubbingComp_UI.OC_SelectedSeason = "Worgen"
ClubbingComp_UI.OC_FrenzySelectedRace = "Worgen"
ClubbingComp_UI.OC_FrenzySelectedMultiplier = 1
ClubbingComp_UI.OC_FrenzySelectedDuration = 2

ClubbingComp_UI.OC_FrenzyMultiplierOptions = 
{
    [1] = 2,
    [2] = 3,
    [4] = 5,    
}

ClubbingComp_UI.OC_FrenzyDurationOptions = 
{
    [1] = 5,
    [2] = 10,
    [3] = 15,
    [5] = 30,
    [6] = 1
}
--

function ClubbingComp_UI:PostSeasonTo(channel)
    local seasonRace = ClubbingComp.moduleDB.seasonData.currentSeasonRace
    local raceData = ClubbingComp:GetRaceScoreData(seasonRace)

    local seasonMessages =
    {
        [1] = "It's %s Clubbing Season, dull your clubs!",
        [2] = "I'm ready for %s Clubbing Season! ",
    }

    SendChatMessage(format(seasonMessages[math.random(1, #seasonMessages)], raceData.name), channel)
end

function ClubbingComp_UI:PostScoreTo(channel)
    local score = ClubbingComp.moduleDB.score

    local scoreMessages =
    {
        [1] = "I've clubbed %i points worth of Alliance scum! I am the mightiest clubber of them all!",
        [2] = "I've scored %i points this clubbing season!",
    }

    SendChatMessage(format(scoreMessages[math.random(1, #scoreMessages)], score), channel)
end

function ClubbingComp_UI:GetRaceClubbedCountDisplayString(race)
    local raceScoreData = ClubbingComp:GetRaceScoreData(race)
    local hitCount = ClubbingComp:GetRaceHitCount(raceScoreData.type)

    return format("%s Clubbed: %i = %ipts (%i each)", raceScoreData.pluralName, hitCount, hitCount * raceScoreData.score, raceScoreData.score)
end