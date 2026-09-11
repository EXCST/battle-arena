-- ============================================================================
-- Battle Arena: Augments — ability stat override controller
-- ============================================================================

modifier_augment_overrider = modifier_augment_overrider or class({})


function modifier_augment_overrider:IsHidden() return true end
function modifier_augment_overrider:IsPurgable() return false end
function modifier_augment_overrider:RemoveOnDeath() return false end
function modifier_augment_overrider:IsPermanent() return true end


-- Abilities whose damage is driven by AbilityDamage (engine pseudo-key), and
-- whose base damage depends on distance or similar — spell amp workaround below
-- would otherwise double-apply.
SPELL_AMP_EXEMPT = {
	storm_spirit_ball_lightning = true,
}

-- Abilities where the lvl 20 talent isn't in AbilityValues, so the passed
-- damage must be used as the baseline.
SPELL_AMP_PASSED_DAMAGE = {
	winter_wyvern_splinter_blast = true,
}


function modifier_augment_overrider:OnCreated()
	self.parent = self:GetParent()

	if IsServer() then
		-- OnStackCountChanged is not invoked on the client when changed on the server,
		-- so the state is synced through the transmitter data
		self:SetHasCustomTransmitterData(true)
	end

	self:OnRefresh()
end


function modifier_augment_overrider:OnRefresh()
	self.cache = {}
	local player_id = self.parent:GetPlayerOwnerID()
	self.source_player_id = player_id

	if not IsServer() then return end

	local owner_hero = PlayerResource:GetSelectedHeroEntity(player_id)
	if not IsValidEntity(owner_hero) then return end

	if owner_hero ~= self.parent then
		-- an illusion can be of another hero: it inherits that hero's augments,
		-- not the owner's
		local parent_name = self.parent:GetUnitName()
		if self.parent:IsHero() and not self.parent:IsSpiritBear() and parent_name ~= owner_hero:GetUnitName() then
			local actual_owner = GetIllusionSource(self.parent)
			if not actual_owner then return end

			self.parent.augment_state = actual_owner.augment_state or {}
			self.source_player_id = actual_owner:GetPlayerOwnerID()
		else
			self.parent.augment_state = owner_hero.augment_state or {}
		end
	end

	self:SendBuffRefreshToClients()
end


function modifier_augment_overrider:AddCustomTransmitterData()
	return {
		source_player_id = self.source_player_id,
	}
end


function modifier_augment_overrider:HandleCustomTransmitterData(data)
	self.source_player_id = data.source_player_id
	self.parent = self.parent or self:GetParent()
	self.parent.augment_state = CustomNetTables:GetTableValue("augment_store", tostring(self.source_player_id)) or {}
	self.cache = {}
end


function modifier_augment_overrider:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
		MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
	}
end


function modifier_augment_overrider:GetModifierOverrideAbilitySpecial(params)
	if not self.parent or self.parent:IsNull() then return 0 end
	if not params.ability then return 0 end
	if params.ability:IsItem() then return 0 end
	if not self.parent.augment_state then return 0 end
	if string.find(params.ability_special_value, "scepter") and not self:GetParent():HasScepter() then return 0 end

	local ability_name = params.ability:GetAbilityName()
	local stat_name = AugmentMath:SpecialAlias(params.ability_special_value)

	if not self.parent.augment_state[ability_name]
	or not self.parent.augment_state[ability_name][stat_name]
	then
		return 0
	end

	return 1
end


function modifier_augment_overrider:GetModifierOverrideAbilitySpecialValue(params)
	if not params.ability or params.ability:IsNull() then return end

	local ability_name = params.ability:GetAbilityName()
	local special_value_name = params.ability_special_value
	local special_value_level = params.ability_special_level

	local base_value = params.ability:GetLevelSpecialValueNoOverride(special_value_name, special_value_level)
	local stat_name = AugmentMath:SpecialAlias(special_value_name)

	if not self.parent.augment_state[ability_name]
	or not self.parent.augment_state[ability_name][stat_name]
	then
		return base_value
	end

	if self.cache[ability_name] and self.cache[ability_name][stat_name]
	and self.cache[ability_name][stat_name][special_value_level]
	then
		return base_value + self.cache[ability_name][stat_name][special_value_level]
	end

	local record = self.parent.augment_state[ability_name][stat_name]

	local added_value = AugmentMath:ComputeBonus(
		self.parent, record.base, record.picks, record, special_value_level, ability_name, stat_name
	)

	self.cache[ability_name] = self.cache[ability_name] or {}
	self.cache[ability_name][stat_name] = self.cache[ability_name][stat_name] or {}
	self.cache[ability_name][stat_name][special_value_level] = added_value

	return base_value + added_value
end


function modifier_augment_overrider:GetModifierPercentageCooldown(params)
	if not params.ability or params.ability:IsItem() then return 0 end
	if not self.parent.augment_state then return 0 end

	local ability_name = params.ability:GetAbilityName()

	if not self.parent.augment_state[ability_name]
	or not self.parent.augment_state[ability_name].cd_mana
	then
		return 0
	end

	if self.cache[ability_name] and self.cache[ability_name].cd_mana then
		return self.cache[ability_name].cd_mana
	end

	local record = self.parent.augment_state[ability_name].cd_mana

	local added_value = AugmentMath:ComputeBonus(self.parent, record.base, record.picks, record)

	self.cache[ability_name] = self.cache[ability_name] or {}
	self.cache[ability_name].cd_mana = added_value

	return added_value
end


function modifier_augment_overrider:GetModifierPercentageManacostStacking(params)
	return self:GetModifierPercentageCooldown(params)
end


--- Spell amp workaround: applies damage upgrades to abilities driven by
--- AbilityDamage (can't be overridden directly — works on the server only).
function modifier_augment_overrider:GetModifierSpellAmplify_Percentage(params)
	if IsClient() then return 0 end
	if self.spell_amp_lock then return 0 end

	local attacker = self:GetParent()
	local ability = params.inflictor
	if not IsValidEntity(ability) or not IsValidEntity(attacker) then return 0 end

	local ability_name = ability:GetAbilityName()

	local ability_state = attacker.augment_state and attacker.augment_state[ability_name] or {}
	if not ability_state or not ability_state.damage then return 0 end

	-- discard damage instances that don't come from AbilityDamage
	if params.original_damage ~= ability:GetAbilityDamage()
	and not SPELL_AMP_EXEMPT[ability_name]
	and not SPELL_AMP_PASSED_DAMAGE[ability_name]
	then
		return 0
	end

	local ability_damage_kv = ability:GetAbilityDamage()
	local ability_damage_special = ability:GetSpecialValueFor("damage")

	if SPELL_AMP_PASSED_DAMAGE[ability_name] then
		ability_damage_kv = params.original_damage
	end

	if ability_damage_kv and (not ability_damage_special or ability_damage_special == 0) then
		local damage_record = ability_state.damage or {}

		local base = damage_record.base
		local picks = damage_record.picks

		if base and picks then
			self.spell_amp_lock = true
			local current_spell_amp = attacker:GetSpellAmplification(false)
			self.spell_amp_lock = false

			local upgrade_value = AugmentMath:ComputeBonus(
				attacker, base, picks, damage_record, ability:GetLevel(), ability_name, "damage"
			)

			return upgrade_value * 100 * (1 + current_spell_amp) / ability_damage_kv
		end
	end

	return 0
end
