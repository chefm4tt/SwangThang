local addonName, ns = ...

-- ----------------------------------------------------------------------------
-- Configuration & Constants
-- ----------------------------------------------------------------------------
local BAR_WIDTH = 200
local BAR_HEIGHT = 20
local CAST_WINDOW = 0.5 -- The hidden cast time for Auto Shot in TBC
local AUTO_SHOT_ID = 75

-- ----------------------------------------------------------------------------
-- Frame Setup
-- ----------------------------------------------------------------------------
local f = CreateFrame("StatusBar", "HunterTimerFrame", UIParent)
f:SetSize(BAR_WIDTH, BAR_HEIGHT)
f:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetClampedToScreen(true)

-- Visuals
f:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
f:SetStatusBarColor(0, 1, 0, 1) -- Green for cooldown phase

local bg = f:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(true)
bg:SetColorTexture(0, 0, 0, 0.5)

local border = f:CreateTexture(nil, "OVERLAY")
border:SetColorTexture(0, 0, 0, 1)
border:SetPoint("TOPLEFT", -1, 1)
border:SetPoint("BOTTOMRIGHT", 1, -1)
border:SetDrawLayer("OVERLAY", -1) -- Behind the spark/text

-- The Red "Cast" Window Overlay
local castZone = f:CreateTexture(nil, "ARTWORK")
castZone:SetColorTexture(1, 0, 0, 0.4) -- Red overlay
castZone:SetPoint("TOPRIGHT")
castZone:SetPoint("BOTTOMRIGHT")
castZone:SetWidth(0) -- Set dynamically

local spark = f:CreateTexture(nil, "OVERLAY")
spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
spark:SetBlendMode("ADD")
spark:SetWidth(20)
spark:SetHeight(BAR_HEIGHT * 2.2)
spark:SetPoint("CENTER", f, "LEFT", 0, 0)

local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
text:SetPoint("CENTER")
text:SetText("Auto Shot")

-- ----------------------------------------------------------------------------
-- State Variables
-- ----------------------------------------------------------------------------
local lastShotTime = 0
local swingDuration = 2.0
local isMoving = false
local isSwinging = false

-- ----------------------------------------------------------------------------
-- Helper Functions
-- ----------------------------------------------------------------------------

-- Calculates current ranged weapon speed (Haste Math)
-- Returns: speed (float)
local function GetCurrentWeaponSpeed()
	-- UnitRangedDamage returns speed in seconds as the first argument.
	-- This native function accounts for Haste, Rapid Fire, Quiver, etc.
	local speed = UnitRangedDamage("player")
	if speed and speed > 0 then
		return speed
	end
	return 2.0 -- Fallback
end

local function UpdateCastZoneVisual()
	if swingDuration > 0 then
		-- Calculate width of the 0.5s window relative to total swing time
		local width = (CAST_WINDOW / swingDuration) * BAR_WIDTH
		-- Clamp width to not exceed bar width
		width = math.min(width, BAR_WIDTH)
		castZone:SetWidth(width)
	end
end

local function ResetTimer()
	isSwinging = false
	f:SetValue(0)
	spark:SetPoint("CENTER", f, "LEFT", 0, 0)
	f:SetAlpha(0)
end

local function StartSwing()
	-- Latency Adjustment
	local _, _, _, latencyWorld = GetNetStats()
	local latencySec = (latencyWorld or 0) / 1000

	lastShotTime = GetTime() - latencySec
	swingDuration = GetCurrentWeaponSpeed()
	
	f:SetMinMaxValues(0, swingDuration)
	UpdateCastZoneVisual()
	
	isSwinging = true
	f:SetAlpha(1)
end

-- ----------------------------------------------------------------------------
-- Event Handling
-- ----------------------------------------------------------------------------
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:RegisterEvent("PLAYER_STARTED_MOVING")
f:RegisterEvent("PLAYER_STOPPED_MOVING")
f:RegisterEvent("UNIT_SPELLCAST_START")
f:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")

f:SetScript("OnEvent", function(self, event, ...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _, subEvent, _, sourceGUID, _, _, _, _, _, _, _, spellId = CombatLogGetCurrentEventInfo()
		
		if sourceGUID == UnitGUID("player") and subEvent == "SPELL_CAST_SUCCESS" then
			if spellId == AUTO_SHOT_ID then
				StartSwing()
			end
		end

	elseif event == "PLAYER_STARTED_MOVING" then
		isMoving = true

	elseif event == "PLAYER_STOPPED_MOVING" then
		isMoving = false

	elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
		local unit, _, spellId = ...
		if unit == "player" then
			-- If casting Aimed Shot or other hard casts, Auto Shot is usually clipped/reset.
			-- We reset the visual timer to indicate the swing is interrupted.
			-- Note: Steady Shot does not clip Auto Shot in the same way in later expansions, 
			-- but in TBC hard casts usually reset the swing timer.
			if spellId ~= AUTO_SHOT_ID then 
				ResetTimer()
			end
		end

	elseif event == "ADDON_LOADED" then
		local name = ...
		if name == "SwangThang" then
			if HunterTimerDB then
				f:ClearAllPoints()
				f:SetPoint(HunterTimerDB.point, UIParent, HunterTimerDB.relativePoint, HunterTimerDB.x, HunterTimerDB.y)
			else
				HunterTimerDB = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -100 }
			end
		end

	elseif event == "PLAYER_REGEN_ENABLED" then
		-- Optional: Hide out of combat if desired, keeping it simple for now
		-- ResetTimer() 
	end
end)

-- ----------------------------------------------------------------------------
-- OnUpdate Logic
-- ----------------------------------------------------------------------------
f:SetScript("OnUpdate", function(self, elapsed)
	if not isSwinging then return end

	local now = GetTime()
	
	-- 1. Dynamic Swing Calculation
	-- Update duration constantly to account for procs (DST, Rapid Fire, etc)
	local currentSpeed = GetCurrentWeaponSpeed()
	
	-- If speed changed significantly, update the max value
	if math.abs(swingDuration - currentSpeed) > 0.01 then
		swingDuration = currentSpeed
		f:SetMinMaxValues(0, swingDuration)
		UpdateCastZoneVisual()
	end

	-- 2. Calculate Time Remaining
	-- The "Cast Window" starts at (swingDuration - CAST_WINDOW)
	local cooldownEndTime = lastShotTime + swingDuration - CAST_WINDOW
	
	-- 3. Movement & Clipping Logic
	if now >= cooldownEndTime then
		-- We are in the 0.5s "Hidden Cast" window
		if isMoving then
			-- If moving during the cast window, the shot is clipped/delayed.
			-- We push the lastShotTime forward so that the timer "pauses" 
			-- exactly at the start of the cast window (0.5s remaining).
			-- This satisfies the "Retry Mechanic": as soon as we stop, 
			-- lastShotTime stops shifting, and we have exactly 0.5s left to fire.
			
			lastShotTime = now - (swingDuration - CAST_WINDOW)
		end
		
		-- Visual: Change color to Red to indicate Cast Phase
		f:SetStatusBarColor(1, 0, 0, 1)
	else
		-- Visual: Green for Cooldown Phase
		f:SetStatusBarColor(0, 1, 0, 1)
	end

	local timeElapsed = now - lastShotTime
	local timeRemaining = swingDuration - timeElapsed

	-- Clamp visual to 0
	if timeRemaining < 0 then timeRemaining = 0 end

	-- Update Bar
	f:SetValue(timeElapsed)

	-- Update Spark
	local sparkPos = (timeElapsed / swingDuration) * BAR_WIDTH
	if sparkPos > BAR_WIDTH then sparkPos = BAR_WIDTH end
	spark:SetPoint("CENTER", f, "LEFT", sparkPos, 0)

	-- Update Text
	text:SetText(string.format("%.1f", timeRemaining))
end)

-- ----------------------------------------------------------------------------
-- Drag Handling
-- ----------------------------------------------------------------------------
f:SetScript("OnMouseDown", function(self, button)
	if button == "LeftButton" and not self.isMoving then
		self:StartMoving()
		self.isMoving = true
	end
end)

f:SetScript("OnMouseUp", function(self, button)
	if button == "LeftButton" and self.isMoving then
		self:StopMovingOrSizing()
		self.isMoving = false
		
		local point, _, relativePoint, x, y = self:GetPoint()
		HunterTimerDB.point = point
		HunterTimerDB.relativePoint = relativePoint
		HunterTimerDB.x = x
		HunterTimerDB.y = y
	end
end)
