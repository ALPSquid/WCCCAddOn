--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--

local _, ns = ...
local WCCCAD = ns.WCCCAD

local ReleaseSpiritModule = WCCCAD:GetModule("WCCC_ReleaseSpiritConfirmation")

local RELEASE_SPIRIT_CONFIRMATION_UI_CONFIG = {
    name = "Release Spirit Confirmation",
    handler = ReleaseSpiritModule,
    type = "group",
    childGroups = "tab",
    args =
    {
        logo =
        {
            type = "description",
            name = "",
            image = "Interface\\AddOns\\WCCCAddOn\\assets\\wccc-header.tga",
            imageWidth = 256,
            imageHeight = 64,
            order = 0
        },

        settingsPanel =
        {
            type = "group",
            name = "Settings",
            order = 1,
            args =
            {
                helpText =
                {
                    type = "description",
                    fontSize = "medium",
                    name = "Shows a confirmation when pressing Release Spirit in the latest raid, so you don't miss raid resses.",
                    order = 1.0
                },

                toggleReleaseSpiritConfirmation =
                {
                    type = "toggle",
                    name = "Show Release Spirit confirmation in the latest raid",
                    width = "full",
                    desc = "Show Release Spirit confirmation in the latest raid.",
                    set = function(info, val)
                        ReleaseSpiritModule.moduleDB.enabled = val
                    end,
                    get = function()
                        return ReleaseSpiritModule.moduleDB.enabled
                    end,
                    order = 1.1,
                },

                toggleGuildOnly =
                {
                    type = "toggle",
                    name = "Only show in a Guild group",
                    width = "full",
                    desc = "If enabled, will only show confirmations if the raid group is a Guild group.",
                    set = function(info, val)
                        ReleaseSpiritModule.moduleDB.guildGroupOnly = val
                    end,
                    get = function()
                        return ReleaseSpiritModule.moduleDB.guildGroupOnly
                    end,
                    order = 1.2,
                }
            }
        }
    }
}
WCCCAD.UI:LoadModuleUI(ReleaseSpiritModule, "Release Spirit Confirmation", RELEASE_SPIRIT_CONFIRMATION_UI_CONFIG)