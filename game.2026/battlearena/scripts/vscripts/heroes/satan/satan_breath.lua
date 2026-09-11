satan_breath = satan_breath or class({})


function satan_breath:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_dragon_knight/dragon_knight_breathe_fire.vpcf", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_dragon_knight.vsndevts", context)
end


function satan_breath:OnSpellStart()
	local caster = self:GetCaster()

	local flame_count = self:GetSpecialValueFor("flame_count")
	local think_time = self:GetSpecialValueFor("think_time")

	local flames_launched = 0

	Timers:CreateTimer(0, function()
		if not caster:IsAlive() then return end

		caster:EmitSound("Hero_DragonKnight.BreathFire")

		self:LaunchProjectile()

		flames_launched = flames_launched + 1

		if flames_launched < flame_count then return think_time end
	end)

	caster:EmitSound("doom_bringer_doom_ability_scorched_0" .. RandomInt(1, 3))
end


function satan_breath:LaunchProjectile(velocity)
	local caster = self:GetCaster()

	local start_radius 	= self:GetSpecialValueFor("start_radius")
	local end_radius 	= self:GetSpecialValueFor("end_radius")
	local range 		= self:GetSpecialValueFor("range")
	local speed 		= self:GetSpecialValueFor("speed")

	if not velocity then velocity = caster:GetForwardVector() * speed end

	ProjectileManager:CreateLinearProjectile({
		EffectName 		= "particles/units/heroes/hero_dragon_knight/dragon_knight_breathe_fire.vpcf",
		Ability 		= self,
		vSpawnOrigin 	= caster:GetOrigin(),
		vVelocity 		= velocity,
		fDistance 		= range,
		fStartRadius 	= start_radius,
		fEndRadius 		= end_radius,
		Source 			= caster,
		bHasFrontalCone = true,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	})
end


function satan_breath:OnProjectileHit(target, location)
	if not IsServer() or not IsValidEntity(target) then return end

	local caster = self:GetCaster()

	local base_damage = self:GetSpecialValueFor("damage")
	local str_mult = self:GetSpecialValueFor("damage_from_str") / 100.0
	local creep_mult = self:GetSpecialValueFor("creep_multiplier")

	local damage = base_damage + caster:GetStrength() * str_mult

	local damage_table = {
		victim 		= target,
		attacker 	= caster,
		damage 		= damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability 	= self
	}

	if target:IsCreep() and not target:IsAncient() and not target:IsSummoned() then
		damage_table.damage = damage * creep_mult
	end

	ApplyDamage(damage_table)
end
