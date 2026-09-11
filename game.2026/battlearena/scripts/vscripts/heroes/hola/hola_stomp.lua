hola_stomp = hola_stomp or class({})


function hola_stomp:IsHiddenWhenStolen() return false end


function hola_stomp:Precache(context)
	PrecacheResource("particle", "particles/econ/items/centaur/centaur_ti6/centaur_ti6_warstomp.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_c.vpcf", context)

	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_earthshaker.vsndevts", context)
end


function hola_stomp:OnSpellStart()
	local caster = self:GetCaster()
	local caster_origin = caster:GetAbsOrigin()

	local radius 			= self:GetSpecialValueFor("radius")
	local heal 				= self:GetSpecialValueFor("heal")
	local damage 			= self:GetSpecialValueFor("damage")
	local heal_percent 		= self:GetSpecialValueFor("heal_percent") / 100.0
	local heal_from_damage 	= self:GetSpecialValueFor("heal_from_damage")

	local caster_int = caster:GetIntellect(true)
	local heal_amount = heal + caster_int * heal_percent

	local allies = FindUnitsInRadius(
		caster:GetTeamNumber(), caster:GetOrigin(), caster, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false
	)

	for _, ally in pairs(allies or {}) do
		ally:Heal(heal_amount, self)
		SendOverheadEventMessage(caster, OVERHEAD_ALERT_HEAL, caster, heal_amount, nil)
	end

	local damage_info = {
		victim = nil,
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self
	}

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(), caster:GetOrigin(), caster, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false
	)

	local accumulated_heal = 0

	for _, enemy in pairs(enemies) do
		if IsValidEntity(enemy) then
			damage_info.victim = enemy
			local damage_dealt = ApplyDamage(damage_info)

			if heal_from_damage > 0 then
				accumulated_heal = accumulated_heal + damage_dealt
			end
		end
	end

	if accumulated_heal > 0 then
		caster:Heal(accumulated_heal, self)
		SendOverheadEventMessage(caster, OVERHEAD_ALERT_HEAL, caster, accumulated_heal, nil)
	end

	caster:EmitSound("Hero_EarthShaker.EchoSlam")

	local part = ParticleManager:CreateParticle("particles/econ/items/centaur/centaur_ti6/centaur_ti6_warstomp.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(part, 0, caster_origin)
	ParticleManager:SetParticleControl(part, 1, Vector(radius, 1, 1))
	ParticleManager:ReleaseParticleIndex(part)

	local part = ParticleManager:CreateParticle("particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_c.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(part, 0, caster_origin)
	ParticleManager:SetParticleControl(part, 1, Vector(radius, 1, 1))
	ParticleManager:ReleaseParticleIndex(part)

	EmitSoundOnClient("keeper_of_the_light_keep_illuminate_0" .. RandomInt(1, 7), caster:GetPlayerOwner())
end