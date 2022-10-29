-- globals
local superTrackedFrame, C_Navigation, abs, floor, Round, TIMER_MINUTES_DISPLAY, IN_GAME_NAVIGATION_RANGE = SuperTrackedFrame, C_Navigation, abs, floor, Round, TIMER_MINUTES_DISPLAY, IN_GAME_NAVIGATION_RANGE

-- anchor time text
superTrackedFrame.TimeText = superTrackedFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
superTrackedFrame.TimeText:SetJustifyV("TOP")
superTrackedFrame.TimeText:SetSize(0, 20)
superTrackedFrame.TimeText:SetPoint("TOP", superTrackedFrame.Icon, "BOTTOM", 0, -22)

-- TODO: can we autotrack new pins?

-- this should be user configurable eventually
local fullAlpha = true

-- override frame alpha to full opacity so the timer is useful
local oldAlpha = superTrackedFrame.GetTargetAlphaBaseValue
function SuperTrackedFrame:GetTargetAlphaBaseValue()
  return fullAlpha and 1 or oldAlpha(self)
end

-- replaces UpdateDistanceText from Blizzard_QuestNavigation/SuperTrackedFrame.lua
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
superTrackedFrame:SetScript("OnUpdate", OnUpdateTimer)
