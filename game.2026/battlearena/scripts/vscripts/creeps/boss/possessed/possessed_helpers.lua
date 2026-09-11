-- ============================================================
-- BATTLE ARENA — Possessed helpers
-- Общие хелперы способностей possessed: урон по формуле
-- ФИКС + % от макс. HP, телеграфы, поиск и случайный выбор врагов.
-- ============================================================

PossessedHelpers = PossessedHelpers or {}

require('lib/ability_kv')

LinkLuaModifier("modifier_possessed_curse_penalty", "creeps/boss/possessed/modifiers/modifier_possessed_curse_penalty", LUA_MODIFIER_MOTION_NONE)


function PossessedHelpers:FindEnemies(team, position, radius)
	return FindUnitsInRadius(
		team,
		position,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		FIND_CLOSEST,
		false
	)
end


function PossessedHelpers:GetRandomEnemy(team, position, radius)
	local enemies = self:FindEnemies(team, position, radius)

	if #enemies == 0 then return nil end

	return enemies[RandomInt(1, #enemies)]
end


--- Красный телеграф-круг. Возвращает массив индексов частиц.
function PossessedHelpers:CreateTelegraph(position, radius)
	local ground = ParticleManager:CreateParticle("particles/ui_mouseactions/tower_range_indicator_alt_ground.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(ground, 0, position)
	ParticleManager:SetParticleControl(ground, 2, position)
	ParticleManager:SetParticleControl(ground, 3, Vector(radius, radius, radius))
	ParticleManager:SetParticleControl(ground, 4, Vector(255, 0, 0))

	local edge = ParticleManager:CreateParticle("particles/ui_mouseactions/tower_range_indicator_alt_edge_sharp.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(edge, 0, position)
	ParticleManager:SetParticleControl(edge, 2, position)
	ParticleManager:SetParticleControl(edge, 3, Vector(radius, radius, radius))
	ParticleManager:SetParticleControl(edge, 4, Vector(255, 0, 0))

	return { ground, edge }
end


function PossessedHelpers:DestroyTelegraph(points)
	if not points then return end

	for _, p in ipairs(points) do
		ParticleManager:DestroyParticle(p, false)
		ParticleManager:ReleaseParticleIndex(p)
	end
end


--- Урон: ФИКС + % от макс. HP цели, чистый, без усиления заклинаний.
--- Умножается на множитель фазы истребления (modifier_possessed_annihilation).
function PossessedHelpers:DealDamage(ability, caster, target)
	local flat = AbilityKV:Get(ability, "damage_flat")
	local pct = AbilityKV:Get(ability, "damage_pct") / 100

	local multiplier = 1

	if caster and caster:HasModifier("modifier_possessed_annihilation") then
		local phase_ability = caster:FindAbilityByName("possessed_annihilation")

		if phase_ability then
			multiplier = AbilityKV:Get(phase_ability, "damage_multiplier") / 100
		end
	end

	local damage = (flat + target:GetMaxHealth() * pct) * multiplier

	ApplyDamage({
		victim = target,
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_PURE,
		damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
		ability = ability,
	})

	return damage
end


--- Стан цели видимым модификатором possessed (орбита оглушения).
function PossessedHelpers:Stun(target, caster, ability, duration)
	if not IsValidEntity(target) or not target:IsAlive() then return end

	target:AddNewModifier(caster, ability, "modifier_possessed_curse_penalty", { duration = duration })
end
