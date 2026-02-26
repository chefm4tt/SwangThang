local addonName, ns = ...

-- ============================================================
-- Timer State
-- ============================================================
-- Three independent timers: mh (main hand), oh (off hand), ranged.
-- Each timer struct:
--   state              "idle" | "swinging"
--   lastSwing          GetTime() at swing start (latency-adjusted for ranged)
--   duration           weapon speed at swing start
--   speed              cached speed (for haste change detection)
--   extraAttackPending counter for Sword Spec / Windfury suppression

ns.timers = {
	mh     = { state = "idle", lastSwing = 0, duration = 0, speed = 0, extraAttackPending = 0 },
	oh     = { state = "idle", lastSwing = 0, duration = 0, speed = 0, extraAttackPending = 0 },
	ranged = { state = "idle", lastSwing = 0, duration = 0, speed = 0 },
}

-- ============================================================
-- State helpers
-- ============================================================

-- Start a melee or ranged swing for the given slot ("mh", "oh", "ranged").
-- latencyAdjust: seconds to subtract from lastSwing (ranged only)
function ns.StartSwing(slot, latencyAdjust)
	local t = ns.timers[slot]
	if not t then return end

	local now = GetTime()
	local speed

	if slot == "ranged" then
		local s = UnitRangedDamage("player")
		speed = (s and s > 0) and s or 2.0
		t.lastSwing = now - (latencyAdjust or 0)
	else
		local mhSpeed, ohSpeed = UnitAttackSpeed("player")
		if slot == "mh" then
			speed = (mhSpeed and mhSpeed > 0) and mhSpeed or 2.0
		else
			speed = (ohSpeed and ohSpeed > 0) and ohSpeed or 2.0
		end
		t.lastSwing = now
	end

	t.duration = speed
	t.speed    = speed
	t.state    = "swinging"
end

-- Reset a timer slot to idle.
function ns.ResetTimer(slot)
	local t = ns.timers[slot]
	if not t then return end
	t.state    = "idle"
	t.lastSwing = 0
	t.duration  = 0
end

-- Apply parry haste to a melee timer when the player parries an incoming attack.
-- Formula: reduce remaining time by 40% of weapon speed, floor at 20%.
function ns.ApplyParryHaste(slot)
	local t = ns.timers[slot]
	if not t or t.state ~= "swinging" then return end

	local now = GetTime()
	local remaining = (t.lastSwing + t.duration) - now
	local floor = 0.2 * t.duration

	if remaining <= floor then
		return  -- already nearly ready; no change
	end

	local reduction = 0.4 * t.duration
	local newRemaining = math.max(remaining - reduction, floor)
	-- Shift lastSwing so the bar reflects the new remaining time
	t.lastSwing = now + newRemaining - t.duration
end

-- Rescale remaining time proportionally when weapon speed changes mid-swing.
-- Called from OnUpdate when speed difference > threshold.
function ns.RescaleTimer(slot, newSpeed)
	local t = ns.timers[slot]
	if not t or t.state ~= "swinging" or t.duration <= 0 then return end
	if math.abs(t.duration - newSpeed) < 0.01 then return end

	local now = GetTime()
	local remaining = (t.lastSwing + t.duration) - now
	local ratio = newSpeed / t.duration
	local newRemaining = remaining * ratio

	t.duration  = newSpeed
	t.speed     = newSpeed
	t.lastSwing = now + newRemaining - newSpeed
end

-- ============================================================
-- CLEU dispatch
-- ============================================================

-- Returns the current player GUID. Cached at first call since it never changes.
local playerGUID
local function GetPlayerGUID()
	if not playerGUID then
		playerGUID = UnitGUID("player")
	end
	return playerGUID
end

-- Main CLEU handler. Called from the bootstrap OnEvent.
function ns.HandleCLEU()
	local timestamp, subEvent, hideCaster,
	      srcGUID, srcName, srcFlags, srcRaidFlags,
	      dstGUID, dstName, dstFlags, dstRaidFlags = CombatLogGetCurrentEventInfo()

	local pGUID = GetPlayerGUID()

	-- ---- Player is the source ----
	if srcGUID == pGUID then

		if subEvent == "SWING_DAMAGE" then
			-- pos 21 = isOffHand
			local _, _, _, _, _, _, _, _, _, isOffHand = select(12, CombatLogGetCurrentEventInfo())
			local slot = isOffHand and "oh" or "mh"
			local t = ns.timers[slot]
			if (t.extraAttackPending or 0) > 0 then
				t.extraAttackPending = t.extraAttackPending - 1
			else
				ns.StartSwing(slot)
				if ns.OnMeleeSwing then ns.OnMeleeSwing(slot) end
			end

		elseif subEvent == "SWING_MISSED" then
			-- pos 12 = missType, pos 13 = isOffHand
			local missType, isOffHand = select(12, CombatLogGetCurrentEventInfo())
			local slot = isOffHand and "oh" or "mh"
			local t = ns.timers[slot]
			if (t.extraAttackPending or 0) > 0 then
				t.extraAttackPending = t.extraAttackPending - 1
			else
				ns.StartSwing(slot)
				if ns.OnMeleeSwing then ns.OnMeleeSwing(slot) end
			end

		elseif subEvent == "SPELL_CAST_SUCCESS" then
			local spellId = select(12, CombatLogGetCurrentEventInfo())
			if spellId == ns.AUTO_SHOT_ID then
				-- Ranged: latency-adjusted
				local _, _, _, latencyWorld = GetNetStats()
				local latencySec = (latencyWorld or 0) / 1000
				ns.StartSwing("ranged", latencySec)
				if ns.OnRangedSwing then ns.OnRangedSwing() end
			elseif ns.NMA_LOOKUP[spellId] then
				-- NMA fired as SPELL_CAST_SUCCESS (belt-and-suspenders with
				-- UNIT_SPELLCAST_SUCCEEDED; whichever fires first wins)
				ns.StartSwing("mh")
				if ns.OnMeleeSwing then ns.OnMeleeSwing("mh") end
			end

		elseif subEvent == "SPELL_EXTRA_ATTACKS" then
			-- pos 15 = amount
			local amount = select(15, CombatLogGetCurrentEventInfo())
			-- Extra attacks can hit either hand; add to both pending counters
			-- so whichever hand fires next absorbs them.
			ns.timers.mh.extraAttackPending = (ns.timers.mh.extraAttackPending or 0) + (amount or 1)
			ns.timers.oh.extraAttackPending = (ns.timers.oh.extraAttackPending or 0) + (amount or 1)

		elseif subEvent == "SPELL_AURA_APPLIED" then
			-- Druid form change → reset MH timer
			local spellId = select(12, CombatLogGetCurrentEventInfo())
			if ns.DRUID_FORM_IDS and ns.DRUID_FORM_IDS[spellId] then
				ns.ResetTimer("mh")
				ns.druidFormChangeTime = GetTime()
				if ns.OnDruidFormChange then ns.OnDruidFormChange(spellId) end
			end
		end

	-- ---- Player is the destination (incoming parry) ----
	elseif dstGUID == pGUID then
		if subEvent == "SWING_MISSED" then
			local missType = select(12, CombatLogGetCurrentEventInfo())
			if missType == "PARRY" then
				ns.ApplyParryHaste("mh")
			end
		end
	end
end

-- ============================================================
-- UNIT_SPELLCAST_SUCCEEDED handler
-- ============================================================
-- NMA detection via UNIT_SPELLCAST_SUCCEEDED (belt-and-suspenders with CLEU).
-- Slam detection: resets MH timer on cast completion.
function ns.HandleSpellcastSucceeded(unit, _, spellId)
	if unit ~= "player" then return end
	if ns.NMA_LOOKUP[spellId] then
		ns.StartSwing("mh")
		if ns.OnMeleeSwing then ns.OnMeleeSwing("mh") end
	elseif ns.SLAM_IDS[spellId] then
		ns.StartSwing("mh")
		if ns.OnMeleeSwing then ns.OnMeleeSwing("mh") end
	end
end
