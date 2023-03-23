--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD
local DRL = WCCCAD:GetModule("WCCC_DragonRacingLeaderboards")

--region Leaderboard entry row
DRL_LeaderboardRowMixin = CreateFromMixins(TableBuilderRowMixin)

function DRL_LeaderboardRowMixin:Init(index)
    -- Alternate background alpha
    self.backgroundTexture:SetAlpha(index % 2 == 1 and 0.9 or 0.7)
end
--endregion

--region Leaderboard column header
DRL_LeaderboardHeaderMixin = CreateFromMixins(TableBuilderElementMixin)

function DRL_LeaderboardHeaderMixin:Init(title, textAlignment)
    self.text:SetText(title)
    self.text:SetJustifyH(textAlignment)
end
--endregion

--region Leaderboard data cell
DRL_LeaderboardCellMixin = CreateFromMixins(TableBuilderCellMixin)

function DRL_LeaderboardCellMixin:Init(dataProviderKey, textAlignment, scrollBox)
    self.scrollBox = scrollBox
     -- dataProviderKey is the key for the data to display in this cell.
    self.dataProviderKey = dataProviderKey
    self.text:SetJustifyH(textAlignment)
end

function DRL_LeaderboardCellMixin:Populate(rowData, dataIndex)
    local rank = self.scrollBox:FindIndex(rowData)
    if self.dataProviderKey == "rank" then
        self.text:SetText(rank)
    else
        self.text:SetText(rowData[self.dataProviderKey])
    end
    local colour = CreateColor(1, 1, 1)
    if rank == 1 then colour = CreateColor(0.94, 0.91, 0.16)
    elseif rank == 2 then colour = CreateColor(0.66, 0.78, 0.80)
    elseif rank == 3 then colour = CreateColor(0.78, 0.60, 0.30) end
    self.text:SetTextColor(colour.r, colour.g, colour.b)
end
--endregion

--region Leaderboard scroll list
DRL_LeaderboardListMixin = {}

function DRL_LeaderboardListMixin:OnLoad()
    local view = CreateScrollBoxListLinearView()
    view:SetElementInitializer("DRL_LeaderboardRowTemplate", function(button, elementData)
        button:Init(self.Container.ScrollBox:FindIndex(elementData))
    end)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.Container.ScrollBox, self.Container.ScrollBar, view)

    self.tableBuilder = CreateTableBuilder()
    self.tableBuilder:SetHeaderContainer(self.Container.ScrollBoxHeader)

    local column = self.tableBuilder:AddColumn()
    column:ConstructHeader("FRAME", "DRL_LeaderboardHeaderTemplate", "Rank", "LEFT")
    column:ConstructCells("FRAME", "DRL_LeaderboardCellTemplate", "rank", "LEFT", self.Container.ScrollBox)

    column = self.tableBuilder:AddColumn()
    column:ConstructHeader("FRAME", "DRL_LeaderboardHeaderTemplate", "Name", "LEFT")
    column:ConstructCells("FRAME", "DRL_LeaderboardCellTemplate", "playerName", "LEFT", self.Container.ScrollBox)

    column = self.tableBuilder:AddColumn()
    column:ConstructHeader("FRAME", "DRL_LeaderboardHeaderTemplate", "Time", "RIGHT")
    column:ConstructCells("FRAME", "DRL_LeaderboardCellTemplate", "time", "RIGHT", self.Container.ScrollBox)

    self.tableBuilder:Arrange()
    local function ElementDataTranslator(elementData)
        return elementData
    end
    self.tableBuilder:SetDataProvider(ElementDataTranslator)
    ScrollUtil.RegisterTableBuilder(self.Container.ScrollBox, self.tableBuilder, ElementDataTranslator)
end

function DRL_LeaderboardListMixin:OnShow()
    self:Refresh()
end

---
--- Refreshes the leaderboard list to display up-to-date data for the selected race or overall leaderboard if no race is selected.
---
function DRL_LeaderboardListMixin:Refresh()
    if not self:IsVisible() then return end
    if DRL.LeaderboardUI.selectedRaceID ~= nil and DRL.races[DRL.LeaderboardUI.selectedRaceID] == nil then
        self.Container.Spinner:Show()
        return
    end
    local leaderboardTitle = DRL.LeaderboardUI.selectedRaceID and DRL:GetRaceName(DRL.LeaderboardUI.selectedRaceID) or "Overall Leaderboard"
    self.Title:SetText(leaderboardTitle)
    self.Container.Spinner:Hide()

    -- Sort entries by time then achieved timestamp.
    local function SortComparator(a, b)
        if a.time == b.time then
            return a.achievedTimestamp < b.achievedTimestamp
        end
        return a.time < b.time
    end

    -- Build leaderboard data array.
    local leaderboard = {}
    if DRL.LeaderboardUI.selectedRaceID then
        -- Leaderboard for a specific race
        local processedMains = {}
        for _, leaderboardEntry in pairs(DRL:GetRaceLeaderboardData(DRL.LeaderboardUI.selectedRaceID)) do
            local playerMainData = WCCCAD:GetPlayerMain(leaderboardEntry.GUID)
            if not playerMainData then
                playerMainData = {
                    GUID = leaderboardEntry.GUID,
                    name = leaderboardEntry.playerName
                }
            end
            if not processedMains[playerMainData.GUID] then
                processedMains[playerMainData.GUID] = true
                local accountBest = DRL:GetPlayerAccountBest(playerMainData.GUID, DRL.LeaderboardUI.selectedRaceID)
                if accountBest ~= nil and accountBest.time > 0 then
                    tinsert(leaderboard, accountBest)
                end
            end
        end
    else
        -- Overall leaderboard using sum of player's times across all races.
        -- Look up of a player's GUID to the index of their entry in the overall leaderboard.
        local leaderboardGUIDIdx = {}
        local entryIdx = nil
        local numRaces = 0
        for raceID in pairs(DRL.races) do
            numRaces = numRaces + 1
            local processedMains = {}
            for _, leaderboardEntry in pairs(DRL:GetRaceLeaderboardData(raceID)) do
                local playerMainData = WCCCAD:GetPlayerMain(leaderboardEntry.GUID)
                if not playerMainData then
                    playerMainData = {
                        GUID = leaderboardEntry.GUID,
                        name = leaderboardEntry.playerName
                    }
                end
                if not processedMains[playerMainData.GUID] then
                    entryIdx = leaderboardGUIDIdx[playerMainData.GUID]
                    processedMains[playerMainData.GUID] = true
                    if not entryIdx then
                        tinsert(leaderboard, {
                            GUID = playerMainData.GUID,
                            playerName = playerMainData.name,
                            time = 0,
                            achievedTimestamp = 0,
                            numRacesLogged = 0
                        })
                        entryIdx = #leaderboard
                        leaderboardGUIDIdx[playerMainData.GUID] = entryIdx
                    end
                    local accountBest = DRL:GetPlayerAccountBest(playerMainData.GUID, raceID)
                    if accountBest.time > 0 then
                        leaderboard[entryIdx].time = leaderboard[entryIdx].time + accountBest.time
                        -- Lower achieved timestamp is used as the tie-breaker.
                        leaderboard[entryIdx].achievedTimestamp = leaderboard[entryIdx].achievedTimestamp + accountBest.achievedTimestamp
                        leaderboard[entryIdx].numRacesLogged = leaderboard[entryIdx].numRacesLogged + 1
                    end
                end
            end
        end
        -- Add default times of 5 mins for each skipped race.
        for _, leaderboardEntry in pairs(leaderboard) do
            if leaderboardEntry.numRacesLogged < numRaces then
                leaderboardEntry.time = leaderboardEntry.time + (300 * (numRaces - leaderboardEntry.numRacesLogged))
            end
        end
    end

    local dataProvider = CreateDataProvider()
    dataProvider:Init(leaderboard)
    local skipSort = false
    dataProvider:SetSortComparator(SortComparator, skipSort)
    self.Container.ScrollBox:SetDataProvider(dataProvider)
end
--endregion