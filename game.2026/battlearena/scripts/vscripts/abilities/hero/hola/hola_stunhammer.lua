hola_stunhammer = hola_stunhammer or class({})


function hola_stunhammer:IsHiddenWhenStolen() return false end
function hola_stunhammer:GetAOERadius() return self:GetSpecialValueFor("bolt_aoe") end


function hola_stunhammer:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_sven/sven_spell_storm_bolt.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_sven/sven_storm_bolt_projectile_explosion.vpcf", context)

	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_sven.vsndevts", context)
end


function hola_stunhammer:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	self:LaunchStunHammer(caster, target, self:GetSpecialValueFor("bounce_count") or 0)

	EmitSoundOnClient("keeper_of_the_light_keep_cast_0" .. RandomInt(1, 3), caster:GetPlayerOwner())
end


function hola_stunhammer:LaunchStunHammer(source, target, bounces)
	source:EmitSound("Hero_Sven.StormBolt")

	local projectile_speed = self:GetSpecialValueFor("bolt_speed")

	ProjectileManager:CreateTrackingProjectile({
		EffectName = "particles/units/heroes/hero_sven/sven_spell_storm_bolt.vpcf",
		Ability = self,
		iMoveSpeed = projectile_speed,
		Source = source,
		Target = target,
		bDodgeable = true,
		bProvidesVision = false,
		ExtraData = {
			bounces_left = bounces
		}
	})
end


function hola_stunhammer:OnProjectileHit_ExtraData(target, location, extra_data)
	if not IsValidEntity(target) then return end

	if target:TriggerSpellReflect(self) then return end
	if target:TriggerSpellAbsorb(self) then return end

	if target:IsMagicImmune() or target:IsInvulnerable() then return end

	target:EmitSound("Hero_Sven.StormBoltImpact")

	local bolt_damage 			= self:GetSpecialValueFor("bolt_damage")
	local bolt_aoe 				= self:GetSpecialValueFor("bolt_aoe")
	local bolt_stun_duration 	= self:GetSpecialValueFor("bolt_stun_duration")
	local bounce_radius 		= self:GetSpecialValueFor("bounce_radius")

	local caster = self:GetCaster()

	local damage_info = {
		victim = target,
		attacker = caster,
		damage = bolt_damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self
	}

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(), target:GetOrigin(), target, bolt_aoe, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false
	)

	for _, enemy in pairs(enemies) do
		if IsValidEntity(enemy) then
			damage_info.victim = enemy
			ApplyDamage(damage_info)

			enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = bolt_stun_duration})
		end
	end

	if extra_data.bounces_left and extra_data.bounces_left > 0 then
		local bounce_targets = FindUnitsInRadius(
			caster:GetTeamNumber(), target:GetAbsOrigin(), nil, bounce_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false
		)

		for _, new_target in pairs(bounce_targets or {}) do
			if IsValidEntity(new_target) and new_target ~= target then
				self:LaunchStunHammer(target, new_target, extra_data.bounces_left - 1)
				break
			end
		end
	end
end