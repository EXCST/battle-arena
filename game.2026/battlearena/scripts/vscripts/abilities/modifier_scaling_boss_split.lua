require('lib/ability_kv')

modifier_scaling_boss_split = class({})

function modifier_scaling_boss_split:IsHidden() return false end
function modifier_scaling_boss_split:IsPurgable() return false end

function modifier_scaling_boss_split:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_scaling_boss_split:OnAttackLanded(params)
	if IsServer() then
		if self:GetCaster():PassivesDisabled() then return end
		if params.attacker ~= self:GetParent() then return end
		local target = params.target
		if not target or target:IsNull() then return end

		local radius = AbilityKV:Get(self:GetAbility(), "radius")
		local split_pct = AbilityKV:Get(self:GetAbility(), "split_pct")
		if not radius or radius <= 0 then radius = 250 end
		if not split_pct or split_pct <= 0 then split_pct = 40 end

		local enemies = FindUnitsInRadius(
			self:GetCaster():GetTeamNumber(),
			target:GetAbsOrigin(),
			nil,
			radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			FIND_ANY_ORDER,
			false
		)
		for _, enemy in pairs(enemies) do
			if enemy ~= target then
				local info = {
					victim = enemy,
					attacker = self:GetCaster(),
					damage = params.damage * split_pct / 100,
					damage_type = DAMAGE_TYPE_PHYSICAL,
				}
				ApplyDamage(info)
			end
		end
	end
end
