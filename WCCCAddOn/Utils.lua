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
    local timeDelta = time() - timeStamp

    return ceil(timeDelta / 86400)
end