local addonName, ns = ...

-- ============================================================
-- Class-specific visual overlays and behavior hooks.
-- Each class mod sets callbacks on ns (OnMeleeSwing, OnRangedSwing,
-- OnBarsCreated, OnDruidFormChange) as needed.
-- ============================================================

local function SetupRetPaladin()
	-- Seal-twist window: gold overlay ~0.4s before swing
	ns.OnBarsCreated = function()
		if not ns.mhBar then return end
		local sealZone = ns.mhBar:CreateTexture(nil, "ARTWORK")
		sealZone:SetColorTexture(1, 0.8, 0, 0.35)
		sealZone:SetPoint("TOPRIGHT")
		sealZone:SetPoint("BOTTOMRIGHT")
		sealZone:SetWidth(0)
		ns.sealTwistZone = sealZone

		local SEAL_WINDOW = 0.4
		local origOnUpdate = ns.OnUpdate
		ns.OnUpdate = function(elapsed)
			origOnUpdate(elapsed)
			if ns.sealTwistZone and ns.timers.mh.state == "swinging" and ns.mhBar then
				local dur = ns.timers.mh.duration
				if dur > 0 then
					local w = (SEAL_WINDOW / dur) * ns.BAR_WIDTH
					ns.sealTwistZone:SetWidth(math.min(w, ns.BAR_WIDTH))
				end
			end
		end
	end
end

local function SetupWarrior()
	-- Slam pending indicator: yellow bar tint and "Slam" label while
	-- the MH timer resets and starts fresh (visual feedback only).
	ns.OnMeleeSwing = function(slot)
		if slot == "mh" and ns.mhBar then
			ns.mhBar:SetStatusBarColor(0.8, 0.8, 0.1, 1)  -- yellow
		end
	end
end

local function SetupEnhShaman()
	-- Windfury 3s ICD annotation.
	-- Track last WF proc via SPELL_EXTRA_ATTACKS (spellId 8232/8235/10486/16362/25505).
	ns.lastWFTime = 0
	-- ns.HandleCLEU is called by bootstrap; ClassMods gets the data via ns callbacks.
	-- For now, record WF ICD start time when extra attacks fire.
	local WF_IDS = { [8232]=true, [8235]=true, [10486]=true, [16362]=true, [25505]=true }
	ns.OnBarsCreated = function()
		-- Overlay logic handled in UpdateMeleeBar annotation; WF ICD display is
		-- a text annotation on the MH bar (implemented as a Phase 6 detail).
	end
end

local function SetupDruid()
	-- Show current form in the MH bar label.
	ns.OnDruidFormChange = function(formSpellId)
		if not ns.mhBar then return end
		local label = ns.DRUID_FORM_IDS[formSpellId] or "Melee"
		ns.mhBar._text:SetText(label)
	end
	ns.OnBarsCreated = function()
		-- Set initial label from current shapeshift form
		local form = GetShapeshiftForm and GetShapeshiftForm() or 0
		if form == 0 and ns.mhBar then
			ns.mhBar._text:SetText("Caster")
		end
	end
end

-- ============================================================
-- Dispatch: pick class mods for the current class
-- ============================================================
function ns.InitClassMods()
	local class = ns.playerClass
	if class == "PALADIN" then
		SetupRetPaladin()
	elseif class == "WARRIOR" then
		SetupWarrior()
	elseif class == "SHAMAN" then
		SetupEnhShaman()
	elseif class == "DRUID" then
		SetupDruid()
	end
	-- HUNTER, ROGUE: no special overlays beyond dual bars
	-- Pure casters: no bars created, no mods needed
end
