possessed_doom_leap = possessed_doom_leap or class({})

local ability = possessed_doom_leap

require('lib/ability_kv')
require('creeps/boss/possessed/possessed_helpers')

LinkLuaModifier("modifier_possessed_leap", "creeps/boss/possessed/modifiers/modifier_possessed_leap", LUA_MODIFIER_MOTION_BOTH)


function ability:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local cast_range = self:GetCastRange(caster:GetAbsOrigin(), caster)
	local target = PossessedHelpers:GetRandomEnemy(caster:GetTeamNumber(), caster:GetAbsOrigin(), cast_range)

	if not IsValidEntity(target) then return end

	local mark = ParticleManager:CreateParticle("particles/econ/items/ogre_magi/ogre_magi_arcana/ogre_magi_arcana_stunned_orbit.vpcf", PATTACH_OVERHEAD_FOLLOW, target)

	local mark_time = AbilityKV:Get(self, "mark_time")

	Timers:CreateTimer(mark_time, function()
		if mark then
			ParticleManager:DestroyParticle(mark, false)
			ParticleManager:ReleaseParticleIndex(mark)
			mark = nil
		end

		if not IsValidEntity(caster) or not caster:IsAlive() then return end

		local target_pos

		if IsValidEntity(target) and target:IsAlive() then
			target_pos = target:GetAbsOrigin()
		else
			target_pos = caster:GetAbsOrigin()
		end

		caster:AddNewModifier(caster, self, "modifier_possessed_leap", {
			duration = AbilityKV:Get(self, "leap_duration"),
			target_x = target_pos.x,
			target_y = target_pos.y,
			target_z = target_pos.z,
		})
	end)

	caster:EmitSound("Boss_Possessed.DevilStomp.Cast")
end
