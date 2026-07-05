modifier_dark_edge_cold = modifier_dark_edge_cold or class({})

function modifier_dark_edge_cold:IsHidden() return false end
function modifier_dark_edge_cold:IsPurgable() return false end
function modifier_dark_edge_cold:RemoveOnDeath() return false end
function modifier_dark_edge_cold:DestroyOnExpire() return true end

function modifier_dark_edge_cold:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self:OnRefresh()
end

function modifier_dark_edge_cold:OnRefresh()
	if not IsValidEntity(self.ability) then return end

	self.cold_slow_melee = self.ability:GetSpecialValueFor("cold_slow_melee")
	self.cold_attack_slow_melee = self.ability:GetSpecialValueFor("cold_attack_slow_melee")
	self.cold_slow_ranged = self.ability:GetSpecialValueFor("cold_slow_ranged")
	self.cold_attack_slow_ranged = self.ability:GetSpecialValueFor("cold_attack_slow_ranged")
	self.heal_reduction = -self.ability:GetSpecialValueFor("heal_reduction")
end

function modifier_dark_edge_cold:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, -- GetModifierMoveSpeedBonus_Percentage
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, -- GetModifierAttackSpeedBonus_Constant

		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE, -- GetModifierHealAmplify_PercentageSource
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, -- GetModifierHealAmplify_PercentageTarget
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, -- GetModifierHPRegenAmplify_Percentage
		MODIFIER_CUSTOM_PROPERTY_LIFESTEAL_AMPLIFICATION, -- GetCustomLifestealAmplification
	}
end

function modifier_dark_edge_cold:GetModifierMoveSpeedBonus_Percentage()
	if self.parent:IsRangedAttacker() then
		return self.cold_slow_ranged
	end
	return self.cold_slow_melee
end

function modifier_dark_edge_cold:GetModifierAttackSpeedBonus_Constant()
	if self.parent:IsRangedAttacker() then
		return self.cold_attack_slow_ranged
	end
	return self.cold_attack_slow_melee
end

function modifier_dark_edge_cold:GetModifierHealAmplify_PercentageSource() return self.heal_reduction end
function modifier_dark_edge_cold:GetModifierHealAmplify_PercentageTarget() return self.heal_reduction end
function modifier_dark_edge_cold:GetCustomLifestealAmplification() return self.heal_reduction end
function modifier_dark_edge_cold:GetModifierHPRegenAmplify_Percentage() return self.heal_reduction end
