--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD


---
--- Create a new module with some helper methods and a module database pre-configured (.moduleDB) which also contains a debugMode flag.
---
function WCCCAD:CreateModule(moduleName, dbDefaults)
    local wcccModule = WCCCAD:NewModule(moduleName) 

    function wcccModule.OnInitialize(moduleSelf)
        moduleSelf:CreateModuleDB()
        moduleSelf:InitializeModule()
    end

    function wcccModule.CreateModuleDB(moduleSelf) 
        moduleSelf.moduleDB = WCCCAD.db:RegisterNamespace(moduleName, dbDefaults).profile
        if moduleSelf.moduleDB.debugMode == nil then
            moduleSelf.moduleDB.debugMode = false
        end

        moduleSelf:RegisterModuleComm("sync", moduleSelf._OnSyncReceivedComm)
    end

    function wcccModule.RegisterModuleSlashCommand(moduleSelf, command, func)
        WCCCAD:RegisterModuleSlashCommand(moduleSelf, command, func)
    end

    function wcccModule.RegisterModuleComm(moduleSelf, messageKey, func)
        WCCCAD:RegisterModuleComm(moduleSelf, moduleName, messageKey, func)
    end

    -- @param targetplayer only used for whisper channel.
    function wcccModule.SendModuleComm(moduleSelf, messageKey, data, channel, targetPlayer)
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
    function wcccModule.InitiateSync(moduleSelf)
        wcccModule:_SendSyncComm()
    end

    --- Send out data to all guild clients without getting a reply.
    function wcccModule.BroadcastSyncData(moduleSelf) 
        moduleSelf:_SendSyncComm(nil, false)
    end

    --- @param targetPlayer  player to send comm to, or guild if null.
    --- @param expectResponse  whether we want a reply if this was a broadcast (no targetPlayer). Defaults to true.
    --- @param testData  optional test data to send instead of calling GetSyncData
    function wcccModule._SendSyncComm(moduleSelf, targetPlayer, expectResponse, testData)
        if expectResponse == nil then
            expectResponse = true
        end 

        if testData ~= nil then
            testData.isTestData = true
        end

        local data = testData or moduleSelf:GetSyncData()
        data.sendingPlayer = ns.utils.GetPlayerNameRealmString()
        data.targetPlayer = targetPlayer
        data.expectResponse = expectResponse

        if targetPlayer ~= nil then
            WCCCAD.UI:PrintDebugMessage("Sending "..moduleName.." sync data to "..targetPlayer, moduleSelf.moduleDB.debugMode)
            moduleSelf:SendModuleComm("sync", data, ns.consts.CHAT_CHANNEL.WHISPER, targetPlayer)
        else
            WCCCAD.UI:PrintDebugMessage("Performing "..moduleName.." sync broadcast", moduleSelf.moduleDB.debugMode)
            moduleSelf:SendModuleComm("sync", data, ns.consts.CHAT_CHANNEL.GUILD)
        end
    end

    function wcccModule._OnSyncReceivedComm(moduleSelf, data)
        if data.sendingPlayer == ns.utils.GetPlayerNameRealmString() and data.isTestData ~= true then
            return 
        end
        WCCCAD.UI:PrintDebugMessage("Received "..moduleName.." sync data from ", wcccModule.moduleDB.debugMode)

        local dataComparisonResult = moduleSelf:CompareSyncData(data)

        WCCCAD.UI:PrintDebugMessage("Received "..moduleName.." sync data from "..data.sendingPlayer..". Data comparison: "..dataComparisonResult, moduleSelf.moduleDB.debugMode)
        if dataComparisonResult == ns.consts.DATA_SYNC_RESULT.REMOTE_NEWER or dataComparisonResult == ns.consts.DATA_SYNC_RESULT.BOTH_NEWER then
            moduleSelf:OnSyncDataReceived(data)
        end

        --- If targetplayer is null, this was a broadcast from a player and needs a reply (assuming we have newer data)
        --- If it's not, the message was sent directly to us.
        if data.targetPlayer == nil 
            and data.expectResponse == true 
            and (dataComparisonResult == ns.consts.DATA_SYNC_RESULT.LOCAL_NEWER or dataComparisonResult == ns.consts.DATA_SYNC_RESULT.BOTH_NEWER) 
        then
            moduleSelf:_SendSyncComm(data.sendingPlayer, false)    
        end
    end

    ---
    --- Returns a single sync result for multiple sync result inputs. Useful for modules with different data chunks with different sync results.
    ---
    function wcccModule.GetTotalSyncResult(moduleSelf, ...)
        local results = {
            [ns.consts.DATA_SYNC_RESULT.LOCAL_NEWER] = 0,
            [ns.consts.DATA_SYNC_RESULT.EQUAL] = 0,
            [ns.consts.DATA_SYNC_RESULT.REMOTE_NEWER] = 0,
            [ns.consts.DATA_SYNC_RESULT.BOTH_NEWER] = 0,
        }

        for _, syncResult in ipairs{...} do
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

    function wcccModule.SendSelfDebugComm(moduleSelf, testData)
        moduleSelf:_SendSyncComm(ns.utils.GetPlayerNameRealmString(), false, testData)
    end

    return wcccModule
end
