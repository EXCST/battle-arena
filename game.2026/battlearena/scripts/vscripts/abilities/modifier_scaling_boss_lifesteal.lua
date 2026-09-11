require('lib/ability_kv')

modifier_scaling_boss_lifesteal = class({})

function modifier_scaling_boss_lifesteal:IsHidden() return false end
function modifier_scaling_boss_lifesteal:IsPurgable() return false end

function modifier_scaling_boss_lifesteal:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_scaling_boss_lifesteal:OnAttackLanded(params)
	if IsServer() then
		if self:GetCaster():PassivesDisabled() then return end
		if params.attacker ~= self:GetParent() then return end
		local target = params.target
		if not target or target:IsNull() then return end

		local pct = AbilityKV:Get(self:GetAbility(), "lifesteal_pct")
		if not pct or pct <= 0 then pct = 20 end

		local heal = params.damage * pct / 100
		self:GetCaster():Heal(heal, self:GetAbility())
	end
end
