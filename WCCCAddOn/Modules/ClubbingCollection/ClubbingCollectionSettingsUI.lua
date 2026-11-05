--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD

local ClubbingCollection = WCCCAD:GetModule("WCCC_ClubbingCollection")

local CLUBBINGCOLLECTION_SETTINGS_CONFIG =
{
    name = "Clubbing Collection",
    handler = ClubbingCollection,
    type = "group",
    childGroups = "tab",
    args =
    {
        logo =
        {
            type = "description",
            name = "",
            image ="Interface\\AddOns\\WCCCAddOn\\assets\\wccc-header-clubbingcollection.tga",
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
                    name = "Azeroth is filled with all manners of interesting wildlife, people and objects. As a member of the WCCC, your task is to club them all!\
The Clubbing Collection features a variety of targets spread out across Azeroth.\
Can you find and club them all?",
                    order = 1.01
                },

                showWindowBtn =
                {
                    type = "execute",
                    name = "View Collection",
                    desc = "View your Clubbing Collection!",
                    func = function() ClubbingCollection.CollectionUI:Show() end,
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
                    set = function(info, val) ClubbingCollection.moduleDB.debugMode = val  end,
                    get = function() return ClubbingCollection.moduleDB.debugMode end,
                    order = 10.0
                },

                wipeCollectionBtn =
                {
                    type = "execute",
                    name = "Wipe Collection",
                    desc = "Wipe your earned collection.",
                    func = function() ClubbingCollection.moduleDB.collection = {} end,
                    order = 10.1
                },
            }
        }
    }
}

local ClubbingCollectionSettingsUI = WCCCAD.UI:LoadModuleUI(ClubbingCollection, "Clubbing Collection", CLUBBINGCOLLECTION_SETTINGS_CONFIG)
WCCCAD.UI:AddGuildControlButton("Clubbing Collection", "View a collection of elusive targets to club!", function() ClubbingCollection.CollectionUI:Show() end)
