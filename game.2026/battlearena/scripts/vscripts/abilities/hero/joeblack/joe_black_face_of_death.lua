joe_black_face_of_death = joe_black_face_of_death or class({})


function joe_black_face_of_death:Precache(context)
	PrecacheResource("particle", "particles/econ/items/abaddon/abaddon_alliance/abaddon_death_coil_alliance.vpcf", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_abaddon.vsndevts", context)
end


function joe_black_face_of_death:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end


function joe_black_face_of_death:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local projectile_speed = self:GetSpecialValueFor("projectile_speed")
	local radius = self:GetSpecialValueFor("radius")

	if radius > 0 then
		local units = FindUnitsInRadius(
			caster:GetTeamNumber(),
			target:GetAbsOrigin(),
			caster,
			radius,
			DOTA_UNIT_TARGET_TEAM_BOTH,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false
		)

		for _, unit in pairs(units) do
			self:LaunchProjectile(caster, unit, projectile_speed)
		end
	else
		self:LaunchProjectile(caster, target, projectile_speed)
	end

	caster:EmitSound("Hero_Abaddon.DeathCoil.Cast")

	if self:GetSpecialValueFor("cast_on_ultimate_targets") == 0 then return end

	local ultimate = caster:FindAbilityByName("joe_black_song")
	if not IsValidEntity(ultimate) then return end

	local range_limit = self:GetCastRange(caster:GetAbsOrigin(), nil) + caster:GetCastRangeBonus()

	for _, unit in pairs(ultimate.active_targets or {}) do
		if IsValidEntity(unit) and (caster:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D() <= range_limit then
			self:LaunchProjectile(caster, unit, projectile_speed)
		end
	end
end


function joe_black_face_of_death:LaunchProjectile(source, target, projectile_speed)
	ProjectileManager:CreateTrackingProjectile({
		Target = target,
		Source = source,
		Ability = self,
		EffectName = "particles/econ/items/abaddon/abaddon_alliance/abaddon_death_coil_alliance.vpcf",
		bDodgeable = true,
		bProvidesVision = true,
		iMoveSpeed = projectile_speed,
	    iVisionRadius = 0,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
	})
end


if not IsServer() then return end


function joe_black_face_of_death:OnProjectileHit(target, location)
	if not IsValidEntity(target) then return end

	target:EmitSound("Hero_Abaddon.DeathCoil.Target")

	if target:TriggerSpellAbsorb(self) then return end
	if target:TriggerSpellReflect(self) then return end

	local caster = self:GetCaster()

	local damage_pct = self:GetSpecialValueFor("heal_percent") / 100.0
	local heal = self:GetSpecialValueFor("damage") + caster:GetIntellect(true) * damage_pct

	if target:GetTeamNumber() == caster:GetTeamNumber() then
		target:Heal(heal, self)
		SendOverheadEventMessage(caster, OVERHEAD_ALERT_HEAL, target, heal, nil)
	elseif not target:IsMagicImmune() then
		ApplyDamage({
			victim 		= target,
			attacker 	= caster,
			damage 		= heal,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability 	= self,
		})
	end
end