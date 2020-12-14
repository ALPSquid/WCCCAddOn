--
-- Simple functionality that shows a confirmation dialog when releasing spirit within the certain zones.
--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--

local ACTIVE_ZONES =
{
    -- Castle Nathria zones
    [1735] = true,
    [1744] = true,
    [1745] = true,
    [1746] = true,
    [1747] = true,
    [1748] = true,
    [1750] = true,
    [1755] = true,
}

local RELEASE_CONFIRMATION_DIALOG_KEY = "WCCC_CONFIRM_RELEASE_SPIRIT";
local defaultReleaseSpiritFunc = StaticPopupDialogs["DEATH"].OnButton1;

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
        return defaultReleaseSpiritFunc();
    end,

    OnCancel = function(dialog)
        if UnitIsDead("player") then
            StaticPopup_Show("DEATH");
        end
    end
}

-- Override the default release spirit button to show the confirmation when in an active raid zone.
StaticPopupDialogs["DEATH"].OnButton1 = function(self)
    -- TODO: Should we add an InGuildParty() check to only enable in guild groups?
    if ACTIVE_ZONES[C_Map.GetBestMapForUnit("player")] == true then
        StaticPopup_Show(RELEASE_CONFIRMATION_DIALOG_KEY);
    else
        return defaultReleaseSpiritFunc();
    end
end