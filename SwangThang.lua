local addonName, ns = ...

-- ============================================================
-- Bootstrap: event frame, SavedVariables init, dispatch
-- ============================================================
-- This file wires everything together. Logic lives in:
--   SwangThang_Constants.lua  — spell IDs, class config, defaults
--   SwangThang_State.lua      — detection engine, timer state
--   SwangThang_UI.lua         — bars, visuals, drag, show/hide
--   SwangThang_ClassMods.lua  — class-specific overlays

-- ============================================================
-- Runtime globals
-- ============================================================
ns.isMoving        = false
ns.playerClass     = nil
ns.classConfig     = nil
ns.druidFormChangeTime = nil

-- ============================================================
-- SavedVariables migration
-- ============================================================
local function MigrateDB()
	-- v2: SwangThangDB with nested positions
	-- Migrate from v1: HunterTimerDB = {point, relativePoint, x, y}
	if HunterTimerDB and not SwangThangDB then
		SwangThangDB = {
			version   = 2,
			showMH    = true,
			showOH    = true,
			positions = {
				mh     = ns.DB_DEFAULTS.positions.mh,
				oh     = ns.DB_DEFAULTS.positions.oh,
				ranged = {
					point        = HunterTimerDB.point        or "CENTER",
					relativePoint = HunterTimerDB.relativePoint or "CENTER",
					x            = HunterTimerDB.x            or 0,
					y            = HunterTimerDB.y            or -100,
				},
			},
		}
		HunterTimerDB = nil  -- clear legacy SavedVariable
	end

	-- Fresh install
	if not SwangThangDB then
		SwangThangDB = {
			version   = ns.DB_DEFAULTS.version,
			showMH    = ns.DB_DEFAULTS.showMH,
			showOH    = ns.DB_DEFAULTS.showOH,
			positions = {
				mh     = { point = ns.DB_DEFAULTS.positions.mh.point,     relativePoint = ns.DB_DEFAULTS.positions.mh.relativePoint,     x = ns.DB_DEFAULTS.positions.mh.x,     y = ns.DB_DEFAULTS.positions.mh.y     },
				oh     = { point = ns.DB_DEFAULTS.positions.oh.point,     relativePoint = ns.DB_DEFAULTS.positions.oh.relativePoint,     x = ns.DB_DEFAULTS.positions.oh.x,     y = ns.DB_DEFAULTS.positions.oh.y     },
				ranged = { point = ns.DB_DEFAULTS.positions.ranged.point, relativePoint = ns.DB_DEFAULTS.positions.ranged.relativePoint, x = ns.DB_DEFAULTS.positions.ranged.x, y = ns.DB_DEFAULTS.positions.ranged.y },
			},
		}
	end

	-- Fill any missing fields for upgrades
	SwangThangDB.version = SwangThangDB.version or 2
	SwangThangDB.showMH  = (SwangThangDB.showMH  ~= false)
	SwangThangDB.showOH  = (SwangThangDB.showOH  ~= false)
	SwangThangDB.positions = SwangThangDB.positions or {}
	for slot, def in pairs(ns.DB_DEFAULTS.positions) do
		if not SwangThangDB.positions[slot] then
			SwangThangDB.positions[slot] = { point = def.point, relativePoint = def.relativePoint, x = def.x, y = def.y }
		end
	end
end

-- ============================================================
-- Initialization
-- ============================================================
local function OnAddonLoaded()
	MigrateDB()

	-- Detect class once
	local _, class = UnitClass("player")
	ns.playerClass = class
	ns.classConfig = ns.CLASS_CONFIG[class] or { ranged = false, melee = false, dualWield = false }

	-- Class-specific mods first (registers callbacks before bars are created)
	ns.InitClassMods()

	-- Create bars for this class
	ns.InitBars()
end

-- ============================================================
-- Event frame
-- ============================================================
local frame = CreateFrame("Frame", "SwangThangFrame", UIParent)

-- Register events conditionally in ADDON_LOADED once class is known
local function RegisterEvents()
	local cfg = ns.classConfig or {}

	-- Core events for all classes
	frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	frame:RegisterEvent("ADDON_LOADED")

	if cfg.melee then
		frame:RegisterEvent("UNIT_ATTACK_SPEED")
		frame:RegisterEvent("PLAYER_REGEN_DISABLED")
		frame:RegisterEvent("PLAYER_REGEN_ENABLED")
		frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
		frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	end

	if cfg.ranged then
		frame:RegisterEvent("UNIT_SPELLCAST_START")
		frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
		frame:RegisterEvent("START_AUTOREPEAT_SPELL")
		frame:RegisterEvent("STOP_AUTOREPEAT_SPELL")
		frame:RegisterEvent("PLAYER_STARTED_MOVING")
		frame:RegisterEvent("PLAYER_STOPPED_MOVING")
		frame:RegisterEvent("PLAYER_REGEN_DISABLED")
		frame:RegisterEvent("PLAYER_REGEN_ENABLED")
	end

	if cfg.melee and ns.playerClass == "WARRIOR" then
		frame:RegisterEvent("UNIT_SPELLCAST_START")
		frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	end

	if cfg.melee and ns.playerClass == "DRUID" then
		frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	end
end

frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local name = ...
		if name == addonName then
			OnAddonLoaded()
			RegisterEvents()
		end

	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		ns.HandleCLEU()

	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		ns.HandleSpellcastSucceeded(...)

	elseif event == "PLAYER_STARTED_MOVING" then
		ns.isMoving = true

	elseif event == "PLAYER_STOPPED_MOVING" then
		ns.isMoving = false

	elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
		local unit, _, spellId = ...
		if unit == "player" and spellId ~= ns.AUTO_SHOT_ID then
			ns.ResetTimer("ranged")
			if ns.rangedBar then ns.rangedBar:SetAlpha(0) end
		end

	elseif event == "START_AUTOREPEAT_SPELL" then
		-- Hunter starts auto-shooting
		if ns.rangedBar then ns.rangedBar:SetAlpha(1) end

	elseif event == "STOP_AUTOREPEAT_SPELL" then
		ns.ResetTimer("ranged")
		if ns.rangedBar then ns.rangedBar:SetAlpha(0) end

	elseif event == "PLAYER_REGEN_DISABLED" then
		ns.ShowBars()

	elseif event == "PLAYER_REGEN_ENABLED" then
		ns.HideBars()
		ns.ResetTimer("mh")
		ns.ResetTimer("oh")
		ns.ResetTimer("ranged")

	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		ns.UpdateOHBar()

	elseif event == "UPDATE_SHAPESHIFT_FORM" then
		-- Druid form label update handled via classmod callback
		if ns.OnDruidFormChange then
			-- Fire with current form; exact aura handled via CLEU
			local form = GetShapeshiftForm and GetShapeshiftForm() or 0
			if form == 0 then
				ns.OnDruidFormChange(0)
			end
		end
	end
end)

frame:SetScript("OnUpdate", function(self, elapsed)
	ns.OnUpdate(elapsed)
end)
