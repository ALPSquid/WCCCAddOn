--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD

local ClubberPoints = WCCCAD:GetModule("WCCC_ClubberPoints")

local CLUBBERPOINTS_UI_CONFIG =
{
    name = "Clubber Points",
    handler = ClubberPoints,
    type = "group",
    childGroups = "tab",
    args =
    {
        toggleDebugMode =
        {
            type = "toggle",
            name = "Debug Mode",
            desc = "Enables verbose printing of events and AddOn functions.",
            disabled = function() return WCCCAD:IsPlayerOfficer() == false end,
            hidden = function() return WCCCAD:IsPlayerOfficer() == false end,
            set = function(info, val)
                ClubberPoints.moduleDB.debugMode = val
            end,
            get = function()
                return ClubberPoints.moduleDB.debugMode
            end,
            order = 1
        }
    }
}

local ClubberPoints_UI = WCCCAD.UI:LoadModuleUI(ClubberPoints, "Clubber Points", CLUBBERPOINTS_UI_CONFIG)

function ClubberPoints_UI:OnDisable()
    DropDownList1:UnhookAll()
end

function ClubberPoints_UI:OnEnable()
    if not WCCCAD:IsPlayerOfficer() then
        return
    end

    -- TODO: Dropdown button needs refactoring to use the new dropdown system.
    if ClubberPoints_UI.dropDownList1WCCCFrame == nil then
        --region Guild Member Tooltip
        ClubberPoints_UI.awardPointsDialogKey = ClubberPoints.moduleName .. "AwardPointsDialog"
        ClubberPoints_UI.awardPointsConfirmationDialogKey = ClubberPoints.moduleName .. "AwardPointsConfirmationDialog"
        StaticPopupDialogs[ClubberPoints_UI.awardPointsDialogKey] =
        {
            text = "Award points to %s",
            button1 = "Award Points",
            button2 = "Cancel",
            hasEditBox = true,
            whileDead = true,
            hideOnEscape = true,
            timeout = 0,
            OnAccept = function(dialog)
                local numPoints = tonumber(dialog.editBox:GetText())
                if numPoints and numPoints > 0 then
                    ClubberPoints_UI.dropDownList1WCCCFrame.targetPlayerInfo.numPoints = numPoints
                    StaticPopup_Show(ClubberPoints_UI.awardPointsConfirmationDialogKey, numPoints, ClubberPoints_UI.dropDownList1WCCCFrame.targetPlayerInfo.nameRealm)
                else
                    WCCCAD.UI:PrintAddOnMessage("Points must be a number above 0.")
                end
            end,
            OnCancel = function(dialog)
                ClubberPoints_UI.dropDownList1WCCCFrame.targetPlayerInfo = nil
            end
        }

        StaticPopupDialogs[ClubberPoints_UI.awardPointsConfirmationDialogKey] =
        {
            text = "Award %i points to %s?",
            button1 = "Award Points",
            button2 = "Cancel",
            hasEditBox = false,
            whileDead = true,
            hideOnEscape = true,
            timeout = 0,
            OnAccept = function(dialog)
                WCCCAD.UI:PrintAddOnMessage(format("Awarding %i points to %s (%s)",
                        ClubberPoints_UI.dropDownList1WCCCFrame.targetPlayerInfo.numPoints,
                        ClubberPoints_UI.dropDownList1WCCCFrame.targetPlayerInfo.nameRealm,
                        ClubberPoints_UI.dropDownList1WCCCFrame.targetPlayerInfo.guid))

                ClubberPoints:OC_AwardPointsToPlayer(ClubberPoints_UI.dropDownList1WCCCFrame.targetPlayerInfo.guid, ClubberPoints_UI.dropDownList1WCCCFrame.targetPlayerInfo.numPoints)
            end,
            OnCancel = function(dialog)
                ClubberPoints_UI.dropDownList1WCCCFrame.targetPlayerInfo = nil
            end
        }

        -- TODO: Convert into similar system as the Guild Control Buttons if more buttons are needed.
        local dropDownList1WCCCFrame = CreateFrame("Frame", nil, DropDownList1)
        ClubberPoints_UI.dropDownList1WCCCFrame = dropDownList1WCCCFrame
        local dropDownWidth = 140
        dropDownList1WCCCFrame:SetSize(dropDownWidth, 30)
        dropDownList1WCCCFrame:SetPoint("TOP", DropDownList1, "BOTTOM", 0, 2)
        dropDownList1WCCCFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        dropDownList1WCCCFrame:Hide()

        -- Give Points Button
        dropDownList1WCCCFrame.givePointsBtn = CreateFrame("Button", nil, dropDownList1WCCCFrame, "UIPanelButtonTemplate")
        dropDownList1WCCCFrame.givePointsBtn:SetPoint("TOP", dropDownList1WCCCFrame, "TOP", 0, 0)
        dropDownList1WCCCFrame.givePointsBtn:SetText("Award Points")
        dropDownList1WCCCFrame.givePointsBtn:SetSize(dropDownWidth, 20)
        dropDownList1WCCCFrame.givePointsBtn:SetScript("OnClick", function()
            StaticPopup_Show(ClubberPoints_UI.awardPointsDialogKey, dropDownList1WCCCFrame.targetPlayerInfo.nameRealm)
        end)
        dropDownList1WCCCFrame.givePointsBtn:SetScript("OnHide", function(buttonSelf)
            if buttonSelf:IsMouseOver() and IsMouseButtonDown(1) then
                StaticPopup_Show(ClubberPoints_UI.awardPointsDialogKey, dropDownList1WCCCFrame.targetPlayerInfo.nameRealm)
            end
        end)

        -- Guild Icon
        dropDownList1WCCCFrame.givePointsBtn.guildIcon = CreateFrame("Button", nil, dropDownList1WCCCFrame.givePointsBtn)
        dropDownList1WCCCFrame.givePointsBtn.guildIcon:SetNormalTexture("Interface\\AddOns\\WCCCAddOn\\assets\\wccc-logo.tga")
        dropDownList1WCCCFrame.givePointsBtn.guildIcon:SetPoint("LEFT", dropDownList1WCCCFrame.givePointsBtn, "LEFT", 5, 0)
        dropDownList1WCCCFrame.givePointsBtn.guildIcon:SetWidth(12)
        dropDownList1WCCCFrame.givePointsBtn.guildIcon:SetHeight(12)
        dropDownList1WCCCFrame.givePointsBtn.guildIcon:EnableMouse(false)
        dropDownList1WCCCFrame.givePointsBtn.guildIcon:Show()
        --endregion
    end

    DropDownList1:HookScript("OnShow", function(_)
        local supportedContexts = {"FRIEND", "REPORT_PLAYER", "COMMUNITIES_GUILD_MEMBER"}
        local isSupportedContext = false
        for _, context in ipairs(supportedContexts) do
            if DropDownList1.dropdown.which == context then
                isSupportedContext = true
                break
            end
        end
        if not isSupportedContext then
            return
        end

        ClubberPoints_UI.dropDownList1WCCCFrame.targetPlayerInfo = nil
        if not DropDownList1.dropdown.clubMemberInfo then
            return
        end

        local guildID = C_Club.GetGuildClubId()
        local guid = DropDownList1.dropdown.clubMemberInfo.guid
        local nameRealm = DropDownList1.dropdown.clubMemberInfo.name
        local targetCommunityID = DropDownList1.dropdown.communityClubID
        if DropDownList1.dropdown.clubInfo then
            targetCommunityID = DropDownList1.dropdown.clubInfo.clubId
        end
        targetCommunityID = tonumber(targetCommunityID)

        if guildID ~= nil and targetCommunityID == guildID then
            ClubberPoints:PrintDebugMessage(nameRealm)
            ClubberPoints:PrintDebugMessage(targetCommunityID .. " vs guild: " .. guildID)

            ClubberPoints_UI.dropDownList1WCCCFrame:Show()
            ClubberPoints_UI.dropDownList1WCCCFrame.targetPlayerInfo =
            {
                guid = guid,
                nameRealm = nameRealm
            }
        end
    end)

    DropDownList1:HookScript("OnHide", function()
        ClubberPoints_UI.dropDownList1WCCCFrame:Hide()
    end)
end