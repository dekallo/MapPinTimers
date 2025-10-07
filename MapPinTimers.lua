-- globals
local C_Map, C_Navigation, C_SuperTrack, C_Timer = C_Map, C_Navigation, C_SuperTrack, C_Timer
local abs, floor, Round, CreateFrame, AbbreviateNumbers = abs, floor, Round, CreateFrame, AbbreviateNumbers
local SuperTrackedFrame, TIMER_MINUTES_DISPLAY, IN_GAME_NAVIGATION_RANGE = SuperTrackedFrame, TIMER_MINUTES_DISPLAY, IN_GAME_NAVIGATION_RANGE

-- set up event frame
local EventFrame = CreateFrame("Frame")
EventFrame:SetScript("OnEvent", function(self, event, ...)
	if self[event] then return self[event](self, event, ...) end
end)

function EventFrame:PLAYER_LOGIN(event)
	self:UnregisterEvent(event)
	-- set up and validate db
	if not MapPinTimersDB then
		MapPinTimersDB = {}
	end
	if type(MapPinTimersDB.fullAlpha) ~= "boolean" then
		MapPinTimersDB.fullAlpha = true
	end
	if type(MapPinTimersDB.showDestination) ~= "boolean" then
		MapPinTimersDB.showDestination = true
	end
	EventFrame:SUPER_TRACKING_CHANGED()
end
EventFrame:RegisterEvent("PLAYER_LOGIN")

-- anchor time text
SuperTrackedFrame.TimeText = SuperTrackedFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
SuperTrackedFrame.TimeText:SetJustifyV("TOP")
SuperTrackedFrame.TimeText:SetSize(0, 20)
SuperTrackedFrame.TimeText:SetPoint("TOP", SuperTrackedFrame.Icon, "BOTTOM", 0, -22)

-- anchor destination text
SuperTrackedFrame.DestinationText = SuperTrackedFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
SuperTrackedFrame.DestinationText:SetJustifyV("TOP")
SuperTrackedFrame.DestinationText:SetSize(0, 20)
SuperTrackedFrame.DestinationText:SetPoint("TOP", SuperTrackedFrame.Icon, "TOP", 0, 22)

-- auto-track new map pins
function EventFrame:USER_WAYPOINT_UPDATED()
	if C_Map.HasUserWaypoint() then
		C_Timer.After(0, function()
			C_SuperTrack.SetSuperTrackedUserWaypoint(true)
		end)
	end
end
EventFrame:RegisterEvent("USER_WAYPOINT_UPDATED")

-- update destination text
function EventFrame:SUPER_TRACKING_CHANGED()
	if not MapPinTimersDB.showDestination then
		SuperTrackedFrame.DestinationText:SetText("")
	elseif C_SuperTrack.IsSuperTrackingContent() then
		local pinType = C_SuperTrack.GetSuperTrackedContent() -- TODO 2nd return?
		if pinType == 0 then -- Enum.ContentTrackingType.Appearance
			SuperTrackedFrame.DestinationText:SetText("Content: Appearance")
		elseif pinType == 1 then -- Enum.ContentTrackingType.Mount
			SuperTrackedFrame.DestinationText:SetText("Content: Mount")
		elseif pinType == 2 then -- Enum.ContentTrackingType.Achievement
			SuperTrackedFrame.DestinationText:SetText("Content: Achievement")
		else
			SuperTrackedFrame.DestinationText:SetText("Content")
		end
	elseif C_SuperTrack.IsSuperTrackingCorpse() then
		SuperTrackedFrame.DestinationText:SetText("Corpse")
	elseif C_SuperTrack.IsSuperTrackingMapPin() then
		local pinType = C_SuperTrack.GetSuperTrackedMapPin() -- TODO 2nd return?
		if pinType == 0 then -- Enum.SuperTrackingMapPinType.AreaPOI
			SuperTrackedFrame.DestinationText:SetText("Map Pin: Area POI")
		elseif pinType == 1 then -- Enum.SuperTrackingMapPinType.QuestOffer
			SuperTrackedFrame.DestinationText:SetText("Map Pin: Quest Offer")
		elseif pinType == 2 then -- Enum.SuperTrackingMapPinType.TaxiNode
			SuperTrackedFrame.DestinationText:SetText("Map Pin: Taxi Node")
		elseif pinType == 3 then -- Enum.SuperTrackingMapPinType.DigSite
			SuperTrackedFrame.DestinationText:SetText("Map Pin: Dig Site")
		else
			SuperTrackedFrame.DestinationText:SetText("Map Pin")
		end
	elseif C_SuperTrack.IsSuperTrackingQuest() then
		local questID = C_SuperTrack.GetSuperTrackedQuestID()
		local questTitle = C_QuestLog.GetTitleForQuestID(questID)
		if questTitle then
			SuperTrackedFrame.DestinationText:SetText(questTitle)
		else
			SuperTrackedFrame.DestinationText:SetText("Quest")
		end
	elseif C_SuperTrack.IsSuperTrackingUserWaypoint() then
		SuperTrackedFrame.DestinationText:SetText("Waypoint")
	elseif C_SuperTrack.IsSuperTrackingAnything() then
		-- TODO what else? Vignette? Item?
		SuperTrackedFrame.DestinationText:SetText("Other")
	end
end
EventFrame:RegisterEvent("SUPER_TRACKING_CHANGED")

-- override frame alpha to full opacity so the timer is useful
do
	local oldAlpha = SuperTrackedFrame.GetTargetAlphaBaseValue
	function SuperTrackedFrame:GetTargetAlphaBaseValue()
		return MapPinTimersDB.fullAlpha and 1 or oldAlpha(self)
	end
end

-- replaces UpdateDistanceText from Blizzard_QuestNavigation/SuperTrackedFrame.lua
do
	local function GetDistanceString(distance)
		if distance < 1000 then
			return tostring(distance)
		else
			return AbbreviateNumbers(distance)
		end
	end
	local throttle = 0
	local lastDistance = nil
	local function UpdateDistanceTextWithTimer(self, elapsed)
		local distance = C_Navigation.GetDistance()
		self.DistanceText:SetShown(true)
		self.DistanceText:SetText(IN_GAME_NAVIGATION_RANGE:format(GetDistanceString(Round(distance))))
		throttle = throttle + elapsed
		if throttle >= .5 then
			local speed = lastDistance and ((lastDistance - distance) / throttle) or 0
			lastDistance = distance
			if speed > 0 then
				local time = abs(distance / speed)
				self.TimeText:SetText(TIMER_MINUTES_DISPLAY:format(floor(time / 60), floor(time % 60)))
				self.TimeText:SetShown(true)
			else
				self.TimeText:SetShown(false)
			end
			throttle = 0
		end
	end

	-- replaces OnUpdate from Blizzard_QuestNavigation/SuperTrackedFrame.lua
	local function OnUpdateTimer(self, elapsed)
		self:CheckInitializeNavigationFrame(false)
		if self.navFrame then
			self:UpdateClampedState()
			self:UpdatePosition()
			self:UpdateArrow()
			-- this replaces the original self:UpdateDistanceText
			UpdateDistanceTextWithTimer(self, elapsed)
			self:UpdateAlpha()
		end
	end
	SuperTrackedFrame:SetScript("OnUpdate", OnUpdateTimer)
end
