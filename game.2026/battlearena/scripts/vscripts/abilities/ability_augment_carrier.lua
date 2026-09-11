-- ============================================================================
-- Battle Arena: Augments — boon carrier ability + engine modifier
-- ============================================================================

ability_augment_carrier = ability_augment_carrier or class({})

LinkLuaModifier("modifier_augment_engine", "abilities/ability_augment_carrier", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_augment_status_res_bonus", "lib/augments/boons/modifier_aug_status_res_on_disable", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_augment_armor_shred_marker", "lib/augments/boons/modifier_aug_armor_shred", LUA_MODIFIER_MOTION_NONE)


function ability_augment_carrier:GetIntrinsicModifierName()
	return "modifier_augment_engine"
end


function ability_augment_carrier:OnHeroLevelUp()
	self:RefreshIntrinsicModifier()
	self:GetCaster():CalculateStatBonus(true)
end


modifier_augment_engine = modifier_augment_engine or class({})


function modifier_augment_engine:IsHidden() return true end
function modifier_augment_engine:IsPurgable() return false end
function modifier_augment_engine:RemoveOnDeath() return false end


function modifier_augment_engine:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.serial = self:GetSerialNumber()
	self.state = {}

	self.rune_index = 1
	self.player_id = self.parent:GetPlayerOwnerID()

	self.state_hexed = tostring(MODIFIER_STATE_HEXED)
	self.state_rooted = tostring(MODIFIER_STATE_ROOTED)
	self.state_feared = tostring(MODIFIER_STATE_FEARED)

	self:OnRefresh()

	if not IsServer() then return end
end


function modifier_augment_engine:OnRefresh()
	self.owner_illusion = self.parent:IsIllusion()

	if IsServer() then
		self.owner_illusion = self.parent:IsIllusion() or self.parent:IsTempestDouble()
			or self.parent:IsClone() or self.parent:IsMonkeyKingSoldier()
	end

	if IsServer() and not self.owner_illusion and self.parent:GetUnitLabel() ~= "spirit_bear" then
		self.state = (self.parent.augment_state or {}).generic or {}
	else
		local store = CustomNetTables:GetTableValue("augment_store", tostring(self.player_id)) or {}
		self.state = store.generic or {}
	end

	self:RecalculateUpgradeValues()

	if not IsServer() or self.owner_illusion then return end

	if self.rune_buff_interval > 0 and not self.rune_timer then
		self.rune_timer = Timers:CreateTimer("augment_auto_rune" .. tostring(self.parent:GetEntityIndex()), {
			endTime = 1,
			callback = function()
				return self:ProcessAutoRune()
			end
		})
	end
end


function modifier_augment_engine:OnDestroy()
end


function modifier_augment_engine:RecalculateUpgradeValues()
	self.aug_armor = self:ComputeStat("aug_armor", "armor")
	self.aug_all_attributes = self:ComputeStat("aug_all_attributes", "attributes")
	self.aug_magic_resistance = self:ComputeStat("aug_magic_resistance", "magic_resistance")
	self.aug_attack_speed = self:ComputeStat("aug_attack_speed", "attack_speed")
	self.aug_spell_amp = self:ComputeStat("aug_spell_amp", "spell_amp")
	self.aug_movement_speed = self:ComputeStat("aug_movement_speed", "movement_speed")
	self.aug_status_resistance = self:ComputeStat("aug_status_resistance", "status_resistance")
	self.aug_base_attack_damage_pct = self:ComputeStat("aug_base_attack_damage_pct", "base_attack_damage_pct")
	self.aug_attack_projectile_speed = self:ComputeStat("aug_attack_projectile_speed", "projectile_speed")
	self.aug_heal_amp = self:ComputeStat("aug_heal_amp", "heal_amp")
	self.aug_item_cdr = self:ComputeStat("aug_item_cdr", "cooldown_reduction")

	self.cast_range = self:ComputeStat("aug_reach", "cast_range")
	self.attack_range = self:ComputeStat("aug_reach",
		self.parent:IsRangedAttacker() and "range_increase_ranged" or "range_increase_melee")

	self.crit_chance = self:GetStatForExplicit("aug_critical_strike", "flat_crit_chance")
	self.crit_base = self:GetStatForExplicit("aug_critical_strike", "flat_crit_damage_base")
	self.crit_bonus = self:ComputeStat("aug_critical_strike", "crit_damage_bonus")
	self.crit_damage = self.crit_base + self.crit_bonus

	self.aug_all_attributes_per_level = self:ComputeStat("aug_all_attributes_per_level", "attributes_gain") * self.parent:GetLevel()
	self.aug_primary_attribute_per_level = self:ComputeStat("aug_primary_attribute_per_level", "attribute_gain") * self.parent:GetLevel()
	self.aug_secondary_attributes_per_level = self:ComputeStat("aug_secondary_attributes_per_level", "attributes_gain") * self.parent:GetLevel()

	self.bonus_agi = self.aug_all_attributes + self.aug_all_attributes_per_level
	self.bonus_int = self.aug_all_attributes + self.aug_all_attributes_per_level
	self.bonus_str = self.aug_all_attributes + self.aug_all_attributes_per_level

	local primary = self:GetParentPrimaryAttribute()

	if primary == DOTA_ATTRIBUTE_STRENGTH then
		self.bonus_str = self.bonus_str + self.aug_primary_attribute_per_level
		self.bonus_agi = self.bonus_agi + self.aug_secondary_attributes_per_level
		self.bonus_int = self.bonus_int + self.aug_secondary_attributes_per_level
	elseif primary == DOTA_ATTRIBUTE_AGILITY then
		self.bonus_agi = self.bonus_agi + self.aug_primary_attribute_per_level
		self.bonus_str = self.bonus_str + self.aug_secondary_attributes_per_level
		self.bonus_int = self.bonus_int + self.aug_secondary_attributes_per_level
	elseif primary == DOTA_ATTRIBUTE_INTELLECT then
		self.bonus_int = self.bonus_int + self.aug_primary_attribute_per_level
		self.bonus_agi = self.bonus_agi + self.aug_secondary_attributes_per_level
		self.bonus_str = self.bonus_str + self.aug_secondary_attributes_per_level
	end

	if not IsServer() then return end

	self.aug_manaburn = self:ComputeStat("aug_manaburn", "mana_burned")
	self.aug_manaburn_burned_as_damage = self:GetStatForExplicit("aug_manaburn", "flat_burned_as_damage")
	self.aug_manaburn_illusion_pct = self:GetStatForExplicit("aug_manaburn", "flat_mana_burned_illusion_pct") / 100

	self.rune_buff_interval = self:ComputeStat("aug_auto_rune", "interval")
	self.rune_duration = self:ComputeStat("aug_auto_rune", "rune_duration")

	self.armor_shred = self:ComputeStat("aug_armor_shred", "armor_shred")
	self.armor_shred_per_level = self:ComputeStat("aug_armor_shred", "armor_shred_per_level")
	self.armor_shred_duration = self:GetStatForExplicit("aug_armor_shred", "flat_duration")

	self.status_res_per_stack = self:ComputeStat("aug_status_res_on_disable", "status_res_per_stack")
	self.status_res_stack_duration = self:GetStatForExplicit("aug_status_res_on_disable", "flat_stack_duration")
end


--- Total bonus of a boon stat, including the per-pick rolled factor.
function modifier_augment_engine:ComputeStat(boon_name, stat_name)
	local per_upgrade = self:GetStatForExplicit(boon_name, stat_name)

	local def = AugmentCatalog.catalog_data[boon_name]
	local record = self.state[boon_name]

	local total = AugmentMath:ComputeBonus(self.parent, per_upgrade, self:GetCountFor(boon_name), def or {})

	if record and record.rolled_factor then
		total = total * record.rolled_factor
	end

	return AugmentMath:Round1(total)
end


function modifier_augment_engine:GetCountFor(boon_name)
	return (self.state[boon_name] or {}).picks or 0
end


function modifier_augment_engine:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, -- GetModifierPhysicalArmorBonus
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, -- GetModifierBonusStats_Strength
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS, -- GetModifierBonusStats_Agility
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, -- GetModifierBonusStats_Intellect
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, -- GetModifierMagicalResistanceBonus
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, -- GetModifierAttackSpeedBonus_Constant
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, -- GetModifierSpellAmplify_Percentage
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, -- GetModifierMoveSpeedBonus_Constant
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING, -- GetModifierStatusResistanceStacking
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE, -- GetModifierBaseDamageOutgoing_Percentage
		MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS, -- GetModifierProjectileSpeedBonus
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE, -- GetModifierPercentageCooldown
		MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING, -- GetModifierCastRangeBonusStacking
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS, -- GetModifierAttackRangeBonus

		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE, -- GetModifierHealAmplify_PercentageSource
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, -- GetModifierHPRegenAmplify_Percentage

		MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL, -- GetModifierProcAttack_BonusDamage_Physical
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE, -- GetModifierPreAttack_CriticalStrike
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK, -- GetModifierProcAttack_Feedback
	}
end


function modifier_augment_engine:GetModifierPhysicalArmorBonus() return self.aug_armor or 0 end
function modifier_augment_engine:GetModifierBonusStats_Strength() return self.bonus_str or 0 end
function modifier_augment_engine:GetModifierBonusStats_Agility() return self.bonus_agi or 0 end
function modifier_augment_engine:GetModifierBonusStats_Intellect() return self.bonus_int or 0 end
function modifier_augment_engine:GetModifierMagicalResistanceBonus() return self.aug_magic_resistance or 0 end
function modifier_augment_engine:GetModifierAttackSpeedBonus_Constant() return self.aug_attack_speed or 0 end
function modifier_augment_engine:GetModifierSpellAmplify_Percentage() return self.aug_spell_amp or 0 end
function modifier_augment_engine:GetModifierMoveSpeedBonus_Constant() return self.aug_movement_speed or 0 end
function modifier_augment_engine:GetModifierStatusResistanceStacking() return self.aug_status_resistance or 0 end
function modifier_augment_engine:GetModifierBaseDamageOutgoing_Percentage() return self.aug_base_attack_damage_pct or 0 end
function modifier_augment_engine:GetModifierProjectileSpeedBonus() return self.aug_attack_projectile_speed or 0 end
function modifier_augment_engine:GetModifierHealAmplify_PercentageSource() return self.aug_heal_amp or 0 end
function modifier_augment_engine:GetModifierHealAmplify_PercentageTarget() return self.aug_heal_amp or 0 end
function modifier_augment_engine:GetModifierHPRegenAmplify_Percentage() return self.aug_heal_amp or 0 end
function modifier_augment_engine:GetModifierCastRangeBonusStacking() return self.cast_range end
function modifier_augment_engine:GetModifierAttackRangeBonus() return self.attack_range end


function modifier_augment_engine:GetModifierProcAttack_BonusDamage_Physical(params)
	if self.aug_manaburn <= 0.01 then return end
	if not IsServer() then return end

	local target = params.target
	if not IsValidEntity(target) or target:IsDebuffImmune() then return end

	local parent = self:GetParent()
	if not IsValidEntity(parent) then return end

	local mana_burned = self.aug_manaburn
	if parent:IsIllusion() then mana_burned = mana_burned * self.aug_manaburn_illusion_pct end

	local actual_reduced = target:Script_ReduceMana(mana_burned, nil)

	-- don't double the particle when a diffusal blade does it already
	if not parent:HasItemInInventory("item_diffusal_blade") and not parent:IsIllusion() then
		local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_manaburn.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
		ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(particle)
	end

	return actual_reduced * self.aug_manaburn_burned_as_damage
end


function modifier_augment_engine:GetCritDamage()
	return self.crit_damage / 100
end


function modifier_augment_engine:GetModifierPreAttack_CriticalStrike(params)
	if not IsValidEntity(params.target) then return 0 end
	if params.target:IsBuilding() or params.target:IsOther() then return 0 end
	if not RollPercentage(self.crit_chance) then return 0 end

	return self.crit_damage
end


function modifier_augment_engine:GetModifierPercentageCooldown(params)
	if not IsValidEntity(params.ability) then return 0 end
	if params.ability:IsItem() then return self.aug_item_cdr end

	return 0
end


modifier_augment_engine.rune_cycle = {
	"modifier_rune_arcane",
	"modifier_rune_doubledamage",
	"modifier_rune_haste",
	"modifier_rune_regen"
}

modifier_augment_engine.rune_sound_map = {
	modifier_rune_arcane = "Rune.Arcane",
	modifier_rune_doubledamage = "Rune.DD",
	modifier_rune_haste = "Rune.Haste",
	modifier_rune_regen = "Rune.Regen",
}


function modifier_augment_engine:ProcessAutoRune()
	if not IsValidEntity(self.parent) then return end
	if self.parent:IsClone() then return end
	if not self.parent:IsAlive() then return 2 end

	local rune_name = self.rune_cycle[self.rune_index]
	self.parent:AddNewModifier(self.parent, nil, "modifier_rune_arcane", { duration = self.rune_duration })
	self.parent:AddNewModifier(self.parent, nil, "modifier_rune_doubledamage", { duration = self.rune_duration })
	self.parent:AddNewModifier(self.parent, nil, "modifier_rune_haste", { duration = self.rune_duration })
	self.parent:AddNewModifier(self.parent, nil, "modifier_rune_regen", { duration = self.rune_duration })
	EmitSoundOnEntityForPlayer(self.rune_sound_map[rune_name], self.parent, self.player_id)

	self.rune_index = self.rune_index % #self.rune_cycle + 1

	if self.rune_buff_interval <= 0.01 then return 2 end

	return self.rune_buff_interval
end


function modifier_augment_engine:GetModifierProcAttack_Feedback(params)
	if self.armor_shred <= 0.01 then return end

	local target = params.target
	if not IsValidEntity(self.parent) or not IsValidEntity(target) then return end

	local modifier_owner = self.parent

	if self.owner_illusion then
		modifier_owner = PlayerResource:GetSelectedHeroEntity(self.player_id)
	end

	if not IsValidEntity(modifier_owner) then return end

	-- one marker per hero, so several heroes can stack their shreds separately
	local existing = target:FindModifierByName("modifier_augment_armor_shred_marker")

	if not existing or existing:IsNull() then
		local duration = self.armor_shred_duration * (1 - target:GetStatusResistance())
		existing = target:AddNewModifier(modifier_owner, nil, "modifier_augment_armor_shred_marker", { duration = duration })
	end

	if not existing or existing:IsNull() then return end

	local current_target = self.armor_shred + self.armor_shred_per_level * modifier_owner:GetLevel()
	existing.target = math.max(existing.target or 0, current_target)
	existing:SetStackCount(math.min(existing:GetStackCount() + self.armor_shred, existing.target))
end


function modifier_augment_engine:OnModifierAdded(event)
	if self.status_res_per_stack <= 0.01 then return end
	if not IsValidEntity(event.unit) or event.unit ~= self.parent then return end

	local is_stun = event.added_buff:IsStunDebuff()

	local state = {}
	event.added_buff:CheckStateToTable(state)

	if is_stun or state[self.state_hexed] or state[self.state_feared] or state[self.state_rooted] then
		local bonus = self.parent:FindModifierByName("modifier_augment_status_res_bonus")

		if not bonus or bonus:IsNull() then
			bonus = self.parent:AddNewModifier(self.parent, nil, "modifier_augment_status_res_bonus", { duration = -1 })
		end

		-- Add may fail on invulnerable or dead heroes
		if bonus and not bonus:IsNull() then
			bonus:AddIndependentStack(self.status_res_per_stack, self.status_res_stack_duration, nil, true)
		end
	end
end
