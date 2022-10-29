-- globals
local C_Map, C_Navigation, C_SuperTrack, C_Timer = C_Map, C_Navigation, C_SuperTrack, C_Timer
local abs, floor, Round, CreateFrame = abs, floor, Round, CreateFrame
local SuperTrackedFrame, TIMER_MINUTES_DISPLAY, IN_GAME_NAVIGATION_RANGE = SuperTrackedFrame, TIMER_MINUTES_DISPLAY, IN_GAME_NAVIGATION_RANGE

-- locals
local fullAlpha = true -- this should be user configurable eventually

-- set up event frame
local eventFrame = CreateFrame("Frame")
eventFrame:SetScript('OnEvent', function(self, event, ...)
  if self[event] then return self[event](...) end
end)

-- anchor time text
SuperTrackedFrame.TimeText = SuperTrackedFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
SuperTrackedFrame.TimeText:SetJustifyV("TOP")
SuperTrackedFrame.TimeText:SetSize(0, 20)
SuperTrackedFrame.TimeText:SetPoint("TOP", SuperTrackedFrame.Icon, "BOTTOM", 0, -22)

-- auto-track new map pins
eventFrame:RegisterEvent("USER_WAYPOINT_UPDATED")
function eventFrame:USER_WAYPOINT_UPDATED()
  if C_Map.HasUserWaypoint() then
    C_Timer.After(0, function()
      C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end)
  end
end

-- override frame alpha to full opacity so the timer is useful
do
  local oldAlpha = SuperTrackedFrame.GetTargetAlphaBaseValue
  function SuperTrackedFrame:GetTargetAlphaBaseValue()
    return fullAlpha and 1 or oldAlpha(self)
  end
end

-- replaces UpdateDistanceText from Blizzard_QuestNavigation/SuperTrackedFrame.lua
do
  local throttle = 0
  local lastDistance = nil
  local function UpdateDistanceTextWithTimer(self, elapsed)
    self.DistanceText:SetShown(not self.isClamped)

      if not self.isClamped then
        local distance = C_Navigation.GetDistance()

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

        self.DistanceText:SetText(IN_GAME_NAVIGATION_RANGE:format(Round(distance)))
      else
        self.TimeText:SetShown(false)
        lastDistance = nil
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
