Augments = Augments or {}

-- ============================================================================
-- Battle Arena: Augments вЂ” summons, clones and illusions
-- ============================================================================

--- Iterates the tracked summons of a hero, calling the callback for each.
function Augments:TrackSummons(hero, callback)
	local player_id = hero:GetPlayerOwnerID()

	for summon_index, summon in pairs(Augments.tracked_summons[player_id] or {}) do
		if not IsValidEntity(summon) then
			Augments.tracked_summons[player_id][summon_index] = nil
		else
			local summon_name = summon:GetUnitName()
			local params = SUMMON_AUGMENTS_MAP[summon_name]

			SafeCall(callback, summon, summon_name, params)
		end
	end
end


--- Re-applies the stat boosts of a specific ability to all of its living summons.
function Augments:RetroSummons(hero, ability_name)
	Augments:TrackSummons(hero, function(summon, summon_name, params)
		if params and ability_name == params.caster then
			Augments:ApplySummonBoosts(summon, summon_name, hero)
		end
	end)
end


--- Grants the carrier ability to every tracked summon that supports generics.
function Augments:ShareGenericsWithSummons(hero, boon_name, new_picks)
	Augments:TrackSummons(hero, function(summon, summon_name, params)
		if params and params.carry_generics then
			Augments:AttachCarrier(summon)
		end
	end)
end


--- Adds the hidden carrier ability (boon engine source) to a unit.
function Augments:AttachCarrier(unit)
	local carrier = unit:FindAbilityByName("ability_augment_carrier")

	if not carrier then
		carrier = unit:AddAbility("ability_augment_carrier")
		if not carrier then return end
		carrier:SetLevel(1)
	end

	carrier:RefreshIntrinsicModifier()

	if unit.CalculateStatBonus then
		unit:CalculateStatBonus(true)
	end
end


--- Rebuilds the augments of a clone/illusion/tempest from the source hero.
function Augments:ApplyToClone(clone, hero, skip_generics)
	if not clone or not IsValidEntity(clone) or not clone:IsAlive() then return end
	if not IsValidEntity(hero) then hero = clone:GetCloneSource() end
	if not IsValidEntity(hero) then return end

	if not clone:HasModifier("modifier_augment_primary_reader") then
		clone:AddNewModifier(clone, nil, "modifier_augment_primary_reader", { duration = -1 })
	end

	local carrier_ability = clone:FindAbilityByName("ability_augment_carrier")
	if not carrier_ability then
		carrier_ability = clone:AddAbility("ability_augment_carrier")
	end
	if not carrier_ability then return end
	carrier_ability:SetLevel(1)
	carrier_ability:RefreshIntrinsicModifier()

	local overrider = clone:FindModifierByName("modifier_augment_overrider")

	if not overrider or overrider:IsNull() then
		overrider = clone:AddNewModifier(clone, nil, "modifier_augment_overrider", nil)

		for ability_name, _ in pairs(hero.augment_state or {}) do
			Augments:RefreshIntrinsics(clone, ability_name)
		end
	end

	if overrider and not overrider:IsNull() then overrider:ForceRefresh() end

	if not hero.augment_state or not hero.augment_state.generic or skip_generics then return end

	for boon_name, record in pairs(hero.augment_state.generic) do
		local def = AugmentCatalog.catalog_data[boon_name]
		if record and record.picks > 0 and def.impl == "modifier" then
			Augments:AddBoonMod(clone, boon_name, record.picks)
		end
	end
end


--- Applies the clone pipeline to every clone of the hero.
function Augments:ApplyToClones(hero, skip_generics)
	local clones = hero:GetClones()

	for _, clone in pairs(clones) do
		Augments:ApplyToClone(clone, hero, skip_generics)
	end
end


--- Syncs a freshly spawned summon with the caster's ability stats.
function Augments:ApplySummonBoosts(summon, summon_name, owner)
	if not summon or not summon_name then return end

	-- some summons list a player controller as their owner (valve quirk)
	if owner and owner:GetClassname() == "dota_player_controller" then
		owner = owner:GetAssignedHero()
	end
	if not IsValidEntity(owner) then return end

	local params = SUMMON_AUGMENTS_MAP[summon_name]
	if not params then return end

	local ability = owner:FindAbilityByName(params.caster)
	if not ability then return end

	local summon_index = summon:GetEntityIndex()
	local summon_owner_id = owner:GetPlayerOwnerID()

	if params.hp then
		local required_health = ability:GetSpecialValueFor(params.hp)

		if summon:GetBaseMaxHealth() < required_health then
			local base_health = ability:GetLevelSpecialValueNoOverride(params.hp, ability:GetLevel() - 1)

			-- the bear is a full hero: its hp must come from a bonus modifier
			if params.hp_as_bonus then
				local bonus = math.max(required_health - base_health, 0)

				local bonus_mod = summon:AddNewModifier(summon, nil, "modifier_augment_summon_health", { duration = -1 })
				if bonus_mod and not bonus_mod:IsNull() then
					bonus_mod:SetStackCount(bonus)
				end

				if summon.CalculateGenericBonuses then summon:CalculateGenericBonuses() end
				if summon.CalculateStatBonus then summon:CalculateStatBonus(true) end
			else
				local base_max_health_old = summon:GetBaseMaxHealth()
				local max_health_old = summon:GetMaxHealth()
				local health_diff = math.max(max_health_old - base_max_health_old, 0)
				local health_pct = summon:GetHealthPercent()

				summon:SetBaseMaxHealth(required_health)
				summon:SetMaxHealth(required_health + health_diff)

				if summon:IsAlive() then
					summon:SetHealth(summon:GetMaxHealth() * health_pct / 100)
				end
			end
		end
	end

	if params.bonus_hp then
		local new_max_health = summon:GetMaxHealth() + ability:GetSpecialValueFor(params.bonus_hp)
		local health_pct = summon:GetHealthPercent()

		summon:SetBaseMaxHealth(new_max_health)
		summon:SetMaxHealth(new_max_health)

		if summon:IsAlive() then
			summon:SetHealth(summon:GetMaxHealth() * health_pct / 100)
		end
	end

	if params.dmg then
		local required_damage = ability:GetSpecialValueFor(params.dmg)
		if required_damage > 0 then
			summon:SetBaseDamageMin(required_damage)
			summon:SetBaseDamageMax(required_damage)
		end
	end

	if params.arm then
		summon:SetPhysicalArmorBaseValue(ability:GetSpecialValueFor(params.arm))
	end

	if params.day_view then
		summon:SetDayTimeVisionRange(ability:GetSpecialValueFor(params.day_view))
	end

	if params.night_view then
		summon:SetNightTimeVisionRange(ability:GetSpecialValueFor(params.night_view))
	end

	if params.tracked and not (Augments.tracked_summons[summon_owner_id] and Augments.tracked_summons[summon_owner_id][summon_index]) then
		Augments.tracked_summons[summon_owner_id] = Augments.tracked_summons[summon_owner_id] or {}
		Augments.tracked_summons[summon_owner_id][summon_index] = summon
	end

	if params.carry_augments then
		summon:AddNewModifier(owner, nil, "modifier_augment_overrider", nil)

		for i = 0, DOTA_MAX_ABILITIES - 1 do
			local summon_ability = summon:GetAbilityByIndex(i)
			if summon_ability then
				local intrinsic_name = summon_ability:GetIntrinsicModifierName()
				local modifier = summon:FindModifierByName(intrinsic_name)
				if modifier then modifier:ForceRefresh() end
			end
		end
	end

	if params.carry_generics then
		Augments:AttachCarrier(summon)
	end
end
