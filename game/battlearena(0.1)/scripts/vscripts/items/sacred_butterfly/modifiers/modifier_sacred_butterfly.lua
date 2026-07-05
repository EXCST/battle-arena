modifier_sacred_butterfly = modifier_sacred_butterfly or class({})

function modifier_sacred_butterfly:IsHidden() return true end
function modifier_sacred_butterfly:IsPurgable() return false end
function modifier_sacred_butterfly:RemoveOnDeath() return false end
function modifier_sacred_butterfly:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_sacred_butterfly:OnCreated()
	self:OnRefresh()
end

function modifier_sacred_butterfly:OnRefresh()
	local ability = self:GetAbility()
	if not ability then return end

	self.bonus_agi = ability:GetSpecialValueFor("bonus_agi")
	self.bonus_dmg = ability:GetSpecialValueFor("bonus_dmg")
	self.bonus_evasion = ability:GetSpecialValueFor("bonus_evasion")
	self.bonus_attackspeed = ability:GetSpecialValueFor("bonus_attackspeed")
	self.bonus_mvspd_pct = ability:GetSpecialValueFor("bonus_mvspd_pct")
end

function modifier_sacred_butterfly:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_EVASION_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_sacred_butterfly:GetModifierBonusStats_Agility() return self.bonus_agi end
function modifier_sacred_butterfly:GetModifierPreAttack_BonusDamage() return self.bonus_dmg end
function modifier_sacred_butterfly:GetModifierEvasion_Constant() return self.bonus_evasion end
function modifier_sacred_butterfly:GetModifierAttackSpeedBonus_Constant() return self.bonus_attackspeed end
function modifier_sacred_butterfly:GetModifierMoveSpeedBonus_Percentage() return self.bonus_mvspd_pct end
