--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local name, ns = ...

ns.consts = {}
ns.utils = {}

ns.consts.CHAT_CHANNEL = {
    EMOTE = "EMOTE",
    SAY = "SAY",
    YELL = "YELL",
    GUILD = "GUILD",
    PARTY = "PARTY",
    RAID = "RAID",
    WHISPER = "WHISPER",
    INSTANCE_CHAT = "INSTANCE_CHAT"
}

ns.consts.MSG_TYPE = 
{
    INFO = "info",
    WARN = "warn",
    ERROR = "error",
    GUILD = "guild",
}

ns.consts.TENSE =
{
    SUBJ = "SUBJECT",
    POS = "POSSESSIVE",
    OBJ = "OBJECT"
}

ns.consts.EVENTS = 
{
    GUILD_MEMBER_LOGGED_IN = "WCCC_GUILD_MEMBER_LOGGED_IN"
}
---
--- UTILS
---

ns.utils.GetPlayerNameRealmString = function()
    local name, realm = UnitFullName("player")
    return name.."-"..realm
end

ns.utils.Pronoun = function(tense, upper)
    local pronouns = 
    {
        {[ns.consts.TENSE.SUBJ] = "it", [ns.consts.TENSE.POS] = "its", [ns.consts.TENSE.OBJ] = "it"},
        {[ns.consts.TENSE.SUBJ] = "he", [ns.consts.TENSE.POS] = "his", [ns.consts.TENSE.OBJ] = "him"},
        {[ns.consts.TENSE.SUBJ] = "she", [ns.consts.TENSE.POS] = "her", [ns.consts.TENSE.OBJ] = "her"},
    }

    local gender = UnitSex("player")
    local pronoun = pronouns[gender][tense]

    if upper == true then
        pronoun = pronoun:gsub("^%l", string.upper)
    end

    return pronoun
end

ns.utils.LongData = function(timeStamp)
    local day = date("%d", timeStamp)
    local month = date("%B", timeStamp)

    if string.sub(day, 1, 1) == "0" then
        day = string.sub(day, -1)
    end

    local suffix = "th"
    if day == "1" or day == "21" or day == "31" then
        suffix = "st"
    elseif day == "2" or day == "22" then
        suffix = "nd"
    elseif day == "3" or day == "23" then
        suffix = "rd"
    end

    return day..suffix.." "..month
end

ns.utils.DaysSince = function(timeStamp)
    local timeDelta = GetServerTime() - timeStamp

    return ceil(timeDelta / 86400)
end


---
--- Creates a floating UI panel themed in the WCCC style. Includes lock and dragging.
--- @param framePointGetter - Function that returns the point, offsetX, offsetY for the framem
--- @param framePointSetter - Function that takes the point, offsetX, offsetY for the frame to be saved.
--- @param infoPressedCallback - Function called when the info button or guild logo is pressed.
---
ns.utils.CreateHUDPanel = function(title, framePointGetter, framePointSetter, infoPressedCallback) 
    local hudFrame = CreateFrame("Frame", nil, UIParent)
    hudFrame:SetFrameStrata("MEDIUM")

    point, offsetX, offsetY = framePointGetter()
    hudFrame:SetPoint(
        point, 
        nil,
        point,
        offsetX, 
        offsetY)
    hudFrame:SetWidth(200)
    hudFrame:SetHeight(200)
    hudFrame:SetMovable(true)
    hudFrame:SetResizable(false)
    hudFrame:SetClampedToScreen(true)
    hudFrame:SetBackdrop(
    {
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
        tile = true, tileSize = 16, edgeSize = 16, 
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    hudFrame:SetBackdropColor(0, 0, 0, 0.2)

    hudFrame:EnableMouse(false)
    hudFrame:RegisterForDrag("LeftButton")
    hudFrame:SetScript("OnDragStart", hudFrame.StartMoving)
    hudFrame:SetScript("OnDragStop", function()
        hudFrame:StopMovingOrSizing()

        point, relativeTo, relativePoint, offsetX, offsetY = hudFrame:GetPoint()
        framePointSetter(point, offsetX, offsetY)
    end)

    hudFrame.SetLocked = function(self, locked)
        hudFrame.IsLocked = locked
        hudFrame:EnableMouse(not locked) 

        local lockTexture = "Interface\\LFGFRAME\\UI-LFG-ICON-LOCK"
        local backdropAlpha = 0.3
        local borderAlpha = 0.4
        if not locked then
            backdropAlpha = 0.8
            borderAlpha = 1
            lockTexture = "Interface\\CURSOR\\UI-Cursor-Move"
        end

        hudFrame:SetBackdropColor(0, 0, 0, backdropAlpha)
        hudFrame:SetBackdropBorderColor(1, 0.62, 0, borderAlpha)

        hudFrame.lockIcon:SetNormalTexture(lockTexture)
    end

    --- Lock Icon
    hudFrame.lockIcon = CreateFrame("Button", nil, hudFrame)
	hudFrame.lockIcon:SetNormalTexture("Interface\\LFGFRAME\\UI-LFG-ICON-LOCK")
	hudFrame.lockIcon:SetPoint("TOPRIGHT", -10, -5)
	hudFrame.lockIcon:SetWidth(12)
	hudFrame.lockIcon:SetHeight(14)
    hudFrame.lockIcon:SetScript("OnClick", function() 
        hudFrame:SetLocked(not hudFrame.IsLocked) 
    end)

    --- Info Button
    local infoBtn = CreateFrame("Button", nil, hudFrame)
	infoBtn:SetNormalTexture("Interface\\FriendsFrame\\InformationIcon")
	infoBtn:SetPoint("TOPRIGHT", -25, -5)
	infoBtn:SetWidth(12)
	infoBtn:SetHeight(14)
    infoBtn:SetScript("OnClick", function()
        infoPressedCallback()
    end)

    --- Guild Logo
    local guildLogo = CreateFrame("Button", nil, hudFrame)
	guildLogo:SetNormalTexture("Interface\\AddOns\\WCCCAddOn\\assets\\wccc-logo.tga")
	guildLogo:SetPoint("TOPLEFT", 5, -5)
	guildLogo:SetWidth(12)
	guildLogo:SetHeight(12)
    guildLogo:SetScript("OnClick", function()
        infoPressedCallback()
    end) 

    --- Title
    hudFrame.title = hudFrame:CreateFontString()
    hudFrame.title:SetFontObject(GameFontNormal)
    hudFrame.title:SetTextColor(1, 0.62, 0, 1)
    hudFrame.title:SetPoint("TOPLEFT", 18, -5)
    hudFrame.title:SetText(title)

    hudFrame:SetLocked(true)

    return hudFrame
end