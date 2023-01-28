--
-- Part of the Worgen Cub Clubbing Club Official AddOn
-- Author: Aerthok - Defias Brotherhood EU
--
local _, ns = ...
local WCCCAD = ns.WCCCAD
local DRL = WCCCAD:GetModule("WCCC_DragonRacingLeaderboards")
DRL.LeaderboardUI = {}
DRL.LeaderboardUI.selectedRaceID = nil

function DRL.LeaderboardUI:Show()
    DRL_LEADERBOARD_UI_FRAME:Show()
end

---
--- Select the race to be shown on the UI. If nil, the overall leaderboard will be shown.
--- UI is refreshed automatically as part of this function.
---
function DRL.LeaderboardUI:SelectRace(raceID)
    if raceID ~= nil then
        local raceData = DRL.races[raceID]
        if raceData == nil then
            self:PrintDebugMessage(format("No race found with ID '%s'", raceID))
            return
        end
    end
    DRL.LeaderboardUI.selectedRaceID = raceID
    -- Update display
    if DRL_LEADERBOARD_UI_FRAME:IsVisible() then
        -- Toggle map pin button.
        DRL_LEADERBOARD_UI_FRAME.CreateMapPinBtn:SetShown(DRL.LeaderboardUI.selectedRaceID ~= nil)
        -- Set description text.
        local descriptionTextKey = DRL.LeaderboardUI.selectedRaceID == nil and "OVERALL_LEADERBOARD_INFO_DESC" or "LEADERBOARD_INFO_DESC"
        DRL_LEADERBOARD_UI_FRAME.LeaderboardInfoContainer.DescText:SetText(DRL.Locale[descriptionTextKey])
        -- Refresh sub-UIs.
        DRL_LEADERBOARD_UI_FRAME.RaceListFrame:Refresh()
        DRL_LEADERBOARD_UI_FRAME.LeaderboardFrame:Refresh()
    end
end

function DRL.LeaderboardUI:OnLeaderboardDataUpdated()
    if DRL_LEADERBOARD_UI_FRAME:IsVisible() then
        DRL_LEADERBOARD_UI_FRAME.RaceListFrame:Refresh()
        DRL_LEADERBOARD_UI_FRAME.LeaderboardFrame:Refresh()
    end
end


DRL_LeaderboardUIMixin = {}

function DRL_LeaderboardUIMixin:OnLoad()
    self.TitleContainer.TitleText:SetText("Dragon Racing Leaderboards")
    self:RegisterForDrag("LeftButton")
    tinsert(UISpecialFrames, self:GetName())

    -- Create map pin button
    self.CreateMapPinBtn:SetScript("OnClick", function()
        if not DRL.LeaderboardUI.selectedRaceID then return end
        local raceData = DRL.races[DRL.LeaderboardUI.selectedRaceID]
        if not C_Map.CanSetUserWaypointOnMap(raceData.zoneID) then
            self.UI:PrintAddOnMessage("Unable to create map pin.")
            return
        end
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(raceData.zoneID, raceData.coordX, raceData.coordY, 0))
        OpenWorldMap(raceData.zoneID)
    end)
end

function DRL_LeaderboardUIMixin:OnShow()
    DRL.LeaderboardUI:SelectRace(DRL.LeaderboardUI.selectedRaceID)
end