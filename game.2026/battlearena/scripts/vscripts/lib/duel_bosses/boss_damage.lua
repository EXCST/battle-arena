-- lib/duel_bosses/boss_damage.lua
-- Урон дуэльных боссов: % от макс. HP цели (PURE, без усиления) — паттерн MonsterDamage.
-- Плюс стан через движковый modifier_stunned + видимый generic_stunned.

DuelBossDamage = DuelBossDamage or {}

function DuelBossDamage:Deal(ability, caster, victim, pct, flat)
	if not IsValidEntity(victim) or not victim:IsAlive() then return 0 end

	local damage = (flat or 0) + victim:GetMaxHealth() * (pct or 0) / 100

	ApplyDamage({
		victim = victim,
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_PURE,
		damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
		ability = ability,
	})

	return damage
end

function DuelBossDamage:DealToArea(ability, caster, pos, radius, pct, flat, team)
	local victims = FindUnitsInRadius(
		team or caster:GetTeamNumber(),
		pos,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		FIND_CLOSEST,
		false
	)

	for _, victim in ipairs(victims) do
		if IsValidEntity(victim) and victim:IsAlive() and not victim:IsCourier() then
			self:Deal(ability, caster, victim, pct, flat)
		end
	end

	return #victims
end

function DuelBossDamage:Stun(target, caster, ability, duration)
	if not IsValidEntity(target) or not target:IsAlive() then return end
	if duration <= 0 then return end

	target:AddNewModifier(caster, ability, "modifier_stunned", { duration = duration })

	-- generic_stunned.vpcf в этой сборке удалён (invalid particle) — рабочий аналог ogre arcana
	local p = ParticleManager:CreateParticle("particles/econ/items/ogre_magi/ogre_magi_arcana/ogre_magi_arcana_stunned_orbit.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
	Timers:CreateTimer(duration, function()
		ParticleManager:DestroyParticle(p, false)
		ParticleManager:ReleaseParticleIndex(p)
		return nil
	end)
end