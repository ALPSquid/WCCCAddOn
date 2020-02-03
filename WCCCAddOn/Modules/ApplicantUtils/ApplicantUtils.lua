--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
-- Applicant List utils intended for Officers.
local name, ns = ...
local WCCCAD = ns.WCCCAD


local wcccApplicantUtilsData = 
{
    profile =
    {
    }
}

local ApplicantUtils = WCCCAD:CreateModule("WCCC_ApplicantUtils", wcccApplicantUtilsData)
-- TODO: Possibly bake this pattern into the ModuleBase?
LibStub("AceEvent-3.0"):Embed(ApplicantUtils) 
LibStub("AceHook-3.0"):Embed(ApplicantUtils) 

local WHO_COMMAND_INTERVAL = 6

-- Array of player GUIDs
ApplicantUtils.onlineApplicants = 
{
    -- [guid] = guid
}

ApplicantUtils.refreshQueue = {}
ApplicantUtils.requestedApplicant = nil
ApplicantUtils.refreshInProgress = false
ApplicantUtils.waitingForResult = false

ApplicantUtils.queueTimeHandle = nil


function ApplicantUtils:InitializeModule()
    ApplicantUtils:RegisterModuleSlashCommand("checkapplicants", ApplicantUtils.CheckApplicants)
end

function ApplicantUtils:OnEnable()
    ApplicantUtils:SecureHook(CommunitiesFrame.ApplicantList, "RefreshLayout", ApplicantUtils.UpdateApplicantsList)

    if ApplicantUtils.CheckApplicantsButton == nil then
        ApplicantUtils.CheckApplicantsButton = CreateFrame("Button", nil, CommunitiesFrame, "UIPanelButtonTemplate");
        ApplicantUtils.CheckApplicantsButton:SetText("Check Online Applicants")
        ApplicantUtils.CheckApplicantsButton:SetSize(180, 20)
        ApplicantUtils.CheckApplicantsButton:SetPoint("BOTTOMRIGHT", CommunitiesFrame, 0, -20)
        ApplicantUtils.CheckApplicantsButton:RegisterForClicks("AnyUp")
        ApplicantUtils.CheckApplicantsButton:SetScript("OnClick", ApplicantUtils.CheckApplicants)
    end
    ApplicantUtils.CheckApplicantsButton:Show()
end

function ApplicantUtils:OnDisable()
    ApplicantUtils:UnhookAll()
    ApplicantUtils:Reset()
    ApplicantUtils.CheckApplicantsButton:Hide()
end

function ApplicantUtils:UpdateApplicantsList()
    for i, applicantButton in ipairs(CommunitiesFrame.ApplicantList.ListScrollFrame.buttons) do
        local playerName = applicantButton:GetApplicantName()

        if ApplicantUtils.onlineApplicants[playerName] == nil then
            if applicantButton.onlineIndicator ~= nil then
                applicantButton.onlineIndicator:Hide()
            end

            applicantButton.InviteButton.Text:SetFontObject(GameFontDisableSmall);
        else
            if applicantButton.onlineIndicator ~= nil then
                applicantButton.onlineIndicator:Show()
            else
                applicantButton.onlineIndicator = CreateFrame("Button", nil, applicantButton)
                applicantButton.onlineIndicator:SetNormalTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
                applicantButton.onlineIndicator:SetPoint("RIGHT", -105, 0)
                applicantButton.onlineIndicator:SetWidth(12)
                applicantButton.onlineIndicator:SetHeight(12)
                applicantButton.onlineIndicator:Show()

                applicantButton.InviteButton.Text:SetFontObject(GameFontHighlightSmall);
            end
        end
    end  
end

function ApplicantUtils:Reset() 
    WCCCAD:CancelTimer(ApplicantUtils.queueTimeHandle)
    ApplicantUtils.refreshQueue = {}
    ApplicantUtils.refreshInProgress = false
    ApplicantUtils.waitingForResult = false
    ApplicantUtils.requestedApplicant = nil
    ApplicantUtils:UnregisterEvent("WHO_LIST_UPDATE")
end

function ApplicantUtils:OnWhoEvent()
    local numResults = C_FriendList.GetNumWhoResults()
    WCCCAD.UI:PrintDebugMessage("Who event triggered.", WCCCAD.db.profile.debugMode)
    ApplicantUtils.waitingForResult = false

    if numResults > 0 then
        local whoInfo = C_FriendList.GetWhoInfo(1)
        WCCCAD.UI:PrintDebugMessage("Got who result for " .. whoInfo.fullName .. ", requested: ".. ApplicantUtils.requestedApplicant, WCCCAD.db.profile.debugMode)
        WCCCAD.UI:PrintAddOnMessage(whoInfo.fullName .. " is online!", ns.consts.MSG_TYPE.INFO)
        ApplicantUtils.onlineApplicants[ApplicantUtils.requestedApplicant] = ApplicantUtils.requestedApplicant

    else
        ApplicantUtils.onlineApplicants[ApplicantUtils.requestedApplicant] = nil
    end

    if WhoFrame:IsShown() then
        FriendsFrame:Hide()
    end

    ApplicantUtils:UpdateApplicantsList()
end

local lastApplicantCheckTimestamp = 0
function ApplicantUtils:CheckApplicants()
    if ApplicantUtils.refreshInProgress then
        WCCCAD.UI:PrintAddOnMessage("Refresh in progress.", ns.consts.MSG_TYPE.WARN)
        return
    end

    if GetServerTime() < lastApplicantCheckTimestamp + WHO_COMMAND_INTERVAL then
        WCCCAD.UI:PrintAddOnMessage("Please wait a short time before sending another applicant request.", ns.consts.MSG_TYPE.WARN)
        return
    end

    lastApplicantCheckTimestamp = GetServerTime()
    ApplicantUtils.refreshInProgress = true

    local pendingList = C_ClubFinder.ReturnClubApplicantList(C_Club.GetGuildClubId())
    
    for i,applicant in ipairs(pendingList) do
        local applicantQueued = false
        for i, queuedApplicant in ipairs(ApplicantUtils.refreshQueue) do
            if queuedApplicant == applicant.name then
                applicantQueued = true
                break
            end
        end

        if not applicantQueued then
            table.insert(ApplicantUtils.refreshQueue, applicant.name)
        end
    end

    ApplicantUtils:RegisterEvent("WHO_LIST_UPDATE", ApplicantUtils.OnWhoEvent)
    ApplicantUtils:ProcessQueue()
end

function ApplicantUtils:ProcessQueue()
    if #ApplicantUtils.refreshQueue == 0 then        
        if ApplicantUtils.refreshInProgress then
            WCCCAD.UI:PrintAddOnMessage("Refresh complete.", ns.consts.MSG_TYPE.WARN)
        end
        ApplicantUtils:Reset()        
        return
    end

    if ApplicantUtils.waitingForResult then
        WCCCAD.UI:PrintDebugMessage("Waiting for result, skipping ProcessQueue", WCCCAD.db.profile.debugMode)
        return
    end

    local nextApplicant = ApplicantUtils.refreshQueue[#ApplicantUtils.refreshQueue]
    table.remove(ApplicantUtils.refreshQueue, #ApplicantUtils.refreshQueue)

    WCCCAD.UI:PrintDebugMessage("Showing button for " .. nextApplicant, WCCCAD.db.profile.debugMode)
    ApplicantUtils:ShowSendWhoButton(nextApplicant)
    ApplicantUtils.waitingForResult = true
end

function ApplicantUtils:ShowSendWhoButton(requestedApplicant)
    if ApplicantUtils.sendWhoButton == nil then
        ApplicantUtils.sendWhoButton = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate,ActionButtonTemplate");
        local sendWhoButtonTex = ApplicantUtils.sendWhoButton:CreateTexture()
        sendWhoButtonTex:SetTexture("interface\\icons\\inv_misc_groupneedmore")
        sendWhoButtonTex:SetWidth(50)
        sendWhoButtonTex:SetHeight(50)
        sendWhoButtonTex:SetAllPoints()
        ApplicantUtils.sendWhoButton:SetNormalTexture(tex)
        ApplicantUtils.sendWhoButton:SetSize(50, 50)
        ApplicantUtils.sendWhoButton:SetPoint("center", UIParent)
        ApplicantUtils.sendWhoButton:RegisterForClicks("AnyUp")
        ApplicantUtils.sendWhoButton:SetScript("PostClick", function(self) 
            ApplicantUtils.sendWhoButton:Hide() 
            ApplicantUtils.cancelCheckButton:Hide()
        end)
        ApplicantUtils.sendWhoButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetText("Run online check")
            GameTooltip:Show()
        end)
        ApplicantUtils.sendWhoButton:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end

    ApplicantUtils.sendWhoButton:Show()
    ApplicantUtils.sendWhoButton:SetScript("OnClick", function(self)
        ApplicantUtils.requestedApplicant = requestedApplicant
        C_FriendList.SetWhoToUi(true)
        C_FriendList.SendWho(requestedApplicant) 
        ApplicantUtils.queueTimeHandle = WCCCAD:ScheduleTimer(ApplicantUtils.ProcessQueue, WHO_COMMAND_INTERVAL)
        ActionButton_HideOverlayGlow(ApplicantUtils.sendWhoButton)
    end)
    ActionButton_ShowOverlayGlow(ApplicantUtils.sendWhoButton)


    if ApplicantUtils.cancelCheckButton == nil then
        ApplicantUtils.cancelCheckButton = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate,ActionButtonTemplate");
        local cancelCheckButtonTex = ApplicantUtils.cancelCheckButton:CreateTexture()
        cancelCheckButtonTex:SetTexture("interface\\icons\\icon_7fx_nightborn_astromancer_blue")
        cancelCheckButtonTex:SetWidth(30)
        cancelCheckButtonTex:SetHeight(30)
        cancelCheckButtonTex:SetAllPoints()
        ApplicantUtils.cancelCheckButton:SetNormalTexture(closeButtonTex)
        ApplicantUtils.cancelCheckButton:SetSize(30, 30)
        ApplicantUtils.cancelCheckButton:SetPoint("center", UIParent, 75, 0)
        ApplicantUtils.cancelCheckButton:RegisterForClicks("AnyUp")
        ApplicantUtils.cancelCheckButton:SetScript("PostClick", function(self) 
            ApplicantUtils.cancelCheckButton:Hide()
            ApplicantUtils.sendWhoButton:Hide()
        end)
        ApplicantUtils.cancelCheckButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetText("Cancel online check")
            GameTooltip:Show()
        end)
        ApplicantUtils.cancelCheckButton:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        ApplicantUtils.cancelCheckButton:SetScript("OnClick", function(self)
            ApplicantUtils:Reset()        
            WCCCAD.UI:PrintAddOnMessage("Online check cancelled.", ns.consts.MSG_TYPE.WARN)
        end)
    end
    ApplicantUtils.cancelCheckButton:Show()
end