--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
-- Core AddOn module-style functionality.
local _, ns = ...
local WCCCAD = ns.WCCCAD

WCCCAD.version = 1702
WCCCAD.versionString = "1.7.2"
WCCCAD.versionType = ns.consts.VERSION_TYPE.RELEASE
--WCCCAD.versionType = ns.consts.VERSION_TYPE.BETA
WCCCAD.newVersionAvailable = false


local COMM_KEY_SHARE_VERSION = "shareVersionRequest"
local COMM_KEY_PLAYER_MAIN_UPDATED = "playerMainUpdated"

local wcccCoreData = 
{
    profile =
    {
        firstTimeUser = true,
        lastCharactersDataWipeVersion = 0,

        ---@class WCCCAD_CharacterDataEntry
        ---@field GUID string
        ---@field name string
        ---@field lastUpdateTimestamp number

        ---@class WCCCAD_CharacterData
        ---@field main string
        ---@field mainUpdateTimestamp number
        ---@field characters table<string, WCCCAD_CharacterDataEntry>

        ---@type table<WCCCAD_CharacterData>
        localPlayerCharacters =
        {
            -- { main = GUID, mainUpdateTimestamp, characters = {{GUID, name, lastUpdateTimestamp}}
        },
        ---@type table<WCCCAD_CharacterData>
        guildPlayerCharacters =
        {
            -- { main = GUID, mainUpdateTimestamp, characters = {{GUID, name, lastUpdateTimestamp}}
        }
    }
}

local WCCCADCore = WCCCAD:CreateModule("WCCC_Core", wcccCoreData)
-- TODO: Possibly bake this pattern into the ModuleBase?
LibStub("AceEvent-3.0"):Embed(WCCCADCore) 
LibStub("AceHook-3.0"):Embed(WCCCADCore)

-- Array of player GUIDs
WCCCADCore.knownAddonUsers = 
{
    -- [guid] = guid
}

-- Last AddOn version a data wipe was requests to fix bad data issues.
-- This is checked against self.moduleDB.lastCharactersDataWipeVersion and other player's data.
WCCCADCore.charactersDataWipeVersion = 1512


function WCCCADCore:InitializeModule()
    self:RegisterModuleSlashCommand("ver", self.VersionCommand)

    self:RegisterModuleComm(COMM_KEY_SHARE_VERSION, self.OnShareVersionCommReceived)
    self:RegisterModuleComm(COMM_KEY_PLAYER_MAIN_UPDATED, self.OnPlayerMainUpdated)
end

function WCCCADCore:OnEnable()
    if self.moduleDB.firstTimeUser == true then
        self:ShowFTUEWindow()
    end

    -- Setup hook to the community roster refresh event for updating AddOn user icons.
    self:SecureHook(CommunitiesFrame.MemberList, "RefreshListDisplay", function()
        self:UpdateGuildRosterAddonIndicators()
    end)

    local playerGUID = UnitGUID("player")
    self.knownAddonUsers[playerGUID] = playerGUID
    -- Check data wipe requests.
    if self.moduleDB.lastCharactersDataWipeVersion < WCCCADCore.charactersDataWipeVersion then
        self.moduleDB.guildPlayerCharacters = {}
        self.moduleDB.lastCharactersDataWipeVersion = WCCCADCore.charactersDataWipeVersion
    end
    self:RegisterLocalPlayerCharacter(playerGUID, UnitName("player"))
    self:BuildPlayerCharactersLookup()
    self:InitiateSync()
end

function WCCCADCore:OnDisable()
    self:UnhookAll()
end

--region Alt Tracking

---
--- @returns WCCCAD_CharacterDataEntry @Main character data for the player that owns the specified character.
---
function WCCCAD:GetPlayerMain(characterGUID)
    if not self.guildPlayerCharactersLookup[characterGUID] then
        --WCCCADCore:PrintDebugMessage(format("Character with ID %s not found in character lookup!", characterGUID))
        return nil
    end
    local mainGUID = self.guildPlayerCharactersLookup[characterGUID].main
    local mainData =
    {
        GUID = mainGUID,
        name = self.guildPlayerCharactersLookup[characterGUID].characters[mainGUID].name,
        lastUpdateTimestamp = self.guildPlayerCharactersLookup[characterGUID].mainUpdateTimestamp
    }
    return mainData
end

---
--- @returns table<string, WCCCAD_CharacterDataEntry> @Array of characters owned by the player who owns the specified character.
---
function WCCCAD:GetPlayerCharacters(characterGUID)
    if not self.guildPlayerCharactersLookup[characterGUID] then
        --WCCCADCore:PrintDebugMessage(format("Character with ID %s not found in character lookup!", characterGUID))
        return nil
    end
    return self.guildPlayerCharactersLookup[characterGUID].characters
end

function WCCCADCore:RegisterLocalPlayerCharacter(GUID, playerName)
    if not self.moduleDB.localPlayerCharacters then
        self.moduleDB.localPlayerCharacters =
        {
            main = nil,
            mainUpdateTimestamp = 0,
            characters = {}
        }
    end
    if not self.moduleDB.localPlayerCharacters.characters then
        self.moduleDB.localPlayerCharacters.characters = {}
    end
    if not self.moduleDB.localPlayerCharacters.characters[GUID] then
        WCCCAD.UI:PrintAddOnMessage("New alt registered. You can set your main in the AddOn settings - /wccc or click the logo under the guild window.")
    end
    -- Always update the entry so the timestamp is up-to-date and potential name changes are caught.
    self.moduleDB.localPlayerCharacters.characters[GUID] =
    {
        GUID = GUID,
        name = playerName,
        lastUpdateTimestamp = GetServerTime()
    }
    -- Set default main without a timestamp, so newer synced data will overwrite it in the case of a fresh install.
    if not self.moduleDB.localPlayerCharacters.main then
        self.moduleDB.localPlayerCharacters.main = GUID
    end

    -- Update moduleDB data
    local entryFound = false
    for i, charactersData in ipairs(self.moduleDB.guildPlayerCharacters) do
        -- If this entry has data for this character or this entry has data for a different local character, update it.
        if charactersData.characters[GUID] then
            entryFound = true
        else
            for characterGUID, character in pairs(charactersData.characters) do
                if self.moduleDB.localPlayerCharacters.characters[characterGUID] then
                    entryFound = true
                    break
                end
            end
        end
        if entryFound then
            charactersData.characters[GUID] = self.moduleDB.localPlayerCharacters.characters[GUID]
            break
        end
    end
    if not entryFound then
        tinsert(self.moduleDB.guildPlayerCharacters, self.moduleDB.localPlayerCharacters)
    end
end

--- Lookup of character GUID to the WCCCAD_CharacterData table they appear in.
---@type table<string, WCCCAD_CharacterData>
WCCCAD.guildPlayerCharactersLookup = {}

---
--- Consolidates guild player character tables from moduleDB and creates a lookup mapping GUIDs to the character table they appear in.
--- Then removes orphaned tables from moduleDB to remove duplicate entries.
---
function WCCCADCore:BuildPlayerCharactersLookup()
    WCCCAD.guildPlayerCharactersLookup = {}
    local existingCharactersData = nil
    for i, charactersData in ipairs(self.moduleDB.guildPlayerCharacters) do
        for GUID, character in pairs(charactersData.characters) do
            existingCharactersData = WCCCAD.guildPlayerCharactersLookup[GUID]
            if existingCharactersData then
                -- If there's already an entry, take the latest.
                if character.lastUpdateTimestamp > existingCharactersData.characters[GUID].lastUpdateTimestamp then
                    existingCharactersData.characters[GUID] = character
                    if (charactersData.mainUpdateTimestamp or 0) > (existingCharactersData.mainUpdateTimestamp or 0) then
                        existingCharactersData.main = charactersData.main
                        existingCharactersData.mainUpdateTimestamp = charactersData.mainUpdateTimestamp
                    end
                end
                -- As we already have a table for this character, this is a duplicate entry so delete it.
                charactersData.characters[GUID] = nil
            else
                WCCCAD.guildPlayerCharactersLookup[GUID] = charactersData
            end
            -- If this is a character in our local data, insert the rest.
            if self.moduleDB.localPlayerCharacters.characters[GUID] then
                for localGUID, localCharacter in pairs(self.moduleDB.localPlayerCharacters.characters) do
                    WCCCAD.guildPlayerCharactersLookup[localGUID] = charactersData
                    if not charactersData.characters[localGUID] or localCharacter.lastUpdateTimestamp > charactersData.characters[localGUID].lastUpdateTimestamp then
                        charactersData.characters[localGUID] = localCharacter
                    end
                end
                if (self.moduleDB.localPlayerCharacters.mainUpdateTimestamp or 0) > (charactersData.mainUpdateTimestamp or 0) then
                    charactersData.main = self.moduleDB.localPlayerCharacters.main
                    charactersData.mainUpdateTimestamp = self.moduleDB.localPlayerCharacters.mainUpdateTimestamp
                end
            end
        end
    end
    -- Remove orphaned tables post-consolidation.
    for i = #self.moduleDB.guildPlayerCharacters, 1, -1 do
        local remove = true
        for _, charactersData in pairs(WCCCAD.guildPlayerCharactersLookup) do
            if self.moduleDB.guildPlayerCharacters[i] == charactersData then
                remove = false
            end
        end
        if remove then
            table.remove(self.moduleDB.guildPlayerCharacters, i)
        end
    end
end

---
--- Merges guild player character data received from other players with our data.
---
function WCCCADCore:OnGuildPlayerCharactersDataReceived(otherGuildPlayerCharacters)
    for _, otherCharactersData in ipairs(otherGuildPlayerCharacters) do
        -- Find table in our data that has a matching character.
        local tableFound = false
        for searchCharacterGUID, _ in pairs(otherCharactersData.characters) do
            local localTable = WCCCAD.guildPlayerCharactersLookup[searchCharacterGUID]
            if localTable then
                tableFound = true
                -- Update main
                if (otherCharactersData.mainUpdateTimestamp or 0) > (localTable.mainUpdateTimestamp or 0) then
                    localTable.main = otherCharactersData.main
                    localTable.mainUpdateTimestamp = otherCharactersData.mainUpdateTimestamp
                end
                -- Update/insert each character
                for otherCharacterGUID, otherCharacter in pairs(otherCharactersData.characters) do
                    WCCCAD.guildPlayerCharactersLookup[otherCharacterGUID] = localTable
                    if not localTable.characters[otherCharacterGUID] or otherCharacter.lastUpdateTimestamp > localTable.characters[otherCharacterGUID].lastUpdateTimestamp then
                        localTable.characters[otherCharacterGUID] = otherCharacter
                    end
                end
                -- Onto the next set of characters as all of these have been processed above.
                break
            end
        end
        -- If no existing table was found for this set of characters, insert it as new.
        if not tableFound then
            tinsert(self.moduleDB.guildPlayerCharacters, otherCharactersData)
            self:BuildPlayerCharactersLookup()
        end
    end
    -- Reconsolidate tables and rebuild the lookup.
    self:BuildPlayerCharactersLookup()
end

---
--- Updates which character the local player owns is set as main.
---
function WCCCADCore:SetPlayerCharacterMain(mainGUID)
    assert(WCCCAD.guildPlayerCharactersLookup[mainGUID] ~= nil, "WCCC: Tried to set main to an unregistered character.")
    local timestamp = GetServerTime()
    WCCCAD.guildPlayerCharactersLookup[mainGUID].main = mainGUID
    WCCCAD.guildPlayerCharactersLookup[mainGUID].mainUpdateTimestamp = timestamp
    self.moduleDB.localPlayerCharacters.main = mainGUID
    self.moduleDB.localPlayerCharacters.mainUpdateTimestamp = timestamp
    data =
    {
        mainGUID = mainGUID,
        mainUpdateTimestamp = timestamp
    }
    self:SendModuleComm(COMM_KEY_PLAYER_MAIN_UPDATED, data, ns.consts.CHAT_CHANNEL.GUILD)
end

function WCCCADCore:OnPlayerMainUpdated(data)
    self:PrintDebugMessage(format("Guildy updated main to %s", WCCCAD.guildPlayerCharactersLookup[data.mainGUID].characters[data.mainGUID].name))
    WCCCAD.guildPlayerCharactersLookup[data.mainGUID].main = data.mainGUID
    WCCCAD.guildPlayerCharactersLookup[data.mainGUID].mainUpdateTimestamp = data.mainUpdateTimestamp
end
--endregion

function WCCCADCore:UpdateGuildRosterAddonIndicators() 
    if CommunitiesFrame == nil then
        return
    end

    for _, guildieButton in ipairs(CommunitiesFrame.MemberList.ScrollBox:GetFrames()) do
        local memberInfo = guildieButton:GetMemberInfo()

        if memberInfo == nil or self.knownAddonUsers[memberInfo.guid] == nil then
            if guildieButton.addonIndicator ~= nil then
                guildieButton.addonIndicator:Hide()
            end
        else
            if guildieButton.addonIndicator ~= nil then
                guildieButton.addonIndicator:Show()
            else
                guildieButton.addonIndicator = CreateFrame("Button", nil, guildieButton)
                guildieButton.addonIndicator:SetNormalTexture("Interface\\AddOns\\WCCCAddOn\\assets\\wccc-logo.tga")
                guildieButton.addonIndicator:SetPoint("RIGHT", -10, 0)
                guildieButton.addonIndicator:SetWidth(12)
                guildieButton.addonIndicator:SetHeight(12)
                guildieButton.addonIndicator:Show()
            end
        end
    end
end

function WCCCADCore:ShowFTUEWindow()
    self.moduleDB.firstTimeUser = false

    local AceGUI = LibStub("AceGUI-3.0")

    local ftueFrame = AceGUI:Create("Frame")
    ftueFrame:SetTitle("Welcome!")
    ftueFrame:SetLayout("Flow")
    ftueFrame:SetWidth(540)
    ftueFrame:SetHeight(300)

    local wcccLogo = AceGUI:Create("Label")
    wcccLogo:SetImage("Interface\\AddOns\\WCCCAddOn\\assets\\wccc-header.tga")
    wcccLogo:SetImageSize(512, 128)
    wcccLogo:SetWidth(512)
    ftueFrame:AddChild(wcccLogo)

    local welcomeText = AceGUI:Create("Label")
    welcomeText:SetWidth(450)
    welcomeText:SetText("Welcome to the official AddOn of the <Worgen Cub Clubbing Club>.\
Participate in the Clubbing Competition, view guild keystones, compete in dragon races and view event information on the Info HUD!\
\
Use the 'WCCC Companion' button on the WoW main menu (press Escape) or type '/wccc' to access the main UI window with instructions on using the AddOn.\
\
Happy Clubbing!")
    ftueFrame:AddChild(welcomeText)
end

---
--- Version Command
---
local lastVerTimestamp = 0
local verSendDelay = 20
function WCCCADCore:VersionCommand()
    if GetServerTime() < lastVerTimestamp + verSendDelay then
        WCCCAD.UI:PrintAddOnMessage("Please wait a short time before sending another version request.", ns.consts.MSG_TYPE.WARN)
        return
    end

    lastVerTimestamp = GetServerTime()
    self:SendRequestVersionComm()
end

function WCCCADCore:SendRequestVersionComm()
    local data = 
    {
        requestingPlayer = ns.utils.GetPlayerNameRealmString()
    }

    self:PrintDebugMessage("Sending version request")
    WCCCAD.UI:PrintAddOnMessage(format("Your version: v%s - %s", WCCCAD.versionString, WCCCAD.versionType.name))
    self:SendModuleComm(COMM_KEY_SHARE_VERSION, data, ns.consts.CHAT_CHANNEL.GUILD)
end

function WCCCADCore:OnShareVersionCommReceived(data)
    if data.requestingPlayer ~= nil then
        -- We've received a request.
        self:PrintDebugMessage("Received version request from " .. data.requestingPlayer)
        local responseData = 
        {
            respondingPlayer = ns.utils.GetPlayerNameRealmString(),
            version = WCCCAD.version,
            versionString = WCCCAD.versionString,
            versionType = WCCCAD.versionType
        }
        self:SendModuleComm(COMM_KEY_SHARE_VERSION, responseData, ns.consts.CHAT_CHANNEL.WHISPER, data.requestingPlayer)

    elseif data.respondingPlayer ~= nil then
        --region compatibility <= v1.0.21
        if not data.versionType then
            data.versionType = ns.consts.VERSION_TYPE.RELEASE
        end
        --endregion

        -- It's a response to a request we made.
        self:PrintDebugMessage("Received version response from " .. data.respondingPlayer)
        local versionOutput = "v"..data.versionString.." - "..data.versionType.name
        if data.version < WCCCAD.version then
            versionOutput =  "|cFFE91100"..versionOutput.."|r (out of date)"
        elseif data.version > WCCCAD.version then
            versionOutput =  "|cFF00D42D"..versionOutput.."|r (newer version)"
            WCCCAD.newVersionAvailable = true
        end
        WCCCAD.UI:PrintAddOnMessage(format("%s - %s", data.respondingPlayer, versionOutput))
    end
end

---
--- Sync functions
---
function WCCCADCore:GetSyncData()
    -- TODO: Consider adding GUID to base sync data (ModuleBase), same as player name.
    local syncData =
    {
        version = WCCCAD.version,
        versionString = WCCCAD.versionString,
        versionType = WCCCAD.versionType,
        playerGuid = UnitGUID("player"),
        guildPlayerCharacters = self.moduleDB.guildPlayerCharacters
    }

    return syncData
end

function WCCCADCore:CompareSyncData()
    -- We want to force the initial sync between users so player GUIDs are up-to-date.
    return ns.consts.DATA_SYNC_RESULT.BOTH_NEWER
end

function WCCCADCore:OnSyncDataReceived(data)
    --region compatibility <= v1.0.21
    if not data.versionType then
        data.versionType = ns.consts.VERSION_TYPE.RELEASE
    end
    --endregion

    if ((data.version > WCCCAD.version and data.versionType.value >= WCCCAD.versionType.value)
            or (data.version == WCCCAD.version and data.versionType.value > WCCCAD.versionType.value))
        and WCCCAD.newVersionAvailable == false 
    then
        WCCCAD.UI:PrintAddOnMessage(format("A new version (%s - %s) of the WCCC Clubbing Companion is available, please update.", data.versionString, data.versionType.name), ns.consts.MSG_TYPE.WARN)
        WCCCAD.newVersionAvailable = true
    end

    self.knownAddonUsers[data.playerGuid] = data.playerGuid
    self:UpdateGuildRosterAddonIndicators()

    -- Alts
    -- Don't sync alt data from anyone who has a version before the last wipe.
    if data.version >= self.charactersDataWipeVersion then
        self:OnGuildPlayerCharactersDataReceived(data.guildPlayerCharacters)
    end
end