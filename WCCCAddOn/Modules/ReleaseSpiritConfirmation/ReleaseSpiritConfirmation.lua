--
-- Simple functionality that shows a confirmation dialog when releasing spirit within the certain zones.
--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--

local _, ns = ...
local WCCCAD = ns.WCCCAD

local ACTIVE_ZONES =
{

}

local ACTIVE_INSTANCES =
{
    -- Vault of the Incarnates
    [2522] = true,
}

local RELEASE_CONFIRMATION_DIALOG_KEY = "WCCC_CONFIRM_RELEASE_SPIRIT";

local releaseSpiritData =
{
    profile =
    {
        enabled = true,
        guildGroupOnly = false
    }
}

local ReleaseSpiritModule = WCCCAD:CreateModule("WCCC_ReleaseSpiritConfirmation", releaseSpiritData)


function ReleaseSpiritModule:InitializeModule()
    ReleaseSpiritModule.defaultReleaseSpiritFunc = StaticPopupDialogs["DEATH"].OnButton1

    StaticPopupDialogs[RELEASE_CONFIRMATION_DIALOG_KEY] =
    {
        text = "[WCCC] Are you sure there isn't a raid res incoming?",
        button1 = "Release Spirit",
        button2 = "Cancel",
        hasEditBox = false,
        whileDead = 1,
        hideOnEscape = false,
        timeout = 0,

        OnAccept = function(dialog)
            self:PrintDebugMessage("Dialog OnAccept")
            local result = ReleaseSpiritModule.defaultReleaseSpiritFunc(dialog)
            self:PrintDebugMessage("Default release func result: " .. result)
            StaticPopup_Hide(RELEASE_CONFIRMATION_DIALOG_KEY)
            return result
        end,

        OnCancel = function(dialog)
            if UnitIsDead("player") then
                StaticPopup_Show("DEATH")
            end
        end,

        OnShow = function(dialog)
            self:PrintDebugMessage("Dialog OnShow")
        end,

        OnHide = function(dialog)
            self:PrintDebugMessage("Dialog OnHide")
        end
    }

    -- Override the default release spirit button to show the confirmation when in an active raid zone.
    StaticPopupDialogs["DEATH"].OnButton1 = function(dialog)
        local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
        local zoneID = C_Map.GetBestMapForUnit("player")
        self:PrintDebugMessage(format("InstanceID=%i UiMapID=%i", instanceID, zoneID))
        if ReleaseSpiritModule.moduleDB.enabled
                and (ACTIVE_INSTANCES[instanceID] == true or ACTIVE_ZONES[zoneID] == true)
                and ((ReleaseSpiritModule.moduleDB.guildGroupOnly and InGuildParty()) or not ReleaseSpiritModule.moduleDB.guildGroupOnly)
        then
            self:PrintDebugMessage("Showing release spirit confirmation.")
            StaticPopup_Show(RELEASE_CONFIRMATION_DIALOG_KEY)
        else
            return ReleaseSpiritModule.defaultReleaseSpiritFunc(dialog)
        end
    end

    self:PrintDebugMessage("Release Spirit Confirmation module loaded.")
end
