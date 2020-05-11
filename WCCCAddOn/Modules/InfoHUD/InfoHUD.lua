--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD

local infoHUDData = 
{
    profile =
    {   
        hudData = 
        {
            shown = true,
            autoShow = true,
            autoResize = true,
            enableScroll = true,

            point = "CENTER",
            offsetX = 0,
            offsetY = 0,
            width = 300,
            height = 300,
        },

        activeMessages = 
        {
            -- [frame_name] = { content = "content", updateTime = 0}
        },

        savedMessages = 
        {
            -- [message_key] = { name = "Message Name", content = "Message Content"}
            [0] = { 
                name = "Special Formatting Example",
                content = "\
Colours (spaces have been added to aid reading but aren't required)\
||cred red text! ||r\
||credred text, no spaces!||r\
||cblue blue text! ||r\
||cgreen green text! ||r\
||cyellow yellow text! ||r\
||corange orange text! ||r\
\
Raid marks\
{star}, {circle}, {diamond}, {triangle}, {moon}, {square}, {cross}, {x}, {skull}\
\
Spells\
{bl}\
\
Roles\
{tank}, {healer}, {dps}\
{melee}, {ranged}\
\
Classes\
{deathknight}, {demonhunter}, {druid}, {hunter}, {mage}, {monk}, {paladin}, {priest}, {rogue}, {shaman}, {warlock}, {warrior}"
            }
        },
    }
}

local InfoHUD = WCCCAD:CreateModule("WCCC_InfoHUD", infoHUDData)

function InfoHUD:InitializeModule()
    self:RegisterModuleSlashCommand("infohud", self.InfoHUDCommand)
    self:PrintDebugMessage("Info HUD module loaded.")
end

function InfoHUD:OnEnable()
    self:InitiateSync()

    self.UI:RestoreHUDShownState()
    self:UpdateHUDMessages()
end

function InfoHUD:InfoHUDCommand(args)
    if args ~= nil and args[1] ~= nil then
        if args[1] == "toggle" then
            self.UI:ToggleHUD()
        end
        return 
    end

    self.UI:Show()
end

function InfoHUD:OC_SetMessage(messageTab, messageContent)
    if WCCCAD:IsPlayerOfficer() == false then
        return
    end

    self.moduleDB.activeMessages[messageTab] = 
    {
        content = messageContent,
        updateTime = GetServerTime()
    }

    self:BroadcastSyncData()
    self:UpdateHUDMessages()
end

---
--- Update the UI to match the data on disk or new message data if supplied
---
function InfoHUD:UpdateHUDMessages(newMessageData) 
    local lastUpdatedFrame = nil
    local lastUpdatedFrameTime = 0

    --- Update local data.
    if newMessageData ~= nil then 
        for frameName, messageData in pairs(newMessageData.activeMessages) do
            local localMessageData = self.moduleDB.activeMessages[frameName]
            if localMessageData == nil or messageData.updateTime > localMessageData.updateTime then
                self.moduleDB.activeMessages[frameName] = messageData
            end
        end
    end

    --- Update UI to show latest messages and switch to the newest tab.
    for frameName, messageData in pairs(self.moduleDB.activeMessages) do
        if messageData.content == nil then
            self.UI.hudFrame:HideTab(frameName)
        else
            self.UI.hudFrame:SetTabMessage(frameName, messageData.content)

            if messageData.updateTime > lastUpdatedFrameTime then
                lastUpdatedFrameTime = messageData.updateTime
                lastUpdatedFrame = frameName
            end
        end
    end

    if lastUpdatedFrame ~= nil then
        self.UI.hudFrame:SwitchTab(lastUpdatedFrame)
        if newMessageData ~= nil and not self.UI.hudFrame:IsShown() then
            if lastUpdatedFrame ~= "guild" or not self.moduleDB.hudData.autoShow then
                WCCCAD.UI:PrintAddOnMessage("Info HUD message updated, use '/wccc infohud' to open.")
            elseif self.moduleDB.hudData.autoShow and lastUpdatedFrame == "guild" then
                self.UI:SetHUDShown(true)
            end
        end
    end
end

---
--- Sync Data
---
function InfoHUD:GetSyncData() 
    local syncData =
    {
        activeMessages = self.moduleDB.activeMessages
    }

    return syncData
end

function InfoHUD:CompareSyncData(remoteData)
    local numLocalNewer = 0
    local numEqual = 0
    local numRemoteNewer = 0

    for frameName, messageData in pairs(remoteData.activeMessages) do
        local localMessageData = self.moduleDB.activeMessages[frameName]
        if localMessageData == nil then
            numRemoteNewer = numRemoteNewer + 1
        else 
            if messageData.updateTime < localMessageData.updateTime then
                numLocalNewer = numLocalNewer + 1

            elseif messageData.updateTime == localMessageData.updateTime then
                numEqual = numEqual + 1

            elseif messageData.updateTime > localMessageData.updateTime then
                numRemoteNewer = numRemoteNewer + 1
            end
        end
    end

    if numRemoteNewer > 0 and numLocalNewer > 0 then
        return ns.consts.DATA_SYNC_RESULT.BOTH_NEWER

    elseif numRemoteNewer > 0 then
        return ns.consts.DATA_SYNC_RESULT.REMOTE_NEWER

    elseif numLocalNewer > 0 then
        return ns.consts.DATA_SYNC_RESULT.LOCAL_NEWER
    end

    return ns.consts.DATA_SYNC_RESULT.EQUAL
end

function InfoHUD:OnSyncDataReceived(data)
    self:UpdateHUDMessages(data)
end