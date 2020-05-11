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

local ClubberPoints_UI = {}
if WCCCAD:IsPlayerOfficer() then
    ClubberPoints_UI = WCCCAD.UI:LoadModuleUI(ClubberPoints, "Clubber Points", CLUBBERPOINTS_UI_CONFIG)

    --region Guild Member Tooltip
    ClubberPoints_UI.AwardPointsDialogKey = ClubberPoints.moduleName .. "AwardPointsDialog"
    StaticPopupDialogs[ClubberPoints_UI.AwardPointsDialogKey] =
    {
        test = "Award points to %s",
        button1 = "Cancel",
        button2 = "Award Points",
        hasEditBox = true,
        whileDead = true,
        hideOnEscape = true,
        timeout = 0,
        OnAccept = function()
            local numPoints = getglobal(this:GetParent():GetName().."EditBox"):GetText()
            print(format("Awarding %i points", numPoints))
            -- TODO: Cache target GUID and award points to them.
            -- TODO: int validation
            -- ClubberPoints:OC_AwardPointsToPlayer(targetGUID, numPoints)
        end
    }

    -- TODO: Convert into similar system as the Guild Control Buttons if more buttons are needed.
    local dropDownList1WCCCFrame = CreateFrame("Frame", nil, DropDownList1)
    local dropDownWidth = 140
    dropDownList1WCCCFrame:SetSize(dropDownWidth, 30)
    dropDownList1WCCCFrame:SetPoint("TOP", DropDownList1, "BOTTOM", 0, 2)
    dropDownList1WCCCFrame:Hide()

    -- Give Points Button
    dropDownList1WCCCFrame.GivePointsBtn = CreateFrame("Button", nil, dropDownList1WCCCFrame, "UIPanelButtonTemplate")
    dropDownList1WCCCFrame.GivePointsBtn:SetPoint("TOP", dropDownList1WCCCFrame, "TOP", 0, 0)
    dropDownList1WCCCFrame.GivePointsBtn:SetText("Award Points")
    dropDownList1WCCCFrame.GivePointsBtn:SetSize(dropDownWidth, 20)
    dropDownList1WCCCFrame.GivePointsBtn:SetScript("OnClick", function()
        StaticPopup_Show(ClubberPoints_UI.AwardPointsDialogKey, DropDownList1.dropdown.name)
    end)
    -- Guild Icon
    dropDownList1WCCCFrame.GivePointsBtn.guildIcon = CreateFrame("Button", nil, dropDownList1WCCCFrame.GivePointsBtn)
    dropDownList1WCCCFrame.GivePointsBtn.guildIcon:SetNormalTexture("Interface\\AddOns\\WCCCAddOn\\assets\\wccc-logo.tga")
    dropDownList1WCCCFrame.GivePointsBtn.guildIcon:SetPoint("LEFT", 5, 0)
    dropDownList1WCCCFrame.GivePointsBtn.guildIcon:SetWidth(12)
    dropDownList1WCCCFrame.GivePointsBtn.guildIcon:SetHeight(12)
    dropDownList1WCCCFrame.GivePointsBtn.guildIcon:Show()


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

        -- TODO: Can we get GUID here?
        local guildID = C_Club.GetGuildClubId()
        local name = DropDownList1.dropdown.name
        local realm = DropDownList1.dropdown.server
        local targetCommunityID = DropDownList1.dropdown.communityClubID
        if DropDownList1.dropdown.clubInfo then
            targetCommunityID = DropDownList1.dropdown.clubInfo.clubId
        end
        targetCommunityID = tonumber(targetCommunityID)

        if guildID ~= nil and targetCommunityID == guildID then
            print(name.."-"..(realm and realm or ""))
            print(targetCommunityID .. " vs guild: " .. guildID)

            dropDownList1WCCCFrame:Show()
        end
    end)

    DropDownList1:HookScript("OnHide", function()
        dropDownList1WCCCFrame:Hide()
    end)
    --endregion

end