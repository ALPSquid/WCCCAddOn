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
                topClubbers = 
                {
                    type = "group",
                    name = " ",
                    inline = true,
                    order = 0.9,
                    args = 
                    {
                        topClubbersHeader =
                        {
                            type = "header",
                            name = "Last Season's Top Clubbers",
                            order = 0.91
                        },

                        noTopClubbers =
                        {
                            type = "description",
                            fontSize = "medium",
                            name = "After the Clubbing Ceremony at the end of a season, the top 3 clubbers will be listed here for all to celebrate!",
                            hidden = function() 
                                return ClubbingComp.UI:GetTopClubberString(1) ~= nil
                            end,
                            order = 0.92
                        },

                        firstClubberEntry =
                        {
                            type = "description",
                            fontSize = "medium",
                            name = function() 
                                return "|cffFFB80F" ..(ClubbingComp.UI:GetTopClubberString(1) or "") .. "|r"
                            end,
                            hidden = function() 
                                return ClubbingComp.UI:GetTopClubberString(1) == nil
                            end,
                            order = 0.92
                        },

                        secondClubberEntry =
                        {
                            type = "description",
                            fontSize = "medium",
                            name = function() 
                                return "|cffA5CAEA" .. (ClubbingComp.UI:GetTopClubberString(2) or "") .. "|r"
                            end,
                            hidden = function() 
                                return ClubbingComp.UI:GetTopClubberString(2) == nil
                            end,
                            order = 0.93
                        },

                        thirdClubberEntry =
                        {
                            type = "description",
                            fontSize = "medium",
                            name = function() 
                                return "|cffA46D27" .. (ClubbingComp.UI:GetTopClubberString(3) or "") .. "|r"
                            end,
                            hidden = function() 
                                return ClubbingComp.UI:GetTopClubberString(3) == nil
                            end,
                            order = 0.94
                        },
                    }
                },

                scoreInfo = 
                {
                    type = "group",
                    name = "Current Score",
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
                            hidden = function() return ClubbingComp.moduleDB.seasonData.currentSeasonRace ~= "Human" end,
                            order = 1.03
                        },
                        hitCountDraenei =
                        {
                            type = "description",
                            fontSize = "medium",
                            name = function() return ClubbingComp.UI:GetRaceClubbedCountDisplayString("Draenei") end,
                            hidden = function() return ClubbingComp.moduleDB.seasonData.currentSeasonRace ~= "Draenei" end,
                            order = 1.04
                        },
                        hitCountDwarf =
                        {
                            type = "description",
                            fontSize = "medium",
                            name = function() return ClubbingComp.UI:GetRaceClubbedCountDisplayString("Dwarf") end,
                            hidden = function() return ClubbingComp.moduleDB.seasonData.currentSeasonRace ~= "Dwarf" end,
                            order = 1.05
                        },
                        hitCountElves =
                        {
                            type = "description",
                            fontSize = "medium",
                            name = function() return ClubbingComp.UI:GetRaceClubbedCountDisplayString("NightElf") end,
                            hidden = function() return ClubbingComp.moduleDB.seasonData.currentSeasonRace ~= "NightElf" end,
                            order = 1.06
                        },
                        hitCountGnome =
                        {
                            type = "description",
                            fontSize = "medium",
                            name = function() return ClubbingComp.UI:GetRaceClubbedCountDisplayString("Gnome") end,
                            hidden = function() return ClubbingComp.moduleDB.seasonData.currentSeasonRace ~= "Gnome" end,
                            order = 1.07
                        },
                        hitCountPandaren =
                        {
                            type = "description",
                            fontSize = "medium",
                            name = function() return ClubbingComp.UI:GetRaceClubbedCountDisplayString("Pandaren") end,
                            hidden = function() return ClubbingComp.moduleDB.seasonData.currentSeasonRace ~= "Pandaren" end,
                            order = 1.08
                        },    
                        
                        hitCountDescription =
                        {
                            type = "description",
                            fontSize = "small",
                            name = "Hit counts show the current season races and don't show frenzy multipliers or non-season frenzy races (these still count to your total score).",
                            order = 1.09
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
                                    name = function() 
                                        if IsInRaid() then
                                            return "Raid"
                                        else
                                            return "Party"
                                        end
                                    end,
                                    desc = "Post your score to party/raid chat.",
                                    func = function() 
                                        local channel = ns.consts.CHAT_CHANNEL.PARTY
                                        if IsInRaid() then
                                            channel = ns.consts.CHAT_CHANNEL.RAID
                                        end
                                        ClubbingComp.UI:PostScoreTo(channel)
                                    end,
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
                                return seasonRace .. " Season" -- (1.5x)
                            end,
                            order = 1.11          
                        },

                        seasonOCLastUpdateDate =
                        {
                            type = "description",     
                            order = 1.12,
                            fontSize = "medium",
                            name = function() 
                                return format("|cFFE97300Season started on %s (%i days ago).|r", ns.utils.LongData(ClubbingComp.moduleDB.seasonData.lastUpdateTimestamp), ns.utils.DaysSince(ClubbingComp.moduleDB.seasonData.lastUpdateTimestamp))
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
                            name = "Seasons reset monthly after each Clubbing Ceremony when prizes are awarded for the top clubbers.\nClubbing the season race will also award points.",
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
                                    name = function() 
                                        if IsInRaid() then
                                            return "Raid"
                                        else
                                            return "Party"
                                        end
                                    end,
                                    desc = "Post the current season to party/raid chat.",
                                    func = function() 
                                        local channel = ns.consts.CHAT_CHANNEL.PARTY
                                        if IsInRaid() then
                                            channel = ns.consts.CHAT_CHANNEL.RAID
                                        end
                                        ClubbingComp.UI:PostSeasonTo(channel) 
                                    end,
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

                                local timeRemaining = math.floor(ClubbingComp:GetFrenzyTimeRemaining() / 60)
                                if timeRemaining < 1 then
                                    timeRemaining = 1
                                end
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
|cFFE97300Using your club:|r\
You can use the club button on the Clubbing HUD and/or use the commands or macro below.\
'/wccc club' - Use your club on the target.\
'/wccc club info' - Open the Clubbing Competition Window.\
Below is a handy macro script to paste into a new macro which makes using your club much easier!\
\
|cFFE97300Seasons:|r\
Each month, a new season will start focussing on a different race, allowing you to club Worgen and the season race.\
At the end of each season, we'll hold a Clubbing Ceremony to share scores and award prize to the top 3 clubbers! These clubbers will be shown in the Clubbing Competition window for all to see.\
\
|cFFE97300Happy Clubbing!|r",
                    order = 1.01
                },

                wcccMacroDesc = 
                {
                    type = "description",
                    fontSize = "medium",
                    name = "\n|cFFE97300Macro:|r\nA useful macro for using the addon and the commands you can use. Simply copy and paste into a new macro or press the 'Create Macro' button below: \n Left click: Use club.\n Ctrl+click: Open Clubbing Competition window.\n Alt+click: Open WCCC Clubbing Companion window.",
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

                createMacroBtn =
                {
                    type = "execute",
                    name = "Create Macro",
                    desc = "Creates the Worgen Club macro above.",
                    func = function() 
                        CreateMacro("Worgen Club", 631502, "/run if IsControlKeyDown() then hash_SlashCmdList[\"/WCCC\"](\"club info\") elseif IsAltKeyDown() then hash_SlashCmdList[\"/WCCC\"](\"\") else hash_SlashCmdList[\"/WCCC\"](\"club\") end") 
                        ShowUIPanel(MacroFrame)
                        WCCCAD.UI:PrintAddOnMessage("Clubbing Competition macro created.")
                    end,
                    order = 1.04,
                },

                copenMacrosBtn =
                {
                    type = "execute",
                    name = "View Macros",
                    desc = "Open the macros UI (note, this might not always work. Type '/m' to open macros manually).",
                    func = function() ShowUIPanel(MacroFrame) end,
                    order = 1.04,
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

                HUDSettingsPanel = 
                {
                    type = "group",
                    name = "Score HUD",
                    inline = true,
                    order = 9.2,
                    args =
                    {
                        toggleHUDClubBtn =
                        {
                            type = "toggle",
                            name = "Show Club Button",
                            desc = "Whether to the club button on the Clubbing Competition score HUD.",
                            width = "full",
                            set = function(info, val) ClubbingComp.UI.hudFrame:SetClubBtnShown(val) end,
                            get = function() return ClubbingComp.moduleDB.hudData.showClubBtn end,
                            order = 9.21
                        },

                        toggleHUDBtn =
                        {
                            type = "execute",
                            name = function() if ClubbingComp.moduleDB.hudData.showHUD then return "Hide HUD" else return "Show HUD" end end,
                            desc = "Toggle the Clubbing Competition score HUD.",
                            func = function() ClubbingComp.UI:SetHUDShown(not ClubbingComp.moduleDB.hudData.showHUD) end,
                            order = 9.22,
                        },
                    },
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
                                    if raceOptions[v.type] == nil  and v.type ~= "Worgen" then
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
                        
                        seasonOCTopClubbersDesc =
                        {
                            type = "description",     
                            order = 10.14,
                            fontSize = "medium",
                            name = "\nTop Clubbers"      
                        },

                        --#region 1st Clubber
                        seasonOCTopClubbersEntry1_Title =
                        {
                            type = "description",     
                            order = 10.15,
                            fontSize = "medium",
                            name = "|cffFFB80F1.|r"      
                        },
                        
                        seasonOCTopClubbersEntry1_Name = 
                        {
                            type = "input",
                            name = "Name",
                            get = function() 
                                return ClubbingComp.UI:GetWorkingTopClubberData(1).name
                            end,
                            set = function(info, val)
                                ClubbingComp.UI:OC_SetTopClubberName(1, val)
                            end,
                            order = 10.151
                        },

                        seasonOCTopClubbersEntry1_Score = 
                        {
                            type = "input",
                            name = "Score",
                            validate = function(info, val) 
                                if not tonumber(val) then
                                    return "Score must be a number."
                                end

                                return true
                            end,
                            get = function() 
                                return ClubbingComp.UI:GetWorkingTopClubberData(1).score
                            end,
                            set = function(info, val)
                                ClubbingComp.UI:OC_SetTopClubberScore(1, val)
                            end,
                            order = 10.151
                        },
                        --#endregion

                        --#region 2nd Clubber
                        seasonOCTopClubbersEntry2_Title =
                        {
                            type = "description",     
                            order = 10.16,
                            fontSize = "medium",
                            name = "|cffA5CAEA2.|r"      
                        },

                        seasonOCTopClubbersEntry2_Name = 
                        {
                            type = "input",
                            name = "Name",
                            get = function() 
                                return ClubbingComp.UI:GetWorkingTopClubberData(2).name
                            end,
                            set = function(info, val)
                                ClubbingComp.UI:OC_SetTopClubberName(2, val)
                            end,
                            order = 10.161
                        },

                        seasonOCTopClubbersEntry2_Score = 
                        {
                            type = "input",
                            name = "Score",
                            validate = function(info, val) 
                                if not tonumber(val) then
                                    return "Score must be a number."
                                end

                                return true
                            end,
                            get = function() 
                                return ClubbingComp.UI:GetWorkingTopClubberData(2).score
                            end,
                            set = function(info, val)
                                ClubbingComp.UI:OC_SetTopClubberScore(2, val)
                            end,
                            order = 10.161
                        },
                        --#endregion

                        --#region 3rd Clubber
                        seasonOCTopClubbersEntry3_Title =
                        {
                            type = "description",     
                            order = 10.17,
                            fontSize = "medium",
                            name = "|cffA46D273.|r"      
                        },

                        seasonOCTopClubbersEntry3_Name = 
                        {
                            type = "input",
                            name = "Name",
                            get = function() 
                                return ClubbingComp.UI:GetWorkingTopClubberData(3).name
                            end,
                            set = function(info, val)
                                ClubbingComp.UI:OC_SetTopClubberName(3, val)
                            end,
                            order = 10.171
                        },

                        seasonOCTopClubbersEntry3_Score = 
                        {
                            type = "input",
                            name = "Score",
                            validate = function(info, val) 
                                if not tonumber(val) then
                                    return "Score must be a number."
                                end

                                return true
                            end,
                            get = function() 
                                return ClubbingComp.UI:GetWorkingTopClubberData(3).score
                            end,
                            set = function(info, val)
                                ClubbingComp.UI:OC_SetTopClubberScore(3, val)
                            end,
                            order = 10.171
                        },
                        --#endregion

                        seasonOCSetTopClubbersBtn =
                        {
                            type = "execute",     
                            order = 10.18,                       
                            name = "Set Top Clubbers",
                            desc = "Update the Top Clubbers to the data entered above. Not all 3 need to be set.",                            
                            func = function() ClubbingComp.UI:OC_SaveTopClubbers() end,        
                            confirm = function() return "Update Top Clubbers?" end,
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
WCCCAD.UI:AddGuildControlButton("Clubbing Competition", "View your score, current season, toggle the HUD and more", ClubbingComp_UI.Show) 


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

ClubbingComp_UI.OC_TopClubbers =
{
    -- [idx] { name, score }
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
    local raceScore = ClubbingComp:GetRaceScore(race)

    return format("%s Clubbed: %i = %ipts (%i each)", raceScoreData.pluralName, hitCount, hitCount * raceScore, raceScore)
end

--#region Top Clubbers UI Controls

---
--- Returns active top clubber data formatted as a string for the idx, or nil if no data exists.
--- Only uses live data.
---
function ClubbingComp_UI:GetTopClubberString(clubberIdx)
    if #ClubbingComp.moduleDB.topClubbers.clubbers < clubberIdx or ClubbingComp.moduleDB.topClubbers.clubbers[clubberIdx].name == nil then
        return nil
    end

    local clubber = ClubbingComp.moduleDB.topClubbers.clubbers[clubberIdx]

    return clubberIdx .. ". " .. clubber.name .. " - " .. clubber.score .. " pts"
end

---
--- Returns edit mode data if there is any or live data is there is any. Otherwise returns blank clubber data.
---
function ClubbingComp_UI:GetWorkingTopClubberData(clubberIdx) 
    local editModeData = ClubbingComp.UI.OC_TopClubbers[clubberIdx]
    if editModeData ~= nil then
        return editModeData
    end

    local liveData = ClubbingComp.moduleDB.topClubbers.clubbers[clubberIdx]
    if liveData ~= nil and liveData.name ~= nil then
        ClubbingComp.UI.OC_TopClubbers[clubberIdx] = liveData
        return liveData
    end

    return { name=nil, score=0}
end

---
--- Edit Mode data: Sets name of the top clubber at clubberIdx 
---
function ClubbingComp_UI:OC_SetTopClubberName(clubberIdx, name) 
    if ClubbingComp.UI.OC_TopClubbers[clubberIdx] == nil then
        ClubbingComp.UI.OC_TopClubbers[clubberIdx] = {name=nil, score=0}
    end
    
    if name == "" then
        name = nil
    end

    ClubbingComp.UI.OC_TopClubbers[clubberIdx].name = name
end

---
--- Edit Mode data: Sets score of the top clubber at clubberIdx 
---
function ClubbingComp_UI:OC_SetTopClubberScore(clubberIdx, score) 
    if ClubbingComp.UI.OC_TopClubbers[clubberIdx] == nil then
        ClubbingComp.UI.OC_TopClubbers[clubberIdx] = {name=nil, score=0}
    end

    ClubbingComp.UI.OC_TopClubbers[clubberIdx].score = score
end


---
--- Applies edit mode data to live.
---
function ClubbingComp_UI:OC_SaveTopClubbers()
    ClubbingComp:OC_SetTopClubbers(ClubbingComp_UI.OC_TopClubbers)
end

--#endregion


function ClubbingComp_UI:CreateHUD() 
    local hudFrame = ns.utils.CreateHUDPanel(
        "Clubbing Competition",

        function() 
            return ClubbingComp.moduleDB.hudData.framePoint, ClubbingComp.moduleDB.hudData.offsetX, ClubbingComp.moduleDB.hudData.offsetY 
        end,

        function(point, offsetX, offsetY)
            ClubbingComp.moduleDB.hudData.framePoint = point
            ClubbingComp.moduleDB.hudData.offsetX = offsetX
            ClubbingComp.moduleDB.hudData.offsetY = offsetY
         end,

        function() 
            ClubbingComp.UI:Show()
        end,

        function()
            ClubbingComp.UI:SetHUDShown(false)
        end
    )
    ClubbingComp_UI.hudFrame = hudFrame   

    hudFrame:SetSize(220, 90)

    hudFrame.SetClubBtnShown = function(self, btnShown)
        local frameHeight = hudFrame:GetHeight()
        if btnShown and hudFrame.clubBtn:IsShown() == false then
            hudFrame.clubBtn:Show()
            frameHeight = frameHeight + hudFrame.clubBtn:GetHeight()
        elseif btnShown == false and hudFrame.clubBtn:IsShown() then
            hudFrame.clubBtn:Hide()
            frameHeight = frameHeight - hudFrame.clubBtn:GetHeight()
        end

        hudFrame:SetHeight(frameHeight)
        ClubbingComp.moduleDB.hudData.showClubBtn = btnShown
    end

    hudFrame.scoreDisplay = hudFrame:CreateFontString()
    hudFrame.scoreDisplay:SetFontObject(GameFontNormal)
    hudFrame.scoreDisplay:SetTextColor(1, 1, 1, 1)
    hudFrame.scoreDisplay:SetPoint("TOPLEFT", 10, -20)

    hudFrame.frenzyDisplay = hudFrame:CreateFontString()
    hudFrame.frenzyDisplay:SetFontObject(GameFontNormal)
    hudFrame.frenzyDisplay:SetTextColor(1, 1, 1, 1)
    hudFrame.frenzyDisplay:SetPoint("TOPLEFT", 10, -35)

    hudFrame.clubBtn = CreateFrame("Button", nil, hudFrame)
	hudFrame.clubBtn:SetNormalTexture(631502)
	hudFrame.clubBtn:SetPushedTexture(1500803)
	hudFrame.clubBtn:SetPoint("BOTTOMLEFT", 5, 5)
	hudFrame.clubBtn:SetWidth(35)
	hudFrame.clubBtn:SetHeight(35)
    hudFrame.clubBtn:SetScript("OnClick", function()
        ClubbingComp:ClubCommand()
    end)  
    
    ClubbingComp_UI:UpdateHUD()
end

function ClubbingComp_UI:UpdateHUD() 
    if ClubbingComp_UI.hudFrame == nil then
        return
    end

    ClubbingComp_UI.hudFrame.scoreDisplay:SetText(format("Score: %s", ClubbingComp.moduleDB.score))

    local frenzyRace = ClubbingComp.moduleDB.frenzyData.race
    local frenzyString = "Frenzy Inactive"
    if frenzyRace ~= nil then
        local timeRemaining = math.floor(ClubbingComp:GetFrenzyTimeRemaining() / 60)
        if timeRemaining < 1 then
            timeRemaining = 1
        end
        local minString = "min"
        if timeRemaining > 1 then minString = "mins" end
        frenzyString = format("%sx %s Frenzy for %s"..minString.."!", 
            ClubbingComp.moduleDB.frenzyData.multiplier,
            ClubbingComp:GetRaceScoreData(ClubbingComp.moduleDB.frenzyData.race).name,
            timeRemaining)
    end

    ClubbingComp_UI.hudFrame.frenzyDisplay:SetText(frenzyString)

    ClubbingComp_UI.hudFrame:SetClubBtnShown(ClubbingComp.moduleDB.hudData.showClubBtn)
end


function ClubbingComp_UI:SetHUDShown(shown) 
    ClubbingComp.moduleDB.hudData.showHUD = shown

    if shown then
        ClubbingComp_UI:ShowHUDIfEnabled()
    elseif ClubbingComp_UI.hudFrame ~= nil then
        ClubbingComp_UI.hudFrame:Hide()
    end
end

function ClubbingComp_UI:ShowHUDIfEnabled() 
    if ClubbingComp.moduleDB.hudData.showHUD == false then
        return
    end

    if ClubbingComp_UI.hudFrame == nil then
        ClubbingComp_UI:CreateHUD()
    end

    ClubbingComp_UI.hudFrame:Show()    
end