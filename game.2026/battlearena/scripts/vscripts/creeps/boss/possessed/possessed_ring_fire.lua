possessed_ring_fire = possessed_ring_fire or class({})

local ability = possessed_ring_fire

require('lib/ability_kv')
require('creeps/boss/possessed/possessed_helpers')


function ability:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local center = caster:GetAbsOrigin()

	local waves 		= AbilityKV:Get(self, "waves")
	local segments 		= AbilityKV:Get(self, "segments")
	local base_radius 	= AbilityKV:Get(self, "base_radius")
	local radius_step 	= AbilityKV:Get(self, "radius_step")
	local segment_aoe 	= AbilityKV:Get(self, "segment_aoe")
	local delay 		= AbilityKV:Get(self, "explosion_delay")
	local stun_duration = AbilityKV:Get(self, "stun_duration")
	local wave_gap 		= AbilityKV:Get(self, "wave_gap")

	if caster:HasModifier("modifier_possessed_annihilation") then
		waves = waves + 1
	end

	for wave = 1, waves do
		Timers:CreateTimer((wave - 1) * wave_gap, function()
			if not IsValidEntity(caster) or not caster:IsAlive() then return end

			local radius = base_radius + (wave - 1) * radius_step

			for i = 1, segments do
				local angle = (i - 1) * 2 * math.pi / segments
				local position = center + Vector(math.cos(angle), math.sin(angle), 0) * radius

				self:CreateSegment(caster, position, segment_aoe, delay, stun_duration)
			end
		end)
	end

	caster:EmitSound("Boss_Possessed.MagmaTrails.Cast")
end


function ability:CreateSegment(caster, position, aoe, delay, stun_duration)
	local telegraph = PossessedHelpers:CreateTelegraph(position, aoe)

	Timers:CreateTimer(delay, function()
		PossessedHelpers:DestroyTelegraph(telegraph)

		if not IsValidEntity(caster) or not caster:IsAlive() then return end

		local p = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(p, 0, position)
		ParticleManager:SetParticleControl(p, 1, Vector(aoe, 1, 1))
		ParticleManager:ReleaseParticleIndex(p)

		local enemies = PossessedHelpers:FindEnemies(caster:GetTeamNumber(), position, aoe)

		for _, enemy in pairs(enemies) do
			if IsValidEntity(enemy) then
				PossessedHelpers:DealDamage(self, caster, enemy)
				PossessedHelpers:Stun(enemy, caster, self, stun_duration)
			end
		end

		EmitSoundOnLocationWithCaster(position, "Boss_Possessed.MagmaTrails.Trail", caster)
	end)
end
