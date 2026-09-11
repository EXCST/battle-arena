require('lib/ability_kv')

modifier_scaling_boss_bash = class({})

function modifier_scaling_boss_bash:IsHidden() return false end
function modifier_scaling_boss_bash:IsPurgable() return false end

function modifier_scaling_boss_bash:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_scaling_boss_bash:OnAttackLanded(params)
	if IsServer() then
		if self:GetCaster():PassivesDisabled() then return end
		if params.attacker ~= self:GetParent() then return end
		local target = params.target
		if not target or target:IsNull() then return end
		if target:IsBuilding() then return end

		local chance = AbilityKV:Get(self:GetAbility(), "chance")
		local duration = AbilityKV:Get(self:GetAbility(), "duration")
		local damage_pct = AbilityKV:Get(self:GetAbility(), "bonus_damage_pct")
		if not chance or chance <= 0 then chance = 25 end
		if not duration or duration <= 0 then duration = 1.5 end
		if not damage_pct or damage_pct <= 0 then damage_pct = 15 end

		if not RollPercentage(chance) then return end

		target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_stunned", { duration = duration })
		if damage_pct > 0 then
			local info = {
				victim = target,
				attacker = self:GetCaster(),
				damage = target:GetMaxHealth() * damage_pct / 100,
				damage_type = DAMAGE_TYPE_MAGICAL,
			}
			ApplyDamage(info)
		end
	end
end
