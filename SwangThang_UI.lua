local addonName, ns = ...

-- ============================================================
-- Bar factory
-- ============================================================
local function CreateBar(frameName, width, height)
	local f = CreateFrame("StatusBar", frameName, UIParent)
	f:SetSize(width or ns.BAR_WIDTH, height or ns.BAR_HEIGHT)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetClampedToScreen(true)
	f:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	f:SetStatusBarColor(0, 0, 0, 1)
	f:SetAlpha(0)

	local bg = f:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(true)
	bg:SetColorTexture(0, 0, 0, 0.5)

	-- Border: 4 thin edges so the fill remains visible
	local borderTop = f:CreateTexture(nil, "OVERLAY")
	borderTop:SetColorTexture(0, 0, 0, 1)
	borderTop:SetPoint("TOPLEFT", -1, 1)
	borderTop:SetPoint("TOPRIGHT", 1, 1)
	borderTop:SetHeight(1)

	local borderBottom = f:CreateTexture(nil, "OVERLAY")
	borderBottom:SetColorTexture(0, 0, 0, 1)
	borderBottom:SetPoint("BOTTOMLEFT", -1, -1)
	borderBottom:SetPoint("BOTTOMRIGHT", 1, -1)
	borderBottom:SetHeight(1)

	local borderLeft = f:CreateTexture(nil, "OVERLAY")
	borderLeft:SetColorTexture(0, 0, 0, 1)
	borderLeft:SetPoint("TOPLEFT", -1, 1)
	borderLeft:SetPoint("BOTTOMLEFT", -1, -1)
	borderLeft:SetWidth(1)

	local borderRight = f:CreateTexture(nil, "OVERLAY")
	borderRight:SetColorTexture(0, 0, 0, 1)
	borderRight:SetPoint("TOPRIGHT", 1, 1)
	borderRight:SetPoint("BOTTOMRIGHT", 1, -1)
	borderRight:SetWidth(1)

	local spark = f:CreateTexture(nil, "OVERLAY")
	spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	spark:SetBlendMode("ADD")
	spark:SetWidth(20)
	spark:SetHeight((height or ns.BAR_HEIGHT) * 2.2)
	spark:SetPoint("CENTER", f, "LEFT", 0, 0)

	local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("CENTER")

	f._spark = spark
	f._text  = text
	f._width = width or ns.BAR_WIDTH
	return f
end

-- ============================================================
-- Ranged bar (preserves v1.x behavior exactly)
-- ============================================================
local function CreateRangedBar()
	local f = CreateBar("SwangThangRangedBar")

	-- Red "cast window" overlay
	local castZone = f:CreateTexture(nil, "ARTWORK")
	castZone:SetColorTexture(1, 0, 0, 0.4)
	castZone:SetPoint("TOPRIGHT")
	castZone:SetPoint("BOTTOMRIGHT")
	castZone:SetWidth(0)
	f._castZone = castZone

	f._text:SetText("Auto Shot")
	f:SetMinMaxValues(0, 1)
	ns.rangedBar = f
	return f
end

-- ============================================================
-- Melee bars (MH and optional OH)
-- ============================================================
local function CreateMHBar()
	local f = CreateBar("SwangThangMHBar")
	local c = SwangThangDB and SwangThangDB.colors and SwangThangDB.colors.mh
	if c then
		f:SetStatusBarColor(c.r, c.g, c.b, c.a)
	else
		f:SetStatusBarColor(0, 0, 0, 1)
	end
	f._text:SetText("Main Hand")
	f:SetMinMaxValues(0, 1)
	ns.mhBar = f
	return f
end

local function CreateOHBar()
	local mh = ns.mhBar
	local f = CreateBar("SwangThangOHBar")
	local c = SwangThangDB and SwangThangDB.colors and SwangThangDB.colors.oh
	if c then
		f:SetStatusBarColor(c.r, c.g, c.b, c.a)
	else
		f:SetStatusBarColor(0, 0, 0, 1)
	end
	f._text:SetText("Off Hand")
	f:SetMinMaxValues(0, 1)
	-- Anchor OH below MH with 2px gap
	f:ClearAllPoints()
	f:SetPoint("TOPLEFT", mh, "BOTTOMLEFT", 0, -2)
	f:SetPoint("TOPRIGHT", mh, "BOTTOMRIGHT", 0, -2)
	ns.ohBar = f
	return f
end

-- ============================================================
-- Cast-zone visual for ranged bar
-- ============================================================
local function UpdateCastZoneVisual()
	local f = ns.rangedBar
	if not f then return end
	local duration = ns.timers.ranged.duration
	if duration and duration > 0 then
		local width = (ns.CAST_WINDOW / duration) * ns.BAR_WIDTH
		f._castZone:SetWidth(math.min(width, ns.BAR_WIDTH))
	end
end
ns.UpdateCastZoneVisual = UpdateCastZoneVisual

-- ============================================================
-- Bar position save/restore
-- ============================================================
local function SavePosition(slot, frame)
	if not frame then return end
	local point, _, relativePoint, x, y = frame:GetPoint()
	if SwangThangDB and SwangThangDB.positions then
		SwangThangDB.positions[slot] = {
			point = point, relativePoint = relativePoint, x = x, y = y
		}
	end
end

local function RestorePosition(slot, frame)
	if not frame then return end
	local pos = SwangThangDB and SwangThangDB.positions and SwangThangDB.positions[slot]
	if pos then
		frame:ClearAllPoints()
		frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
	end
end

-- ============================================================
-- Drag handling (anchor bar only — OH follows MH automatically)
-- ============================================================
local function AttachDrag(frame, slot)
	frame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and not self.isMoving then
			self:StartMoving()
			self.isMoving = true
		end
	end)
	frame:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and self.isMoving then
			self:StopMovingOrSizing()
			self.isMoving = false
			SavePosition(slot, self)
		end
	end)
end

-- ============================================================
-- Combat show/hide
-- ============================================================
local function ShowBars()
	local cfg = ns.classConfig
	if cfg and cfg.ranged and ns.rangedBar then
		ns.rangedBar:SetAlpha(1)
	end
	if cfg and cfg.melee and ns.mhBar then
		ns.mhBar:SetAlpha(1)
	end
	if cfg and cfg.dualWield and ns.ohBar then
		ns.ohBar:SetAlpha(1)
	end
end

local function HideBars()
	if ns.rangedBar then ns.rangedBar:SetAlpha(0) end
	if ns.mhBar     then ns.mhBar:SetAlpha(0) end
	if ns.ohBar     then ns.ohBar:SetAlpha(0) end
end

ns.ShowBars = ShowBars
ns.HideBars = HideBars

-- ============================================================
-- OnUpdate tick for ranged bar
-- ============================================================
local function UpdateRangedBar(elapsed)
	local t = ns.timers.ranged
	if t.state ~= "swinging" then return end

	local f = ns.rangedBar
	if not f then return end

	local now = GetTime()

	-- Haste rescaling: check current speed
	local currentSpeed = UnitRangedDamage("player")
	if currentSpeed and currentSpeed > 0 then
		ns.RescaleTimer("ranged", currentSpeed)
	end

	-- Movement clipping in cast window
	local cooldownEnd = t.lastSwing + t.duration - ns.CAST_WINDOW
	if now >= cooldownEnd then
		f:SetStatusBarColor(1, 0, 0, 1)  -- red: cast window
		if ns.isMoving then
			-- Pin timer at cast-window boundary
			t.lastSwing = now - (t.duration - ns.CAST_WINDOW)
		end
	else
		local c = ns.rangedBarBaseColor
		if c then
			f:SetStatusBarColor(c.r, c.g, c.b, c.a)
		else
			f:SetStatusBarColor(0, 0, 0, 1)
		end
	end

	local elapsed_time = now - t.lastSwing
	local remaining = t.duration - elapsed_time
	if remaining < 0 then remaining = 0 end

	f:SetMinMaxValues(0, t.duration)
	f:SetValue(elapsed_time)

	local sparkPos = (elapsed_time / t.duration) * f._width
	if sparkPos > f._width then sparkPos = f._width end
	f._spark:SetPoint("CENTER", f, "LEFT", sparkPos, 0)
	f._text:SetText(string.format("%.1f", remaining))
end

-- ============================================================
-- OnUpdate tick for melee bars
-- ============================================================
local function UpdateMeleeBar(slot, frame)
	local t = ns.timers[slot]
	if not frame or t.state ~= "swinging" then return end

	local now = GetTime()

	-- Haste rescaling
	local mhSpeed, ohSpeed = UnitAttackSpeed("player")
	local currentSpeed = (slot == "oh") and ohSpeed or mhSpeed
	if currentSpeed and currentSpeed > 0 then
		-- Only rescale if UNIT_ATTACK_SPEED debounce has cleared
		local skipUntil = ns.druidFormChangeTime and (ns.druidFormChangeTime + 0.05)
		if not skipUntil or now > skipUntil then
			ns.RescaleTimer(slot, currentSpeed)
		end
	end

	local elapsed_time = now - t.lastSwing
	local remaining = t.duration - elapsed_time
	if remaining < 0 then remaining = 0 end

	frame:SetMinMaxValues(0, t.duration)
	frame:SetValue(elapsed_time)

	local sparkPos = (elapsed_time / t.duration) * frame._width
	if sparkPos > frame._width then sparkPos = frame._width end
	frame._spark:SetPoint("CENTER", frame, "LEFT", sparkPos, 0)
	frame._text:SetText(string.format("%.1f", remaining))
end

-- ============================================================
-- Runtime apply functions (called from config panel)
-- ============================================================
function ns.ApplyBarSize(width, height)
	ns.BAR_WIDTH  = width
	ns.BAR_HEIGHT = height
	SwangThangDB.barWidth  = width
	SwangThangDB.barHeight = height

	local bars = { ns.mhBar, ns.ohBar, ns.rangedBar }
	for _, bar in ipairs(bars) do
		if bar then
			bar:SetSize(width, height)
			bar._width = width
			bar._spark:SetHeight(height * 2.2)
		end
	end
	-- OH anchors to MH via two-point, so width follows automatically.
	-- Re-anchor to ensure the gap is correct after height change.
	if ns.ohBar and ns.mhBar then
		ns.ohBar:ClearAllPoints()
		ns.ohBar:SetPoint("TOPLEFT", ns.mhBar, "BOTTOMLEFT", 0, -2)
		ns.ohBar:SetPoint("TOPRIGHT", ns.mhBar, "BOTTOMRIGHT", 0, -2)
	end
end

function ns.ApplyBarColors()
	local colors = SwangThangDB and SwangThangDB.colors
	if not colors then return end

	-- Bars always use alpha=1; only sealTwist uses fractional alpha
	if ns.mhBar and colors.mh then
		local c = colors.mh
		ns.mhBar:SetStatusBarColor(c.r, c.g, c.b, 1)
		ns.mhBarBaseColor = { r = c.r, g = c.g, b = c.b, a = 1 }
	end
	if ns.ohBar and colors.oh then
		local c = colors.oh
		ns.ohBar:SetStatusBarColor(c.r, c.g, c.b, 1)
	end
	if colors.ranged then
		local c = colors.ranged
		ns.rangedBarBaseColor = { r = c.r, g = c.g, b = c.b, a = 1 }
		if ns.rangedBar then
			ns.rangedBar:SetStatusBarColor(c.r, c.g, c.b, 1)
		end
	end
	if ns.sealTwistZone and colors.sealTwist then
		local c = colors.sealTwist
		ns.sealTwistZone:SetColorTexture(c.r, c.g, c.b, c.a or 0.4)
	end
end

-- ============================================================
-- OnUpdate dispatcher (called from bootstrap frame)
-- ============================================================
function ns.OnUpdate(elapsed)
	UpdateRangedBar(elapsed)
	if ns.mhBar then UpdateMeleeBar("mh", ns.mhBar) end
	if ns.ohBar then UpdateMeleeBar("oh", ns.ohBar) end
end

-- ============================================================
-- Bar initialization (called after SavedVariables are loaded)
-- ============================================================
function ns.InitBars()
	local cfg = ns.classConfig
	if not cfg then return end

	if cfg.ranged then
		CreateRangedBar()
		RestorePosition("ranged", ns.rangedBar)
		AttachDrag(ns.rangedBar, "ranged")
	end

	if cfg.melee then
		CreateMHBar()
		RestorePosition("mh", ns.mhBar)
		AttachDrag(ns.mhBar, "mh")
	end

	if cfg.melee and cfg.dualWield then
		-- Only create OH bar if player has an OH weapon equipped
		-- (checked via UnitAttackSpeed returning a non-nil ohSpeed)
		local _, ohSpeed = UnitAttackSpeed("player")
		if ohSpeed then
			CreateOHBar()
			-- OH doesn't need drag — it follows MH automatically
		end
	end

	-- Notify ClassMods that bars exist
	if ns.OnBarsCreated then ns.OnBarsCreated() end
end

-- ============================================================
-- OH bar creation on equipment change
-- ============================================================
function ns.UpdateOHBar()
	local cfg = ns.classConfig
	if not cfg or not cfg.dualWield then return end

	local _, ohSpeed = UnitAttackSpeed("player")
	if ohSpeed and not ns.ohBar then
		CreateOHBar()
		if ns.OnBarsCreated then ns.OnBarsCreated() end
	elseif not ohSpeed and ns.ohBar then
		ns.ohBar:Hide()
		ns.ohBar = nil
		ns.timers.oh.state = "idle"
	end
end

-- Callbacks set by ClassMods (optional)
ns.OnMeleeSwing  = nil
ns.OnRangedSwing = nil
ns.OnBarsCreated = nil
ns.OnDruidFormChange = nil
