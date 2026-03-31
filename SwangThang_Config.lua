local addonName, ns = ...

-- ============================================================
-- Config panel: /swang opens this frame.
-- Sliders for bar dimensions, color picker buttons for bar colors.
-- ============================================================

local panel
local PREVIEW_ALPHA = 1

-- ============================================================
-- Bar preview: show bars while config panel is open
-- ============================================================
local function ShowBarPreview()
	local bars = { ns.mhBar, ns.ohBar, ns.rangedBar }
	for _, bar in ipairs(bars) do
		if bar then
			bar:SetAlpha(1)
			bar:SetMinMaxValues(0, 1)
			bar:SetValue(1)
		end
	end
	ns.ApplyBarColors()
end

local function HideBarPreview()
	-- Only hide if not in combat (combat show/hide handles itself)
	if not InCombatLockdown or not InCombatLockdown() then
		local bars = { ns.mhBar, ns.ohBar, ns.rangedBar }
		for _, bar in ipairs(bars) do
			if bar then bar:SetAlpha(0) end
		end
	end
end

-- ============================================================
-- Color picker helper
-- ============================================================
local function OpenColorPicker(colorKey, swatch)
	local c = SwangThangDB.colors[colorKey]
	local isSealTwist = (colorKey == "sealTwist")

	local function applyColor(r, g, b)
		local a = isSealTwist and 0.4 or 1
		SwangThangDB.colors[colorKey] = { r = r, g = g, b = b, a = a }
		swatch:SetColorTexture(r, g, b, a)
		ns.ApplyBarColors()
	end

	local info = {
		r = c.r,
		g = c.g,
		b = c.b,
		swatchFunc = function()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			applyColor(r, g, b)
		end,
		cancelFunc = function(prev)
			applyColor(prev.r, prev.g, prev.b)
		end,
	}
	ColorPickerFrame:SetupColorPickerAndShow(info)
end

-- ============================================================
-- Widget builders
-- ============================================================
local function CreateSlider(parent, label, minVal, maxVal, step, yOffset)
	local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
	slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
	slider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, yOffset)
	slider:SetMinMaxValues(minVal, maxVal)
	slider:SetValueStep(step)
	slider:SetObeyStepOnDrag(true)
	slider:SetHeight(17)

	slider.Text:SetText(label)
	slider.Low:SetText(tostring(minVal))
	slider.High:SetText(tostring(maxVal))

	-- Value label below the slider
	local valText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	valText:SetPoint("TOP", slider, "BOTTOM", 0, -2)
	slider._valText = valText

	return slider
end

local function CreateColorButton(parent, label, colorKey, yOffset)
	local row = CreateFrame("Frame", nil, parent)
	row:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
	row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, yOffset)
	row:SetHeight(22)

	local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("LEFT", row, "LEFT", 0, 0)
	text:SetText(label)

	local btn = CreateFrame("Button", nil, row)
	btn:SetSize(22, 22)
	btn:SetPoint("RIGHT", row, "RIGHT", 0, 0)

	local swatch = btn:CreateTexture(nil, "ARTWORK")
	swatch:SetAllPoints(true)
	local c = SwangThangDB.colors[colorKey]
	if c then
		swatch:SetColorTexture(c.r, c.g, c.b, c.a)
	end
	btn._swatch = swatch
	btn._colorKey = colorKey

	local border = btn:CreateTexture(nil, "OVERLAY")
	border:SetColorTexture(0.4, 0.4, 0.4, 1)
	border:SetPoint("TOPLEFT", -1, 1)
	border:SetPoint("BOTTOMRIGHT", 1, -1)
	border:SetDrawLayer("OVERLAY", -1)

	btn:SetScript("OnClick", function()
		OpenColorPicker(colorKey, swatch)
	end)

	row._btn = btn
	row._swatch = swatch
	return row
end

-- ============================================================
-- Panel creation
-- ============================================================
local function CreatePanel()
	local f = CreateFrame("Frame", "SwangThangConfigPanel", UIParent, "BackdropTemplate")
	f:SetSize(280, 340)
	f:SetPoint("CENTER")
	f:SetBackdrop({
		bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	})
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetScript("OnMouseDown", function(self, button)
		if button == "RightButton" then return end  -- suppress right-click menu
	end)
	f:SetClampedToScreen(true)
	f:SetFrameStrata("DIALOG")
	f:SetScript("OnHide", function() HideBarPreview() end)
	f:Hide()

	-- Title
	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", f, "TOP", 0, -16)
	title:SetText("SwangThang")

	-- Close button
	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)

	-- Sliders
	local widthSlider = CreateSlider(f, "Bar Width", 100, 400, 10, -50)
	widthSlider:SetValue(SwangThangDB.barWidth or ns.DB_DEFAULTS.barWidth)
	widthSlider._valText:SetText(tostring(widthSlider:GetValue()))

	local heightSlider = CreateSlider(f, "Bar Height", 10, 40, 2, -100)
	heightSlider:SetValue(SwangThangDB.barHeight or ns.DB_DEFAULTS.barHeight)
	heightSlider._valText:SetText(tostring(heightSlider:GetValue()))

	widthSlider:SetScript("OnValueChanged", function(self, value)
		value = math.floor(value + 0.5)
		self._valText:SetText(tostring(value))
		ns.ApplyBarSize(value, heightSlider:GetValue())
	end)

	heightSlider:SetScript("OnValueChanged", function(self, value)
		value = math.floor(value + 0.5)
		self._valText:SetText(tostring(value))
		ns.ApplyBarSize(widthSlider:GetValue(), value)
	end)

	-- Color buttons
	local yStart = -150
	local spacing = -28
	local mhRow     = CreateColorButton(f, "Main Hand Color",  "mh",     yStart)
	local ohRow     = CreateColorButton(f, "Off Hand Color",   "oh",     yStart + spacing)
	local rangedRow = CreateColorButton(f, "Ranged Color",     "ranged", yStart + spacing * 2)
	local sealRow   = CreateColorButton(f, "Seal-Twist Color", "sealTwist", yStart + spacing * 3)

	-- Seal-twist row only visible for Paladins
	if ns.playerClass ~= "PALADIN" then
		sealRow:Hide()
	end

	-- Reset button
	local resetBtn = CreateFrame("Button", nil, f)
	resetBtn:SetSize(120, 24)
	resetBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 16)

	local resetBg = resetBtn:CreateTexture(nil, "BACKGROUND")
	resetBg:SetAllPoints(true)
	resetBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

	local resetBorder = resetBtn:CreateTexture(nil, "OVERLAY")
	resetBorder:SetColorTexture(0.5, 0.5, 0.5, 1)
	resetBorder:SetPoint("TOPLEFT", -1, 1)
	resetBorder:SetPoint("BOTTOMRIGHT", 1, -1)
	resetBorder:SetDrawLayer("OVERLAY", -1)

	local resetText = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	resetText:SetPoint("CENTER")
	resetText:SetText("Reset Defaults")

	resetBtn:SetScript("OnEnter", function(self)
		resetBg:SetColorTexture(0.3, 0.3, 0.3, 0.9)
	end)
	resetBtn:SetScript("OnLeave", function(self)
		resetBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
	end)
	resetBtn:SetScript("OnClick", function()
		ns.ResetConfigDefaults()
		-- Update slider positions
		widthSlider:SetValue(ns.DB_DEFAULTS.barWidth)
		heightSlider:SetValue(ns.DB_DEFAULTS.barHeight)
		-- Update color swatches
		for _, row in ipairs({ mhRow, ohRow, rangedRow, sealRow }) do
			local key = row._btn._colorKey
			local c = SwangThangDB.colors[key]
			if c then
				row._swatch:SetColorTexture(c.r, c.g, c.b, c.a)
			end
		end
	end)

	f._widthSlider  = widthSlider
	f._heightSlider = heightSlider
	f._colorRows    = { mhRow, ohRow, rangedRow, sealRow }
	return f
end

-- ============================================================
-- Public API
-- ============================================================
function ns.InitConfig()
	panel = CreatePanel()
end

function ns.ToggleConfig()
	if not panel then return end
	if panel:IsShown() then
		panel:Hide()
	else
		-- Refresh slider values from DB before showing
		panel._widthSlider:SetValue(SwangThangDB.barWidth or ns.DB_DEFAULTS.barWidth)
		panel._heightSlider:SetValue(SwangThangDB.barHeight or ns.DB_DEFAULTS.barHeight)
		for _, row in ipairs(panel._colorRows) do
			local key = row._btn._colorKey
			local c = SwangThangDB.colors[key]
			if c then
				row._swatch:SetColorTexture(c.r, c.g, c.b, c.a)
			end
		end
		panel:Show()
		ShowBarPreview()
	end
end

function ns.ResetConfigDefaults()
	SwangThangDB.barWidth  = ns.DB_DEFAULTS.barWidth
	SwangThangDB.barHeight = ns.DB_DEFAULTS.barHeight
	for key, def in pairs(ns.DB_DEFAULTS.colors) do
		SwangThangDB.colors[key] = { r = def.r, g = def.g, b = def.b, a = def.a }
	end
	ns.ApplyBarSize(ns.DB_DEFAULTS.barWidth, ns.DB_DEFAULTS.barHeight)
	ns.ApplyBarColors()
end
