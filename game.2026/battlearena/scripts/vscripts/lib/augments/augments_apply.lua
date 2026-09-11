Augments = Augments or {}

-- ============================================================================
-- Battle Arena: Augments вЂ” applying picked cards to the hero
-- ============================================================================

--- Pushes the hero's augment state to the client through the net table.
function Augments:SyncPlayer(player_id, hero)
	CustomNetTables:SetTableValue("augment_store", tostring(player_id), hero.augment_state or {})
end


--- Ensures the override modifier exists and refreshes it.
function Augments:RefreshOverrider(hero)
	local overrider = hero:FindModifierByName("modifier_augment_overrider")
	if not overrider or overrider:IsNull() then
		overrider = hero:AddNewModifier(hero, nil, "modifier_augment_overrider", {})
	end
	if overrider and not overrider:IsNull() then
		overrider:ForceRefresh()
	end
end


--- Refreshes the intrinsic modifier of an ability (and level-reset quirks).
function Augments:RefreshIntrinsics(hero, ability_name)
	local ability = hero:FindAbilityByName(ability_name)
	if not IsValidEntity(ability) or ability:GetLevel() <= 0 then return end

	if ability_name == "gyrocopter_side_gunner_spawn_ability" then
		hero:RemoveModifierByName("modifier_gyrocopter_flak_cannon_scepter")
	end

	ability:RefreshIntrinsicModifier()

	if LEVEL_RESET_ABILITIES[ability:GetAbilityName()] then
		ability:SetLevel(ability:GetLevel())
	end
end


--- Creates or grows a stat record inside the hero state.
---@param entry table|number canonical definition or bundle entry (or raw base)
function Augments:AddOrGrow(hero, ability_name, stat_name, entry, tier)
	hero.augment_state[ability_name] = hero.augment_state[ability_name] or {}

	local record = hero.augment_state[ability_name][stat_name]

	if not record then
		local hero_name = hero:GetUnitName()
		local def = Augments.hero_defs[hero_name] and Augments.hero_defs[hero_name][ability_name]
			and Augments.hero_defs[hero_name][ability_name][stat_name]

		local entry_table = type(entry) == "table" and entry or nil

		record = {
			base = entry_table and entry.base or entry or (def and def.base) or 0,
			picks = 0,
			mode = (entry_table and entry.mode) or (def and def.mode) or AUGMENT_MODE.ADD,
			step = (entry_table and entry.step) or (def and def.step),
			cap = def and def.cap,
			floor = def and def.floor,
			roof = def and def.roof,
			limit = (entry_table and entry.limit) or (def and def.limit),
			limit_base = (entry_table and entry.limit_base) or (def and def.limit_base),
			perks = (entry_table and entry.perks) or (def and def.perks),
		}

		hero.augment_state[ability_name][stat_name] = record
	end

	record.picks = (record.picks or 0) + tier

	Augments:RefreshIntrinsics(hero, ability_name)
end


--- Accumulates a rolled (random) value into the record:
--- ADD -> add_sum, MULT -> mult_product of (1 - uv) terms.
--- The tier scales the gain like AAF (count += rarity): rare = x2, epic = x4.
function Augments:Accumulate(record, rolled, tier, hero, ability_name, stat_name)
	if not rolled then return end

	tier = tier or AUGMENT_TIER.COMMON

	local mode = record.mode or AUGMENT_MODE.ADD

	if mode == AUGMENT_MODE.ADD then
		record.add_sum = (record.add_sum or 0) + rolled * tier
	else
		local base = record.limit_base or AugmentMath:AbilityBaseValue(hero, nil, ability_name, stat_name) or 0
		local limit = record.limit or DEFAULT_MULT_LIMIT

		if base - limit == 0 then base = 0 end

		local uv = math.abs(rolled / (base - limit))
		record.mult_product = (record.mult_product or 1) * (1 - uv) ^ tier
	end
end


--- Applies bundle (linked stat) growth of the picked stat.
function Augments:ApplyBundles(hero, hero_name, ability_name, stat_name, tier)
	local defs = Augments.hero_defs[hero_name]
	if not defs or not defs[ability_name] or not defs[ability_name][stat_name] then return end

	local def = defs[ability_name][stat_name]

	for linked_stat, entry in pairs(def.bundle or {}) do
		Augments:AddOrGrow(hero, ability_name, linked_stat, entry, tier)
	end

	for linked_ability, stats in pairs(def.bundle_abilities or {}) do
		for linked_stat, entry in pairs(stats or {}) do
			Augments:AddOrGrow(hero, linked_ability, linked_stat, entry, tier)
		end
	end
end


--- Grants an ability-stat card.
function Augments:GrantAbility(player_id, ability_name, stat_name, tier, rolled)
	local hero = Augments:GetHero(player_id)
	if not hero then return end

	local hero_name = hero:GetUnitName()
	local defs = Augments.hero_defs[hero_name]
	if not defs or not defs[ability_name] or not defs[ability_name][stat_name] then return end

	local def = defs[ability_name][stat_name]

	Augments:AddOrGrow(hero, ability_name, stat_name, def, tier)
	Augments:Accumulate(hero.augment_state[ability_name][stat_name], rolled, tier, hero, ability_name, stat_name)
	Augments:ApplyBundles(hero, hero_name, ability_name, stat_name, tier)

	Augments:RefreshOverrider(hero)
	Augments:SyncPlayer(player_id, hero)
	Augments:RefreshIntrinsics(hero, ability_name)

	Augments:ApplyToClones(hero, true)
	Augments:RetroSummons(hero, ability_name)

	if ManaPool and hero.mana_pool then
		ManaPool:Recalc(hero)
	end
end


--- Applies a boon (generic card) to the hero.
---@param rolled_factor number|nil the ±25% factor rolled when the hand was created
function Augments:GrantGeneric(player_id, boon_name, tier, rolled_factor)
	local hero = Augments:GetHero(player_id)
	if not hero then return end

	local def = AugmentCatalog.catalog_data[boon_name]
	if not def then return end

	hero.augment_state.generic = hero.augment_state.generic or {}
	local record = hero.augment_state.generic[boon_name]

	if not record then
		record = {
			base = 0,
			picks = 0,
			mode = def.mode,
			cap = def.cap,
			floor = def.floor,
			roof = def.roof,
			limit = def.limit,
			limit_base = def.limit_base,
			step = def.step,
			perks = def.perks,
		}
		hero.augment_state.generic[boon_name] = record
	end

	record.picks = (record.picks or 0) + tier
	record.rolled_factor = rolled_factor or AugmentMath:RollValue(1)

	Augments:SyncPlayer(player_id, hero)

	if def.impl == "modifier" then
		Augments:AddBoonMod(hero, boon_name, record.picks)
	else
		local carrier = hero:FindAbilityByName("ability_augment_carrier")
		if not carrier then
			carrier = hero:AddAbility("ability_augment_carrier")
			if carrier then carrier:SetLevel(1) end
		end
		if carrier then carrier:RefreshIntrinsicModifier() end
	end

	if IsInToolsMode() and record.picks <= 0 then
		hero:RemoveModifierByName("modifier_" .. boon_name)
		hero.augment_state.generic[boon_name] = nil
	end

	Augments:ShareGenericsWithSummons(hero, boon_name, record.picks)

	if hero.CalculateStatBonus then hero:CalculateStatBonus(true) end
	if hero.CalculateGenericBonuses then hero:CalculateGenericBonuses() end

	local engine = hero:FindModifierByName("modifier_augment_engine")
	if engine and not engine:IsNull() then
		engine:ForceRefresh()
		engine:SendBuffRefreshToClients()
	end

	if ManaPool and hero.mana_pool then
		ManaPool:Recalc(hero)
	end
end


--- Adds (or re-stacks) a boon modifier on a unit.
function Augments:AddBoonMod(unit, boon_name, picks)
	local def = AugmentCatalog.catalog_data[boon_name]
	if not def then return end

	if (unit:IsClone() or unit:IsSpiritBear()) and def.skip_clones then return end
	if (unit:IsIllusion() or unit:IsMonkeyKingSoldier()) and def.skip_illusions then return end

	local modifier_name = "modifier_" .. boon_name

	local modifier = unit:FindModifierByName(modifier_name)
	if not modifier or modifier:IsNull() then
		modifier = unit:AddNewModifier(unit, nil, modifier_name, { duration = -1 })
	end

	if not modifier or modifier:IsNull() then
		print("[Augments] AddBoonMod FAILED to create " .. modifier_name .. " on " .. unit:GetUnitName())
		return
	end

	modifier:SetStackCount(picks)
	modifier:ForceRefresh()
end
