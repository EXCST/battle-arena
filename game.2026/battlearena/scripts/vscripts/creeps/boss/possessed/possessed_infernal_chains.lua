possessed_infernal_chains = possessed_infernal_chains or class({})

local ability = possessed_infernal_chains

require('lib/ability_kv')
require('creeps/boss/possessed/possessed_helpers')

LinkLuaModifier("modifier_possessed_chains_pull", "creeps/boss/possessed/modifiers/modifier_possessed_chains_pull", LUA_MODIFIER_MOTION_HORIZONTAL)


function ability:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local caster_pos = caster:GetAbsOrigin()
	local cast_range = self:GetCastRange(caster_pos, caster)
	local target = PossessedHelpers:GetRandomEnemy(caster:GetTeamNumber(), caster_pos, cast_range)

	if not IsValidEntity(target) then return end

	local speed = AbilityKV:Get(self, "projectile_speed")

	-- видимый луч цепи босс -> цель (уничтожается при попадании снаряда)
	self.active_lasso = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_flaming_lasso.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControlEnt(self.active_lasso, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(self.active_lasso, 2, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

	local info = {
		EffectName 		= "particles/units/heroes/hero_oracle/oracle_false_promise_dmg.vpcf",
		Ability 		= self,
		vSpawnOrigin 	= caster_pos,
		fStartRadius 	= 70,
		fEndRadius 		= 70,
		vVelocity 		= (target:GetAbsOrigin() - caster_pos):Normalized() * speed,
		fDistance 		= cast_range,
		Source 			= caster,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	}

	ProjectileManager:CreateLinearProjectile(info)

	caster:EmitSound("Boss_Possessed.Curse.Cast")
end


function ability:OnProjectileHit(hTarget, vLocation)
	if not IsServer() then return end

	if self.active_lasso then
		ParticleManager:DestroyParticle(self.active_lasso, false)
		ParticleManager:ReleaseParticleIndex(self.active_lasso)
		self.active_lasso = nil
	end

	if not IsValidEntity(hTarget) then return end

	local caster = self:GetCaster()

	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	local point = caster:GetAbsOrigin()
	local pull_duration = AbilityKV:Get(self, "pull_duration")

	hTarget:AddNewModifier(caster, self, "modifier_possessed_chains_pull", {
		duration = pull_duration,
		point_x = point.x,
		point_y = point.y,
		point_z = point.z,
	})

	PossessedHelpers:DealDamage(self, caster, hTarget)

	return true
end
