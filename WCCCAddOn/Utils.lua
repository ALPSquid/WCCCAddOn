--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...

ns.consts = {}
ns.utils = {}

ns.utils.WCCC_GUILD_NAME = "Worgen Cub Clubbing Club"

ns.consts.VERSION_TYPE =
{
    ALPHA = 
    {
        value = 1,
        name = "alpha"
    },

    BETA = 
    {
        value = 2,
        name = "beta"
    },

    RELEASE = 
    {
        value = 3,
        name = "release"
    }
}

ns.consts.DATA_SYNC_RESULT =
{
    LOCAL_NEWER = -1,
    EQUAL = 0,
    REMOTE_NEWER = 1,
    BOTH_NEWER = 2
}

ns.consts.CHAT_CHANNEL = 
{
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

ns.utils.LongDate = function(timeStamp)
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

ns.utils.HoursSince = function(timeStamp)
    local timeDelta = GetServerTime() - timeStamp

    return ceil(timeDelta / 3600)
end

ns.utils.MinutesSince = function(timeStamp)
    local timeDelta = GetServerTime() - timeStamp

    return ceil(timeDelta / 60)
end

--- Creates a string displaying the time since the specified timestamp. e.g. "10 hours ago", "5 minutes ago"
ns.utils.GetTimeSinceString = function(timeStamp)
    local currentTime = GetServerTime()
    if timeStamp > currentTime then
        timeStamp = currentTime
        print("[WCCC][ERROR] Tried to check the time since a date in the future. This should never happen, please inform Aerthok!")
    end

    local timeDelta = currentTime - timeStamp
    local formattedTime
    local unitString

    if timeDelta >= 86400 then
        formattedTime = ns.utils.DaysSince(timeStamp)
        unitString = formattedTime == 1 and "day" or "days"

    elseif timeDelta >= 3600 then
        formattedTime = ns.utils.HoursSince(timeStamp)
        unitString = formattedTime == 1 and "hour" or "hours"

    else
        formattedTime = ns.utils.MinutesSince(timeStamp)
        unitString = formattedTime == 1 and "min" or "mins"
    end

    return format("%i %s ago", formattedTime, unitString)

end

ns.utils.GetLastServerResetTimestamp = function()
    -- TODO: Could convert this to use the new C_DateAndTime.GetSecondsUntilWeeklyReset() function: GetServerTime() - (reset_length - time_until_reset)
    local currentTimestamp = GetServerTime()
    local currentDate = date("!*t", currentTimestamp)

    local minutesPastResetMinute = currentDate.min
    local hoursPastResetHour = currentDate.hour - 7

    local daysPastResetDay = currentDate.wday - 4
    if daysPastResetDay < 0 or (daysPastResetDay == 0 and hoursPastResetHour < 0) then
        daysPastResetDay = 7 + daysPastResetDay
    end

    local secondsPastReset = currentDate.sec + (minutesPastResetMinute * 60) + (hoursPastResetHour * 60 * 60) + (daysPastResetDay * 24 * 60 * 60)

    -- TODO: Might not be necessary? Test in other timezones.
    local serverOffset = currentTimestamp - time(currentDate)
    secondsPastReset = secondsPastReset +  serverOffset

    return currentTimestamp - secondsPastReset
end

--- Returns true if the specified player GUID is in a valid format.
ns.utils.isValidPlayerGUID = function(GUID)
    if GUID == nil then
        return false
    end
    local pattern = "^Player%-[0-9A-Z]+%-[0-9A-Z]+$"
    return GUID:match(pattern) ~= nil
end

--- Returns the max value of an attribute across all objects in a table.
--- @param attributeGetter fun(table):number @Function that returns the attribute value for the specified object.
ns.utils.MaxAttribute = function(table, attributeGetter)
    local max, attrVal = nil
    for _, object in pairs(table) do
        attrVal = attributeGetter(object)
        if max == nil or attrVal > max then
            max = attrVal
        end
    end
    return max
end

--- Returns the min value of an attribute across all objects in a table.
--- @param attributeGetter fun(table):number @Function that returns the attribute value for the specified object.
ns.utils.MinAttribute = function(table, attributeGetter)
    local min, attrVal = nil
    for _, object in pairs(table) do
        attrVal = attributeGetter(object)
        if min == nil or attrVal < min then
            min = attrVal
        end
    end
    return min
end

--- Returns true if the table contains the specified value.
ns.utils.TableContains = function(table, search_value)
    for _, value in ipairs(table) do
        if value == search_value then
            return true
        end
    end
    return false
end

--- Format special sequences in a string, such as {skull} and |cblue word |r
ns.utils.FormatSpecialString = function(inputString)
    local formatStrings = 
    {
        -- Colours
        {"|cred", "|cffd23636"},
        {"|cblue", "|cff009bfd"},
        {"|cgreen", "|cff4df439"},	
        {"|cyellow", "|cfffdc500"},
        {"|corange", "|cfffd8e00"},

        -- Marks
        {"{star}", "{rt1}"},
        {"{circle}", "{rt2}"},
        {"{diamond}", "{rt3}"},
        {"{triangle}", "{rt4}"},
        {"{moon}", "{rt5}"},
        {"{square}", "{rt6}"},
        {"{cross}", "{rt7}"},
        {"{x}", "{rt7}"},
        {"{skull}", "{rt8}"},
        {"{rt([1-8])}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%1:0|t"},
        {"{bl}", "|TInterface\\Icons\\SPELL_Nature_Bloodlust:0|t"},

        -- Roles
        {"{tank}", "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:0:19:22:41|t"},
        {"{healer}", "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:20:39:1:20|t"},
        {"{dps}", "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:20:39:22:41|t"},
        {"{melee}", "{warrior}"},
        {"{ranged}", "{hunter}"},

        -- Classes
        {"{deathknight}", "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:0:0:0:0:64:64:16:32:32:48|t"},
        {"{demonhunter}", "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:0:0:0:0:64:64:64:48:32:48|t"},
        {"{druid}", "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:0:0:0:0:64:64:48:64:0:16|t"},
        {"{hunter}", "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:0:0:0:0:64:64:0:16:16:32|t"},
        {"{mage}", "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:0:0:0:0:64:64:16:32:0:16|t"},
        {"{monk}", "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:0:0:0:0:64:64:32:48:32:48|t"},
        {"{paladin}", "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:0:0:0:0:64:64:0:16:32:48|t"},
        {"{priest}", "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:0:0:0:0:64:64:32:48:16:32|t"},
        {"{rogue}", "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:0:0:0:0:64:64:32:48:0:16|t"},
        {"{shaman}", "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:0:0:0:0:64:64:16:32:16:32|t"},
        {"{warlock}", "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:0:0:0:0:64:64:48:64:16:32|t"},
        {"{warrior}", "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:0:0:0:0:64:64:0:16:0:16|t"},

    }

    local formattedString = inputString:gsub("||", "|")
    for _, formatData in pairs(formatStrings) do
        formattedString = formattedString:gsub(formatData[1], formatData[2])
    end

    return formattedString
end

---
--- Creates a floating UI panel themed in the WCCC style. Includes lock and dragging.
--- @param framePointGetter fun():number, number, number @Function that returns the point, offsetX, offsetY for the frame.
--- @param framePointSetter fun(point:number, offsetX:number, offsetY:number) @Function that takes the point, offsetX, offsetY for the frame to be saved.
--- @param infoPressedCallback fun() @Function called when the info button or guild logo is pressed.
--- @param resizable boolean optional @Whether the frame should be resizable.
--- @param sizeGetter fun():number, number optional @Function that returns the width, height for the frame.
--- @param sizeSetter fun(width:number, height:number) optional @Function that takes the width, height for the frame to be saved.
---
ns.utils.CreateHUDPanel = function(title, framePointGetter, framePointSetter, infoPressedCallback, closePressedCallback, resizable, sizeGetter, sizeSetter) 
    local hudFrame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
    hudFrame:SetFrameStrata("MEDIUM")

    local point, offsetX, offsetY = framePointGetter()
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

        local newPoint, _, _, newOffsetX, newOffsetY = hudFrame:GetPoint()
        framePointSetter(newPoint, newOffsetX, newOffsetY)
    end)

    function hudFrame.SetLocked(hudFrameSelf, locked)
        hudFrameSelf.IsLocked = locked
        hudFrameSelf:EnableMouse(not locked) 

        local lockTexture = "Interface\\LFGFRAME\\UI-LFG-ICON-LOCK"
        local backdropAlpha = 0.3
        local borderAlpha = 0.4
        if not locked then
            backdropAlpha = 0.8
            borderAlpha = 1
            lockTexture = "Interface\\CURSOR\\UI-Cursor-Move"
        end

        hudFrameSelf:SetBackdropColor(0, 0, 0, backdropAlpha)
        hudFrameSelf:SetBackdropBorderColor(1, 0.62, 0, borderAlpha)

        hudFrameSelf.lockBtn:SetNormalTexture(lockTexture)

        if hudFrameSelf.resizeHandle ~= nil then
            if locked then 
                hudFrameSelf.resizeHandle:Hide()
            else
                hudFrameSelf.resizeHandle:Show()
            end                
        end
    end

    --- Lock Button
    hudFrame.lockBtn = CreateFrame("Button", nil, hudFrame)
	hudFrame.lockBtn:SetNormalTexture("Interface\\LFGFRAME\\UI-LFG-ICON-LOCK")
	hudFrame.lockBtn:SetPoint("TOPRIGHT", -10, -5)
	hudFrame.lockBtn:SetWidth(12)
	hudFrame.lockBtn:SetHeight(14)
    hudFrame.lockBtn:SetScript("OnClick", function() 
        hudFrame:SetLocked(not hudFrame.IsLocked) 
    end)

    --- Info Button
    local infoBtn = CreateFrame("Button", nil, hudFrame)
	infoBtn:SetNormalTexture("Interface\\FriendsFrame\\InformationIcon")
	infoBtn:SetPoint("TOPRIGHT", -45, -5)
	infoBtn:SetWidth(12)
	infoBtn:SetHeight(14)
    infoBtn:SetScript("OnClick", function()
        infoPressedCallback()
    end)

    --- Close Button
    hudFrame.closeBtn = CreateFrame("Button", nil, hudFrame)
	hudFrame.closeBtn:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
	hudFrame.closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
	hudFrame.closeBtn:SetPoint("TOPRIGHT", -27, -5)
	hudFrame.closeBtn:SetWidth(12)
	hudFrame.closeBtn:SetHeight(14)
    hudFrame.closeBtn:SetScript("OnClick", function() 
        closePressedCallback()
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

    --- Resize handling
    if resizable then
        hudFrame:SetResizable(true)

        local width, height = sizeGetter()
        hudFrame:SetSize(width, height)
        hudFrame:SetResizeBounds(200, 200)

        hudFrame.resizeHandle = CreateFrame("Button", nil, hudFrame)
        hudFrame.resizeHandle:SetPoint("BOTTOMRIGHT", 0, 0)
        hudFrame.resizeHandle:SetSize(16, 16)
        hudFrame.resizeHandle:EnableMouse(true)
        hudFrame.resizeHandle:SetNormalTexture("Interface\\AddOns\\WCCCAddOn\\assets\\resize-handle.tga")
        hudFrame.resizeHandle:SetFrameLevel(99)

        hudFrame.resizeHandle:SetScript("OnMouseDown", function() 
            if hudFrame.IsLocked then
                return
            end

            hudFrame:StartSizing("BOTTOMRIGHT")
        end)

        hudFrame:SetScript("OnSizeChanged", function(hudFrameSelf, newWidth, newHeight)
            sizeSetter(newWidth, newHeight)
        end)

        hudFrame.resizeHandle:SetScript("OnMouseUp", function() 
            hudFrame:StopMovingOrSizing()

            sizeSetter(hudFrame:GetWidth(), hudFrame:GetHeight())
        end)
    end

    hudFrame:SetLocked(true)

    return hudFrame
end
