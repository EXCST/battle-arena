-- ============================================================
-- BATTLE ARENA — Travaler: Врата Миров (3 стана, как Split Earth
-- Лешрака с шардом Tormented Staff)
-- Три последовательные волны с увеличивающимся радиусом:
-- 240 → 340 → 440. Каждая волна: красный теллур, затем взрыв
-- с иммортал-эффектом Лешрака: урон + стан.
-- ============================================================

travaler_stun = travaler_stun or class({})

local ability = travaler_stun

require('lib/ability_kv')
require('creeps/boss/travaler/travaler_helpers')

LinkLuaModifier("modifier_travaler_stun", "creeps/boss/travaler/modifiers/modifier_travaler_stun", LUA_MODIFIER_MOTION_NONE)

local CAST_GESTURE = ACT_DOTA_CAST_ABILITY_1
local CAST_PARTICLE = "particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_c.vpcf"
local BURST_PARTICLE = "particles/econ/items/leshrac/leshrac_tormented_staff/leshrac_split_tormented.vpcf"
local BEAM_PARTICLE = "particles/econ/items/leshrac/leshrac_tormented_staff/leshrac_split_lightbeam_tormented.vpcf"


function ability:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local center = caster:GetAbsOrigin()

	local radii = {
		AbilityKV:Get(self, "radius_1"),
		AbilityKV:Get(self, "radius_2"),
		AbilityKV:Get(self, "radius_3"),
	}

	local telegraphs = {
		AbilityKV:Get(self, "telegraph_1"),
		AbilityKV:Get(self, "telegraph_2"),
		AbilityKV:Get(self, "telegraph_3"),
	}

	local wave_gap 		= AbilityKV:Get(self, "wave_gap")
	local stun_duration = AbilityKV:Get(self, "stun_duration")

	caster:StartGesture(CAST_GESTURE)

	local p = ParticleManager:CreateParticle(CAST_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(p, 0, center)
	ParticleManager:SetParticleControl(p, 1, Vector(radii[3], radii[3], radii[3]))
	ParticleManager:ReleaseParticleIndex(p)

	caster:EmitSound("Boss_Travaler.Stun.Cast")

	-- три волны с растущим радиусом
	for wave = 1, 3 do
		Timers:CreateTimer((wave - 1) * (telegraphs[wave] + wave_gap), TravalerHelpers:SafeTimer(function()
			if not IsValidEntity(caster) or not caster:IsAlive() then return end

			local radius = radii[wave]

			-- красный теллур волны
			local telegraph = TravalerHelpers:CreateTelegraph(center, radius)

			Timers:CreateTimer(telegraphs[wave], TravalerHelpers:SafeTimer(function()
				TravalerHelpers:DestroyTelegraph(telegraph)

				if not IsValidEntity(caster) or not caster:IsAlive() then return end

				local victims = TravalerHelpers:FindEnemies(caster:GetTeamNumber(), center, radius)

				for _, victim in ipairs(victims) do
					if IsValidEntity(victim) then
						TravalerHelpers:DealDamage(self, caster, victim)
						TravalerHelpers:Stun(victim, caster, self, stun_duration)
					end
				end

				-- иммортал-взрыв Split Earth (Tormented Staff)
				local burst = ParticleManager:CreateParticle(BURST_PARTICLE, PATTACH_WORLDORIGIN, nil)
				ParticleManager:SetParticleControl(burst, 0, center)
				ParticleManager:SetParticleControl(burst, 1, Vector(radius, 1, 1))
				ParticleManager:ReleaseParticleIndex(burst)

				local beam = ParticleManager:CreateParticle(BEAM_PARTICLE, PATTACH_WORLDORIGIN, nil)
				ParticleManager:SetParticleControl(beam, 0, center)
				ParticleManager:SetParticleControl(beam, 1, Vector(radius, 1, 1))
				ParticleManager:ReleaseParticleIndex(beam)

				EmitSoundOnLocationWithCaster(center, "Boss_Travaler.Stun.Burst", caster)
			end))
		end))
	end
end
