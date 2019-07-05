--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
-- Core AddOn module-style functionality not intended to be shared across modules.
local name, ns = ...
local WCCCAD = ns.WCCCAD

WCCCAD.version = 101
WCCCAD.versionString = "1.0.1"
WCCCAD.newVersionAvailable = false;


local wcccCoreData = 
{
}

local WCCCADCore = WCCCAD:CreateModule("WCCC_Core", wcccCoreData)


function WCCCADCore:InitializeModule()

end

function WCCCADCore:OnEnable()
    WCCCADCore:InitiateSync()
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