function Blink(keys)
	local caster 		= keys.caster
	local target_point 	= keys.target_points[1]
	local difference	= target_point - caster:GetAbsOrigin()
	local max_range		= keys.BlinkRange
	local radius 		= keys.Radius
	local damage_pct	= keys.Damage / 100

	ProjectileManager:ProjectileDodge(caster)
	
	ParticleManager:CreateParticle("particles/items_fx/blink_dagger_start.vpcf", PATTACH_ABSORIGIN, caster)
	caster:EmitSound("DOTA_Item.BlinkDagger.Activate")

	if difference:Length2D() > max_range then
		target_point = caster:GetAbsOrigin() + difference:Normalized() * max_range
	end

	FindClearSpaceForUnit(caster, target_point, false)
	
	ParticleManager:CreateParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN, caster)

	local units = FindUnitsInRadius(caster:GetTeamNumber(), target_point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NO_INVIS, 0, false) 

	if not units then return end

	for _, target in pairs(units) do
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_leshrac/leshrac_lightning_bolt.vpcf", PATTACH_WORLDORIGIN, target)
		ParticleManager:SetParticleControl(particle, 0, Vector(target:GetAbsOrigin().x, target:GetAbsOrigin().y, target:GetAbsOrigin().z + target:GetBoundingMaxs().z))
		ParticleManager:SetParticleControl(particle, 1, Vector(target:GetAbsOrigin().x, target:GetAbsOrigin().y, 1000))
		ParticleManager:SetParticleControl(particle, 2, Vector(target:GetAbsOrigin().x, target:GetAbsOrigin().y, target:GetAbsOrigin().z + target:GetBoundingMaxs().z))
		ApplyDamage({ victim = target, attacker = caster, damage = target:GetHealth() * damage_pct, damage_type = DAMAGE_TYPE_MAGICAL })
	end

	caster:EmitSound("Hero_Leshrac.Lightning_Storm")
end

function OnTakeDamage(keys)
	local caster   	= keys.caster
	local ability 	= keys.ability
	local cooldown_duration = ability:GetCooldown(ability:GetLevel() - 1)

	if not ability:IsCooldownReady() then return end

	local damage = keys.Damage or 0

	if damage < 100 then return end

	-- Lightning chain to nearby enemies
	local chain_radius = 500
	local chain_damage = damage * 0.5 -- 50% of damage as chain lightning

	local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, chain_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NO_INVIS, 0, false)

	for _, target in pairs(units) do
		if target ~= caster then
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_leshrac/leshrac_lightning_bolt.vpcf", PATTACH_WORLDORIGIN, target)
			ParticleManager:SetParticleControl(particle, 0, Vector(target:GetAbsOrigin().x, target:GetAbsOrigin().y, target:GetAbsOrigin().z + target:GetBoundingMaxs().z))
			ParticleManager:SetParticleControl(particle, 1, Vector(caster:GetAbsOrigin().x, caster:GetAbsOrigin().y, caster:GetAbsOrigin().z + caster:GetBoundingMaxs().z))
			ParticleManager:SetParticleControl(particle, 2, Vector(target:GetAbsOrigin().x, target:GetAbsOrigin().y, target:GetAbsOrigin().z + target:GetBoundingMaxs().z))
			ApplyDamage({ victim = target, attacker = caster, damage = chain_damage, damage_type = DAMAGE_TYPE_MAGICAL })
		end
	end

	caster:EmitSound("Hero_Leshrac.Lightning_Storm")
	ability:StartCooldown(cooldown_duration)
end