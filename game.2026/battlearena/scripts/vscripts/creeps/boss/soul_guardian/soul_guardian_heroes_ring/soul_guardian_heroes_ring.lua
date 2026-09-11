soul_guardian_heroes_ring = class({})
local modifierInCaster = "modifier_soul_guardian_heroes_ring_in_caster"
LinkLuaModifier(modifierInCaster, "creeps/boss/soul_guardian/soul_guardian_heroes_ring/"..modifierInCaster, LUA_MODIFIER_MOTION_NONE)

require('lib/ability_kv')
require('creeps/boss/soul_guardian/soul_guardian_helpers')

local RING_1_PARTICLE = "particles/bosses/soul_guardian/soul_guardian_heroes_ring/soul_guardian_heroes_ring_1.vpcf"
local RING_2_PARTICLE = "particles/bosses/soul_guardian/soul_guardian_heroes_ring/soul_guardian_heroes_ring_2.vpcf"

--------------------------------------------------------------------------------
function soul_guardian_heroes_ring:OnSpellStart()
	local caster = self:GetCaster()

	local flat_base = AbilityKV:Get(self, "flat_base")
	local flat_gain = AbilityKV:Get(self, "flat_gain")
	local pct_max_hp = AbilityKV:Get(self, "pct_max_hp")
	local anti_stack_pct = AbilityKV:Get(self, "anti_stack_pct")
	local circle_radius = AbilityKV:Get(self, "circle_radius")
	local circle_creation_time = AbilityKV:Get(self, "circle_creation_time")
	local detonation_delay = AbilityKV:Get(self, "detonation_delay")

	-- страховки от 0 в KV
	flat_base = flat_base > 0 and flat_base or 3000
	flat_gain = flat_gain > 0 and flat_gain or 250
	pct_max_hp = pct_max_hp > 0 and pct_max_hp or 10
	anti_stack_pct = anti_stack_pct > 0 and anti_stack_pct or 15
	circle_radius = circle_radius > 0 and circle_radius or 800
	circle_creation_time = circle_creation_time > 0 and circle_creation_time or 3.0
	detonation_delay = detonation_delay > 0 and detonation_delay or 2.0

	self.particleFirstCircle = ParticleManager:CreateParticle(RING_1_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(self.particleFirstCircle, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.particleFirstCircle, 1, Vector(circle_radius / circle_creation_time, circle_radius, 1))

	self.particleSecondCircle = ParticleManager:CreateParticle(RING_2_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, caster)

	local detonationTime = circle_creation_time + detonation_delay
	caster:AddNewModifier(caster, self, modifierInCaster, { duration = detonationTime })

	Timers:CreateTimer(detonationTime, SoulGuardianHelpers:SafeTimer(function()
		if not IsValidEntity(caster) or not caster:IsAlive() then
			self:_DestroyRings()
			return nil
		end

		ParticleManager:SetParticleControlEnt(self.particleSecondCircle, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(self.particleSecondCircle, 1, Vector(circle_radius * 2.5, circle_radius, 1))

		local enemies = SoulGuardianHelpers:FindEnemies(caster:GetTeamNumber(), caster:GetAbsOrigin(), circle_radius)

		local herosInCircle = 0
		for _, enemy in ipairs(enemies) do
			if enemy ~= nil and enemy:IsRealHero() then
				herosInCircle = herosInCircle + 1
			end
		end

		-- анти-стак: первый герой «бесплатный», каждый следующий режет урон;
		-- минимум 25% урона (в легаси урон мог стать отрицательным при толпе)
		local mult = 1.0
		if herosInCircle > 1 then
			mult = math.max(0.25, 1.0 - (anti_stack_pct / 100) * (herosInCircle - 1))
		end

		for _, enemy in ipairs(enemies) do
			if enemy ~= nil and enemy:IsRealHero() then
				SoulGuardianHelpers:DealDamageCustom(self, caster, enemy, flat_base * mult, flat_gain * mult, pct_max_hp * mult)
			end
		end

		Timers:CreateTimer(circle_radius / (circle_radius * 2.5) + 0.07, SoulGuardianHelpers:SafeTimer(function()
			self:_DestroyRings()
			return nil
		end))

		return nil
	end))

end

--------------------------------------------------------------------------------

function soul_guardian_heroes_ring:_DestroyRings()
	if self.particleFirstCircle then
		ParticleManager:DestroyParticle(self.particleFirstCircle, false)
		self.particleFirstCircle = nil
	end
	if self.particleSecondCircle then
		ParticleManager:DestroyParticle(self.particleSecondCircle, false)
		self.particleSecondCircle = nil
	end
end
