modifier_phase_boots_2_passive = modifier_phase_boots_2_passive or class({})

function modifier_phase_boots_2_passive:IsHidden() return true end
function modifier_phase_boots_2_passive:IsPurgable() return false end
function modifier_phase_boots_2_passive:RemoveOnDeath() return false end
function modifier_phase_boots_2_passive:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_phase_boots_2_passive:OnCreated()
	self:OnRefresh()
end

function modifier_phase_boots_2_passive:OnRefresh()
	local ability = self:GetAbility()
	if not ability then return end

	self.bonus_movement_speed = ability:GetSpecialValueFor("bonus_movement_speed")
	self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
	end

function modifier_phase_boots_2_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function modifier_phase_boots_2_passive:GetModifierMoveSpeedBonus_Constant() return self.bonus_movement_speed end
function modifier_phase_boots_2_passive:GetModifierPreAttack_BonusDamage() return self.bonus_damage end

--------------------------------------------------------------------------------

modifier_phase_boots_2_active = modifier_phase_boots_2_active or class({})

function modifier_phase_boots_2_active:IsHidden() return false end
function modifier_phase_boots_2_active:IsPurgable() return true end
function modifier_phase_boots_2_active:RemoveOnDeath() return true end
function modifier_phase_boots_2_active:GetAttributes() return MODIFIER_ATTRIBUTE_NONE end

function modifier_phase_boots_2_active:OnCreated()
	self:OnRefresh()
end

function modifier_phase_boots_2_active:OnRefresh()
	local ability = self:GetAbility()
	if not ability then return end

	if self:GetParent():IsRangedAttacker() then
		self.bonus_movement_speed_pct = ability:GetSpecialValueFor("phase_movement_speed_range")
	else
		self.bonus_movement_speed_pct = ability:GetSpecialValueFor("phase_movement_speed")
	end
end

function modifier_phase_boots_2_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
	}
end

function modifier_phase_boots_2_active:GetModifierMoveSpeedBonus_Percentage() return self.bonus_movement_speed_pct end
function modifier_phase_boots_2_active:GetActivityTranslationModifiers() return "phase" end
