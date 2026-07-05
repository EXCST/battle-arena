modifier_amaliels_cuirass_passive = modifier_amaliels_cuirass_passive or class({})

function modifier_amaliels_cuirass_passive:IsHidden() return true end
function modifier_amaliels_cuirass_passive:IsPurgable() return false end
function modifier_amaliels_cuirass_passive:RemoveOnDeath() return false end
function modifier_amaliels_cuirass_passive:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_amaliels_cuirass_passive:OnCreated()
	self:OnRefresh()

	if IsServer() then
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		if caster and ability and not caster:IsNull() then
			caster:AddNewModifier(caster, ability, "modifier_amaliels_cuirass_aura_friend", {})
			caster:AddNewModifier(caster, ability, "modifier_amaliels_cuirass_aura_enemy", {})
		end
	end
end

function modifier_amaliels_cuirass_passive:OnRefresh()
	local ability = self:GetAbility()
	if not ability then return end

	self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
	self.bonus_aspeed = ability:GetSpecialValueFor("bonus_aspeed")
	self.bonus_health = ability:GetSpecialValueFor("bonus_health")
	self.bonus_stats = ability:GetSpecialValueFor("bonus_stats")
end

function modifier_amaliels_cuirass_passive:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()
		if caster and not caster:IsNull() then
			caster:RemoveModifierByName("modifier_amaliels_cuirass_aura_friend")
			caster:RemoveModifierByName("modifier_amaliels_cuirass_aura_enemy")
		end
	end
end

function modifier_amaliels_cuirass_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function modifier_amaliels_cuirass_passive:GetModifierPhysicalArmorBonus() return self.bonus_armor end
function modifier_amaliels_cuirass_passive:GetModifierAttackSpeedBonus_Constant() return self.bonus_aspeed end
function modifier_amaliels_cuirass_passive:GetModifierExtraHealthBonus() return self.bonus_health end
function modifier_amaliels_cuirass_passive:GetModifierBonusStats_Strength() return self.bonus_stats end
function modifier_amaliels_cuirass_passive:GetModifierBonusStats_Agility() return self.bonus_stats end
function modifier_amaliels_cuirass_passive:GetModifierBonusStats_Intellect() return self.bonus_stats end

--------------------------------------------------------------------------------

modifier_amaliels_cuirass_aura_friend = modifier_amaliels_cuirass_aura_friend or class({})

function modifier_amaliels_cuirass_aura_friend:IsHidden() return true end
function modifier_amaliels_cuirass_aura_friend:IsPurgable() return false end
function modifier_amaliels_cuirass_aura_friend:RemoveOnDeath() return false end
function modifier_amaliels_cuirass_aura_friend:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_amaliels_cuirass_aura_friend:IsAura() return true end
function modifier_amaliels_cuirass_aura_friend:GetModifierAura() return "modifier_amaliels_cuirass_aura_friend_buff" end
function modifier_amaliels_cuirass_aura_friend:GetAuraRadius()
	local ability = self:GetAbility()
	if ability then return ability:GetSpecialValueFor("friend_radius") end
	return 900
end
function modifier_amaliels_cuirass_aura_friend:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_amaliels_cuirass_aura_friend:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_amaliels_cuirass_aura_friend:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_amaliels_cuirass_aura_friend:GetAuraEntityReject() return false end

--------------------------------------------------------------------------------

modifier_amaliels_cuirass_aura_friend_buff = modifier_amaliels_cuirass_aura_friend_buff or class({})

function modifier_amaliels_cuirass_aura_friend_buff:IsHidden() return false end
function modifier_amaliels_cuirass_aura_friend_buff:IsPurgable() return false end
function modifier_amaliels_cuirass_aura_friend_buff:RemoveOnDeath() return true end

function modifier_amaliels_cuirass_aura_friend_buff:OnCreated() self:OnRefresh() end

function modifier_amaliels_cuirass_aura_friend_buff:OnRefresh()
	local ability = self:GetAbility()
	if not ability then return end
	self.armor = ability:GetSpecialValueFor("bonus_armor_aura")
	self.aspeed = ability:GetSpecialValueFor("bonus_aspeed_aura")
end

function modifier_amaliels_cuirass_aura_friend_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_amaliels_cuirass_aura_friend_buff:GetModifierPhysicalArmorBonus() return self.armor end
function modifier_amaliels_cuirass_aura_friend_buff:GetModifierAttackSpeedBonus_Constant() return self.aspeed end

--------------------------------------------------------------------------------

modifier_amaliels_cuirass_aura_enemy = modifier_amaliels_cuirass_aura_enemy or class({})

function modifier_amaliels_cuirass_aura_enemy:IsHidden() return true end
function modifier_amaliels_cuirass_aura_enemy:IsPurgable() return false end
function modifier_amaliels_cuirass_aura_enemy:RemoveOnDeath() return false end
function modifier_amaliels_cuirass_aura_enemy:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_amaliels_cuirass_aura_enemy:IsAura() return true end
function modifier_amaliels_cuirass_aura_enemy:GetModifierAura() return "modifier_amaliels_cuirass_aura_enemy_debuff" end
function modifier_amaliels_cuirass_aura_enemy:GetAuraRadius()
	local ability = self:GetAbility()
	if ability then return ability:GetSpecialValueFor("enemy_radius") end
	return 900
end
function modifier_amaliels_cuirass_aura_enemy:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_amaliels_cuirass_aura_enemy:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES end
function modifier_amaliels_cuirass_aura_enemy:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end

--------------------------------------------------------------------------------

modifier_amaliels_cuirass_aura_enemy_debuff = modifier_amaliels_cuirass_aura_enemy_debuff or class({})

function modifier_amaliels_cuirass_aura_enemy_debuff:IsHidden() return false end
function modifier_amaliels_cuirass_aura_enemy_debuff:IsDebuff() return true end
function modifier_amaliels_cuirass_aura_enemy_debuff:IsPurgable() return false end
function modifier_amaliels_cuirass_aura_enemy_debuff:RemoveOnDeath() return true end

function modifier_amaliels_cuirass_aura_enemy_debuff:OnCreated() self:OnRefresh() end

function modifier_amaliels_cuirass_aura_enemy_debuff:OnRefresh()
	local ability = self:GetAbility()
	if not ability then return end
	self.disarmor = ability:GetSpecialValueFor("disarmor_aura")
end

function modifier_amaliels_cuirass_aura_enemy_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function modifier_amaliels_cuirass_aura_enemy_debuff:GetModifierPhysicalArmorBonus() return self.disarmor end
