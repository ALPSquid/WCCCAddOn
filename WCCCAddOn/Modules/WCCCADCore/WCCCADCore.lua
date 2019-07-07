--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
-- Core AddOn module-style functionality not intended to be shared across modules.
local name, ns = ...
local WCCCAD = ns.WCCCAD

WCCCAD.version = 106
WCCCAD.versionString = "1.0.6"
WCCCAD.newVersionAvailable = false;


local wcccCoreData = 
{
    profile =
    {
        firstTimeUser = true
    }
}

local WCCCADCore = WCCCAD:CreateModule("WCCC_Core", wcccCoreData)


function WCCCADCore:InitializeModule()

end

function WCCCADCore:OnEnable()
    WCCCADCore:InitiateSync()

    if WCCCADCore.moduleDB.firstTimeUser == true then
        WCCCADCore:ShowFTUEWindow()
    end
end

function WCCCADCore:ShowFTUEWindow()
    WCCCADCore.moduleDB.firstTimeUser = false

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
Participate in the Clubbing Competition along with more features to come!\
\
Use the 'WCCC AddOn' button on the WoW main menu (press Escape) or type '/wccc' to access the main UI window with instructions on using the AddOn.\
\
Happy Clubbing!")
    ftueFrame:AddChild(welcomeText)
end


---
--- Sync functions
---
function WCCCADCore:GetSyncData() 
    local syncData =
    {
        version = WCCCAD.version,
        versionString = WCCCAD.versionString
    }

    return syncData
end

function WCCCADCore:CompareSyncData(remoteData)
    if remoteData.version > WCCCAD.version then
        return 1
    elseif remoteData.version == WCCCAD.version then
        return 0
    else 
        return -1
    end
end

function WCCCADCore:OnSyncDataReceived(data)
    if data.version > WCCCAD.version and WCCCAD.newVersionAvailable == false then
        WCCCAD.UI:PrintAddOnMessage(format("A new version (%s) of the WCCC AddOn is available, please update.", data.versionString), ns.consts.MSG_TYPE.WARN)
        newVersionAvailable = true
    end
end