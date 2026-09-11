require('lib/ability_kv')

modifier_scaling_boss_evasion = class({})

function modifier_scaling_boss_evasion:IsHidden() return false end
function modifier_scaling_boss_evasion:IsPurgable() return false end

function modifier_scaling_boss_evasion:DeclareFunctions()
	return { MODIFIER_PROPERTY_EVASION_CONSTANT }
end

function modifier_scaling_boss_evasion:GetModifierEvasion_Constant(params)
	if self:GetCaster():PassivesDisabled() then return 0 end
	local evasion = AbilityKV:Get(self:GetAbility(), "evasion_pct")
	if not evasion or evasion <= 0 then evasion = 30 end
	return evasion
end
