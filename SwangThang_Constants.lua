local addonName, ns = ...

-- ============================================================
-- UI constants
-- ============================================================
ns.BAR_WIDTH   = 200
ns.BAR_HEIGHT  = 20
ns.CAST_WINDOW = 0.5    -- hidden ranged cast time in TBC

-- ============================================================
-- Spell IDs
-- ============================================================
ns.AUTO_SHOT_ID = 75

-- Next-Melee-Attack (NMA) abilities: queue on the MH swing, fire
-- as SPELL_DAMAGE (not SWING_DAMAGE), reset MH timer on land.
-- OH is unaffected by NMAs.
ns.NMA_LOOKUP = {}
local function registerNMAs(ids)
	for _, id in ipairs(ids) do
		ns.NMA_LOOKUP[id] = true
	end
end

-- Heroic Strike (Warrior)
registerNMAs({ 78, 284, 285, 1608, 11564, 11565, 11566, 11567, 25286, 29707, 30324 })

-- Cleave (Warrior)
registerNMAs({ 845, 7369, 11608, 11609, 20569, 25231 })

-- Maul (Druid — Bear)
registerNMAs({ 6807, 6808, 6809, 8972, 9745, 9880, 9881, 26996 })

-- Raptor Strike (Hunter)
registerNMAs({ 2973, 14260, 14261, 14262, 14263, 14264, 14265, 14266, 27014 })

-- Slam (Warrior) — resets MH timer on UNIT_SPELLCAST_SUCCEEDED.
-- In original TBC, Arms Warriors timed Slam immediately after a white hit.
-- Default: reset behavior. Verify via in-game test on Anniversary Edition.
ns.SLAM_IDS = {}
local SLAM_LIST = { 1464, 8820, 11604, 11605, 25241, 25242 }
for _, id in ipairs(SLAM_LIST) do
	ns.SLAM_IDS[id] = true
end

-- Druid form aura IDs (trigger MH timer reset on apply)
ns.DRUID_FORM_IDS = {
	[768]  = "Cat",       -- Cat Form
	[5487] = "Bear",      -- Bear Form
	[9634] = "DireBear",  -- Dire Bear Form
}

-- ============================================================
-- Class configuration
-- ============================================================
-- Determines which bars to create and which events to register.
ns.CLASS_CONFIG = {
	HUNTER  = { ranged = true,  melee = true,  dualWield = false },
	WARRIOR = { ranged = false, melee = true,  dualWield = true  },
	ROGUE   = { ranged = false, melee = true,  dualWield = true  },
	PALADIN = { ranged = false, melee = true,  dualWield = false },
	SHAMAN  = { ranged = false, melee = true,  dualWield = true  },
	DRUID   = { ranged = false, melee = true,  dualWield = false },
	MAGE    = { ranged = false, melee = false, dualWield = false },
	PRIEST  = { ranged = false, melee = false, dualWield = false },
	WARLOCK = { ranged = false, melee = false, dualWield = false },
}

-- ============================================================
-- SavedVariables defaults
-- ============================================================
ns.DB_DEFAULTS = {
	version   = 2,
	showMH    = true,
	showOH    = true,
	positions = {
		mh     = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -120 },
		oh     = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -145 },
		ranged = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -100 },
	},
}
