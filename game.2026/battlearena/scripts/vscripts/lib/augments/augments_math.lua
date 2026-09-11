-- ============================================================================
-- Battle Arena: Augments — shared math (loaded on server and client VMs)
-- ============================================================================

AugmentMath = AugmentMath or {}
AugmentMath._talent_refresh_registry = {}

-- Special value names that act as aliases for engine pseudo-keys.
-- #AbilityDamage / AbilityDuration are NOT real special values — the engine
-- exposes them separately, so cards stored under "damage"/"duration" are
-- matched to them through this map.
AugmentMath.SPECIAL_ALIASES = {
	["#AbilityDamage"] = "damage",
	["AbilityDuration"] = "duration",
}

--- Resolves an engine special value name to the stat key used by the system.
function AugmentMath:SpecialAlias(special_name)
	return AugmentMath.SPECIAL_ALIASES[special_name] or special_name
end


--- Registers talent names that should trigger an upgrade cache refresh when learned.
function AugmentMath:RegisterTalentRefresh(talents)
	for talent_name, _ in pairs(talents or {}) do
		AugmentMath._talent_refresh_registry[talent_name] = true
	end
end


function AugmentMath:IsTalentRegisteredForRefresh(talent_name)
	return AugmentMath._talent_refresh_registry[talent_name] ~= nil
end


--- Normalizes a raw KV record into the canonical runtime form.
---@param record table raw KV record
---@param name string stat name (ability stat) or boon name (generic)
---@param kind AUGMENT_KIND
---@param ability_name string owning ability name, or "generic"
function AugmentMath:Normalize(record, name, kind, ability_name)
	record.kind = kind
	record.name = name
	record.ability = ability_name or "generic"
	record.mode = MODE_BY_TEXT[record.mode or "ADD"] or AUGMENT_MODE.ADD

	if record.rarity then
		record.floor = TIER_BY_TEXT[record.rarity] or AUGMENT_TIER.COMMON
	end
	if record.floor then
		record.floor = TIER_BY_TEXT[record.floor] or AUGMENT_TIER.COMMON
	end
	if record.roof then
		record.roof = TIER_BY_TEXT[record.roof] or AUGMENT_TIER.COMMON
	end
	record.unlock_at = tonumber(record.unlock_at) or 0

	-- style: engine attack capability constant, stored as its global name in KV
	if type(record.style) == "string" then
		record.style = _G[record.style]
	end

	local default_bundle_mode = AUGMENT_MODE.ADD
	if record.bundle_mode then
		default_bundle_mode = MODE_BY_TEXT[record.bundle_mode] or AUGMENT_MODE.ADD
		record.bundle_mode = nil
	end

	local function normalize_bundle_entry(entry)
		if type(entry) == "table" then
			entry.base = entry.base
			entry.mode = (entry.mode and MODE_BY_TEXT[entry.mode]) or default_bundle_mode
			AugmentMath:RegisterTalentRefresh(entry.perks or {})
		else
			entry = { base = entry, mode = default_bundle_mode }
		end
		return entry
	end

	for stat, entry in pairs(record.bundle or {}) do
		record.bundle[stat] = normalize_bundle_entry(entry)
	end

	for linked_ability, stats in pairs(record.bundle_abilities or {}) do
		for stat, entry in pairs(stats or {}) do
			stats[stat] = normalize_bundle_entry(entry)
		end
	end

	AugmentMath:RegisterTalentRefresh(record.perks or {})
end


--- Default base value of an ability stat (used by MULT growth as the starting point).
function AugmentMath:AbilityBaseValue(hero, ability_level, ability_name, stat_name)
	if not ability_name or not stat_name or ability_name == "generic" then return 0 end

	local ability = hero:FindAbilityByName(ability_name)
	if not IsValidEntity(ability) then return 0 end

	return ability:GetLevelSpecialValueNoOverride(stat_name, ability_level or ability:GetLevel()) or 0
end


--- Rounds a value to 1 decimal place (display truth).
function AugmentMath:Round1(v)
	return math.floor((v or 0) * 10 + 0.5) / 10
end


--- Rolls a per-pick value around the KV base (variance), rounded to 1 decimal.
function AugmentMath:RollValue(value)
	if not value then return value end
	return AugmentMath:Round1(value * (1 + RandomFloat(-PICK_VARIANCE, PICK_VARIANCE)))
end


--- The exact bonus delta this pick will add (matches the applied math).
--- ADD -> the rolled value scaled by tier; MULT -> rounded new total minus rounded current total.
function AugmentMath:PickDelta(hero, def, rolled, rec, tier, ability_level, ability_name, stat_name)
	local mode = def.mode or AUGMENT_MODE.ADD

	if mode == AUGMENT_MODE.ADD then
		return rolled * (tier or AUGMENT_TIER.COMMON)
	end

	local limit = def.limit or DEFAULT_MULT_LIMIT
	local base = def.limit_base or AugmentMath:AbilityBaseValue(hero, ability_level, ability_name, stat_name) or 0

	if base - limit == 0 then return 0 end

	local uv = math.abs(rolled / (base - limit))
	local product_old = rec and rec.mult_product or 1
	local product_new = product_old * (1 - uv) ^ (tier or AUGMENT_TIER.COMMON)

	local total_old = AugmentMath:Round1((limit - base) * (1 - product_old))
	local total_new = AugmentMath:Round1((limit - base) * (1 - product_new))

	return total_new - total_old
end


--- Total bonus of one boon stat at given picks and factor (mirrors the engine).
function AugmentMath:BoonStatTotal(hero, def, stat_name, stat_base, picks, factor)
	local raw = AugmentMath:ComputeBonus(hero, stat_base, picks, def)
	return AugmentMath:Round1(raw * (factor or 1))
end


--- Per-stat deltas a boon pick will add (rounded totals difference).
function AugmentMath:BoonDeltas(hero, def, rec, picks_old, factor_new, rarity)
	local deltas = {}
	local picks_new = picks_old + rarity
	local factor_old = rec and rec.rolled_factor or 1

	for stat_name, stat_base in pairs(def.stats or {}) do
		if stat_name:sub(1, 5) == "flat_" then
			deltas[stat_name] = stat_base
		else
			local total_old = AugmentMath:BoonStatTotal(hero, def, stat_name, stat_base, picks_old, factor_old)
			local total_new = AugmentMath:BoonStatTotal(hero, def, stat_name, stat_base, picks_new, factor_new)
			deltas[stat_name] = total_new - total_old
		end
	end

	return deltas
end


--- Computes the total BONUS granted by the given number of picks.
--- Mirrors the growth formulas: additive (with optional step) and
--- multiplicative (asymptote toward `limit`).
function AugmentMath:ComputeBonus(hero, base, picks, record, ability_level, ability_name, stat_name)
	local result = 0
	local final_multiplier = 1

	-- perks change the base value (+) or scale the final value (x)
	for talent_name, operation in pairs(record.perks or {}) do
		local operator, value

		if type(operation) == "number" then
			operator = "+"
			value = operation
		else
			operator = string.sub(operation, 1, 1)
			value = tonumber(string.sub(operation, 2))
		end

		local talent = hero:FindAbilityByName(talent_name)
		if IsValidEntity(talent) and talent:GetLevel() > 0 then
			if operator == "+" then result = result + value end
			if operator == "x" then final_multiplier = final_multiplier * value end
		end
	end

	local mode = record.mode or AUGMENT_MODE.ADD

	if mode == AUGMENT_MODE.ADD then
		-- randomized picks accumulate into add_sum; when present it wins over base*count
		if record.add_sum then
			return AugmentMath:Round1(result + record.add_sum * final_multiplier)
		end

		result = result + base * picks

		if record.step then
			-- arithmetic progression: picks * ((picks - 1) * step) / 2
			result = result * final_multiplier
			result = result + picks * ((picks - 1) * record.step * final_multiplier) / 2.0
		end

		return AugmentMath:Round1(result)
	end

	-- multiplicative growth toward the limit
	local limit = record.limit or DEFAULT_MULT_LIMIT
	result = result + (record.limit_base or AugmentMath:AbilityBaseValue(hero, ability_level, ability_name, stat_name))

	if result - limit == 0 then return 0 end

	if record.mult_product then
		return AugmentMath:Round1((limit - result) * (1 - record.mult_product))
	end

	local per_pick = math.abs((base * final_multiplier) / (result - limit))
	return AugmentMath:Round1((limit - result) * (1 - (1 - per_pick) ^ picks))
end
