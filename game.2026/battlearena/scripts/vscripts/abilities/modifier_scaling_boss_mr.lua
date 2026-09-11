require('lib/ability_kv')

modifier_scaling_boss_mr = class({})

function modifier_scaling_boss_mr:IsHidden() return false end
function modifier_scaling_boss_mr:IsPurgable() return false end

function modifier_scaling_boss_mr:DeclareFunctions()
	return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

function modifier_scaling_boss_mr:GetModifierMagicalResistanceBonus(params)
	if self:GetCaster():PassivesDisabled() then return 0 end
	local mr = AbilityKV:Get(self:GetAbility(), "magic_resist")
	if not mr or mr <= 0 then mr = 40 end
	return mr
end
