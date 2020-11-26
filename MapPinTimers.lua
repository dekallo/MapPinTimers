local superTrackedFrame = _G["SuperTrackedFrame"]
local timeText = superTrackedFrame:CreateFontString("TimeText", "BACKGROUND", "GameFontNormal")
timeText:SetJustifyV("TOP")
timeText:SetSize(0, 20)
timeText:SetPoint("TOP", superTrackedFrame.Icon, "BOTTOM", 0, -22)

-- this should be user configurable eventually
local fullAlpha = true

-- TODO: can we autotrack new pins?

-- override frame alpha to full opacity so the timer is useful
local oldAlpha = SuperTrackedFrame.GetTargetAlphaBaseValue
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
          timeText:SetText(TIMER_MINUTES_DISPLAY:format(floor(time / 60), floor(time % 60)))
          timeText:SetShown(true)
        else
          timeText:SetShown(false)
        end

        throttle = 0
      end

      self.DistanceText:SetText(IN_GAME_NAVIGATION_RANGE:format(Round(distance)))
    else
      timeText:SetShown(false)
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
