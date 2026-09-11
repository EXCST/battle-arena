require('lib/ability_kv')

modifier_scaling_boss_crit = class({})

function modifier_scaling_boss_crit:IsHidden() return false end
function modifier_scaling_boss_crit:IsPurgable() return false end

function modifier_scaling_boss_crit:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE }
end

function modifier_scaling_boss_crit:GetModifierPreAttack_CriticalStrike(params)
	if self:GetCaster():PassivesDisabled() then return end
	-- AbilityKV читаем на лету: в OnCreated интринзика GetAbility() ещё nil → 0
	local chance = AbilityKV:Get(self:GetAbility(), "chance")
	local mult = AbilityKV:Get(self:GetAbility(), "crit_mult")
	if not chance or chance <= 0 then chance = 20 end
	if not mult or mult <= 0 then mult = 2.5 end
	if not RollPercentage(chance) then return end
	return mult
end
