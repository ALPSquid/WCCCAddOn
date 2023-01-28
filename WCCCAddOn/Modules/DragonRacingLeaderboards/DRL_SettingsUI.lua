local _, ns = ...
local WCCCAD = ns.WCCCAD
local DRL = WCCCAD:GetModule("WCCC_DragonRacingLeaderboards")

local DRL_SETTINGS_CONFIG =
{
    name = "Dragon Racing Leaderboards",
    handler = DRL,
    type = "group",
    childGroups = "tab",
    args =
    {
        logo =
        {
            type = "description",
            name = "",
            image ="Interface\\AddOns\\WCCCAddOn\\assets\\wccc-header-drl.tga",
            imageWidth=256,
            imageHeight=64,
            order = 0
        },

        helpPanel =
        {
            type = "group",
            name = "How to Use",
            order = 1,
            args =
            {
                helpText =
                {
                    type = "description",
                    fontSize = "medium",
                    name = "When completing Dragon Races or talking to the ".. DRL.Locale["NPC_TIMEKEEPER_ASSISTANT"][1] .." your time is recorded on the guild leaderboard!\
To populate the leaderboard with your times, speak to the ".. DRL.Locale["NPC_TIMEKEEPER_ASSISTANT"][1] .." at the start point of each race.",
                    order = 1.01
                },

                showWindowBtn =
                {
                    type = "execute",
                    name = "View Leaderboards",
                    desc = "View Guild Dragon Racing Leaderboards",
                    func = function() DRL.LeaderboardUI:Show() end,
                    order = 1.02,
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
                    width = "full",
                    desc = "Enables verbose printing of events and AddOn functions.",
                    set = function(info, val) DRL.moduleDB.debugMode = val  end,
                    get = function() return DRL.moduleDB.debugMode end,
                    order = 10.0
                },
            }
        }
    }
}

local DRL_SettingsUI = WCCCAD.UI:LoadModuleUI(DRL, "Dragon Racing Leaderboards", DRL_SETTINGS_CONFIG)
WCCCAD.UI:AddGuildControlButton("Dragon Racing", "View Guild Dragon Racing Times", function() DRL.LeaderboardUI:Show() end)