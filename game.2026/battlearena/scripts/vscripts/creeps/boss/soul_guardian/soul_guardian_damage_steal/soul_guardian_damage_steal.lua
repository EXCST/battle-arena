soul_guardian_damage_steal = class({})
local damageStealModifierName = "modifier_soul_guardian_damage_steal"
local modifierInCaster = "modifier_soul_guardian_damage_in_caster"
LinkLuaModifier(damageStealModifierName, "creeps/boss/soul_guardian/soul_guardian_damage_steal/"..damageStealModifierName, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier(modifierInCaster, "creeps/boss/soul_guardian/soul_guardian_damage_steal/"..modifierInCaster, LUA_MODIFIER_MOTION_NONE)

require('lib/ability_kv')
require('creeps/boss/soul_guardian/soul_guardian_helpers')

local DELAY_PARTICLE = "particles/bosses/soul_guardian/soul_guardian_damage_steal/soul_guardian_damage_steal_delay.vpcf"
local STEAL_PARTICLE = "particles/bosses/soul_guardian/soul_guardian_damage_steal/soul_guardian_damage_steal.vpcf"

--------------------------------------------------------------------------------
function soul_guardian_damage_steal:OnSpellStart()
	local caster = self:GetCaster()

	local duration = AbilityKV:Get(self, "duration")
	local radius = AbilityKV:Get(self, "radius")
	local delay_for_start = AbilityKV:Get(self, "delay_for_start")
	local interval = AbilityKV:Get(self, "interval")
	local damage_pct_per_tick = AbilityKV:Get(self, "damage_pct_per_tick")
	local debuff_duration = AbilityKV:Get(self, "debuff_duration")

	-- страховки
	duration = duration > 0 and duration or 5
	radius = radius > 0 and radius or 450
	delay_for_start = delay_for_start > 0 and delay_for_start or 1.8
	interval = interval > 0 and interval or 0.1
	damage_pct_per_tick = damage_pct_per_tick > 0 and damage_pct_per_tick or 0.75
	debuff_duration = debuff_duration > 0 and debuff_duration or 5

	-- стак урона атаки за тик = % от виртуального AD босса (AAF-модель)
	local stacks_per_tick = math.floor(SoulGuardianHelpers:GetAttackDamage() * damage_pct_per_tick / 100)
	if stacks_per_tick < 1 then stacks_per_tick = 1 end

	local particleDelay = ParticleManager:CreateParticle(DELAY_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(particleDelay, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

	Timers:CreateTimer(delay_for_start, SoulGuardianHelpers:SafeTimer(function()
		if not IsValidEntity(caster) or not caster:IsAlive() then
			ParticleManager:DestroyParticle(particleDelay, false)
			ParticleManager:ReleaseParticleIndex(particleDelay)
			return nil
		end

		local particleStealDamage = ParticleManager:CreateParticle(STEAL_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(particleStealDamage, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		caster:AddNewModifier(caster, self, modifierInCaster, { duration = duration })

		local currentTime = 0

		Timers:CreateTimer(0, SoulGuardianHelpers:SafeTimer(function()
			if not IsValidEntity(caster) or not caster:IsAlive() then
				ParticleManager:DestroyParticle(particleDelay, false)
				ParticleManager:ReleaseParticleIndex(particleDelay)
				ParticleManager:DestroyParticle(particleStealDamage, false)
				ParticleManager:ReleaseParticleIndex(particleStealDamage)
				return nil
			end

			local enemies = SoulGuardianHelpers:FindEnemies(caster:GetTeamNumber(), caster:GetAbsOrigin(), radius)

			for _, enemy in ipairs(enemies) do
				local modifier = enemy:FindModifierByName(damageStealModifierName)
				if not modifier then
					modifier = enemy:AddNewModifier(caster, self, damageStealModifierName, { duration = debuff_duration })
				end
				modifier:SetDuration(debuff_duration, true)
				enemy:SetModifierStackCount(damageStealModifierName, nil, modifier:GetStackCount() + stacks_per_tick)
			end

			currentTime = currentTime + interval
			if currentTime < duration and caster:IsAlive() then
				return interval
			else
				ParticleManager:DestroyParticle(particleDelay, false)
				ParticleManager:ReleaseParticleIndex(particleDelay)
				ParticleManager:DestroyParticle(particleStealDamage, false)
				ParticleManager:ReleaseParticleIndex(particleStealDamage)
				return nil
			end
		end))
	end))
end

--------------------------------------------------------------------------------
