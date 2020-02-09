--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local name, ns = ...
local WCCCAD = ns.WCCCAD

---
--- Create a new module with some helper methods and a module database pre-configured (.moduleDB) which also contains a debugMode flag.
---
function WCCCAD:CreateModule(moduleName, dbDefaults)
    local wcccModule = WCCCAD:NewModule(moduleName) 

    wcccModule.OnInitialize = function(self)
        wcccModule:CreateModuleDB()
        wcccModule:InitializeModule()
    end
    
    wcccModule.CreateModuleDB = function(self) 
        wcccModule.moduleDB = WCCCAD.db:RegisterNamespace(moduleName, dbDefaults).profile
        if wcccModule.moduleDB.debugMode == nil then
            wcccModule.moduleDB.debugMode = false
        end

        wcccModule:RegisterModuleComm("sync", wcccModule._OnSyncReceivedComm)
    end

    wcccModule.RegisterModuleSlashCommand = function(self, command, func)
        WCCCAD:RegisterModuleSlashCommand(wcccModule, command, func)
    end

    wcccModule.RegisterModuleComm = function(self, messageKey, func)
        WCCCAD:RegisterModuleComm(self, moduleName, messageKey, func)
    end

    -- @param targetplayer only used for whisper channel.
    wcccModule.SendModuleComm = function(self, messageKey, data, channel, targetPlayer)
        WCCCAD:SendModuleComm(moduleName, messageKey, data, channel, targetPlayer)
    end


    --- Sync functionality.
    --- To request a sync or send updated data, use InitiateSync. 
    --- If a sync is received from a client, a response with data is sent back. Use BroadcastSyncData to send out data without wanting a reply (same functionality, but less traffic).
    ---  GetSyncData()  should return a table of data to send to other clients.
    ---  CompareSyncData(remoteData)  compare received data with local data. Return type of ns.consts.DATA_SYNC_RESULT. 
    ---                               GetTotalSyncResult can be used to calculate a final value when multiple sync results from data chunks are required.
    ---  OnSyncDataReceived(data)  will be called when newer data is received from other clients.

    --- Send a sync request to the guild. This will send our data to all guild clients and request a reply with updated data.
    wcccModule.InitiateSync = function(self)
        wcccModule:_SendSyncComm()
    end

    --- Send out data to all guild clients without getting a reply.
    wcccModule.BroadcastSyncData = function(self) 
        wcccModule:_SendSyncComm(nil, false)
    end
   
    --- @param targetPlayer  player to send comm to, or guild if null.
    --- @param expectResponse  whether we want a reply if this was a broadcast (no targetPlayer). Defaults to true.
    --- @param testData  optional test data to send instead of calling GetSyncData
    wcccModule._SendSyncComm = function(self, targetPlayer, expectResponse, testData)
        if expectResponse == nil then
            expectResponse = true
        end 

        if testData ~= nil then
            testData.isTestData = true
        end

        local data = testData or wcccModule:GetSyncData()
        data.sendingPlayer = ns.utils.GetPlayerNameRealmString()
        data.targetPlayer = targetPlayer
        data.expectResponse = expectResponse

        if targetPlayer ~= nil then
            WCCCAD.UI:PrintDebugMessage("Sending "..moduleName.." sync data to "..targetPlayer, wcccModule.moduleDB.debugMode)        
            wcccModule:SendModuleComm("sync", data, ns.consts.CHAT_CHANNEL.WHISPER, targetPlayer)
        else
            WCCCAD.UI:PrintDebugMessage("Performing "..moduleName.." sync broadcast", wcccModule.moduleDB.debugMode)        
            wcccModule:SendModuleComm("sync", data, ns.consts.CHAT_CHANNEL.GUILD)
        end
    end

    wcccModule._OnSyncReceivedComm = function(self, data)
        if data.sendingPlayer == ns.utils.GetPlayerNameRealmString() and data.isTestData ~= true then
            return 
        end
        WCCCAD.UI:PrintDebugMessage("Received "..moduleName.." sync data from ", wcccModule.moduleDB.debugMode)
            
        local dataComparisonResult = wcccModule:CompareSyncData(data)

        WCCCAD.UI:PrintDebugMessage("Received "..moduleName.." sync data from "..data.sendingPlayer..". Data comparison: "..dataComparisonResult, wcccModule.moduleDB.debugMode)
        if dataComparisonResult == ns.consts.DATA_SYNC_RESULT.REMOTE_NEWER or dataComparisonResult == ns.consts.DATA_SYNC_RESULT.BOTH_NEWER then
            wcccModule:OnSyncDataReceived(data)
        end

        --- If targetplayer is null, this was a broadcast from a player and needs a reply (assuming we have newer data)
        --- If it's not, the message was sent directly to us.
        if data.targetPlayer == nil 
            and data.expectResponse == true 
            and (dataComparisonResult == ns.consts.DATA_SYNC_RESULT.LOCAL_NEWER or dataComparisonResult == ns.consts.DATA_SYNC_RESULT.BOTH_NEWER) 
        then
            wcccModule:_SendSyncComm(data.sendingPlayer, false)    
        end
    end

    ---
    --- Returns a single sync result for multiple sync result inputs. Useful for modules with different data chunks with different sync results.
    ---
    wcccModule.GetTotalSyncResult = function(self, ...)
        local results = {
            [ns.consts.DATA_SYNC_RESULT.LOCAL_NEWER] = 0,
            [ns.consts.DATA_SYNC_RESULT.EQUAL] = 0,
            [ns.consts.DATA_SYNC_RESULT.REMOTE_NEWER] = 0,
            [ns.consts.DATA_SYNC_RESULT.BOTH_NEWER] = 0,
        }

        for i, syncResult in ipairs{...} do
            results[syncResult] = results[syncResult] + 1
        end    

        -- If local and remote have new data, return both newer.
        if results[ns.consts.DATA_SYNC_RESULT.BOTH_NEWER] > 0 
            or (results[ns.consts.DATA_SYNC_RESULT.LOCAL_NEWER] > 0 and results[ns.consts.DATA_SYNC_RESULT.REMOTE_NEWER] > 0) 
        then
            return ns.consts.DATA_SYNC_RESULT.BOTH_NEWER
        end
        
        -- Otherwise, return whichever newer value we have, or equal otherwise.
        if results[ns.consts.DATA_SYNC_RESULT.REMOTE_NEWER] > 0 then
            return ns.consts.DATA_SYNC_RESULT.REMOTE_NEWER

        elseif results[ns.consts.DATA_SYNC_RESULT.LOCAL_NEWER] > 0 then
            return ns.consts.DATA_SYNC_RESULT.LOCAL_NEWER 

        else
            return ns.consts.DATA_SYNC_RESULT.EQUAL
        end
    end

    wcccModule.SendSelfDebugComm = function(self, testData)
        wcccModule:_SendSyncComm(ns.utils.GetPlayerNameRealmString(), false, testData)
    end
    
    return wcccModule
end
