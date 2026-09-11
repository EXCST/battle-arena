-- ============================================================
-- BATTLE ARENA — Travaler helpers
-- Общие хелперы способностей Travaler: урон (ФИКС + % от макс. HP),
-- красные телеграфы-предикторы, зоны-тикеры, поиск врагов, стан.
-- ============================================================

TravalerHelpers = TravalerHelpers or {}

require('lib/ability_kv')


function TravalerHelpers:FindEnemies(team, position, radius)
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


function TravalerHelpers:GetRandomEnemy(team, position, radius)
	local enemies = self:FindEnemies(team, position, radius)

	if #enemies == 0 then return nil end

	return enemies[RandomInt(1, #enemies)]
end


--- Обычный красный теллур-круг (как у possessed). Возвращает массив индексов частиц.
function TravalerHelpers:CreateTelegraph(position, radius)
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


function TravalerHelpers:DestroyTelegraph(points)
	if not points then return end

	for _, p in ipairs(points) do
		ParticleManager:DestroyParticle(p, false)
		ParticleManager:ReleaseParticleIndex(p)
	end
end


--- Урон: ФИКС + % от макс. HP цели (PURE, без усиления заклинаний).
--- Значения читаются из KV способности (ключи damage_flat / damage_pct).
function TravalerHelpers:DealDamage(ability, caster, target)
	return self:DealDamageCustom(ability, caster, target, AbilityKV:Get(ability, "damage_flat"), AbilityKV:Get(ability, "damage_pct"))
end


--- Урон с явными значениями (для зон-тикеров и механик без способности).
function TravalerHelpers:DealDamageCustom(ability, caster, target, flat, pct)
	if not IsValidEntity(target) or not target:IsAlive() then return 0 end

	local damage = flat + target:GetMaxHealth() * pct / 100

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


--- Стан цели модификатором Travaler (стан + фроз, видимый).
function TravalerHelpers:Stun(target, caster, ability, duration)
	if not IsValidEntity(target) or not target:IsAlive() then return end

	target:AddNewModifier(caster, ability, "modifier_travaler_stun", { duration = duration })
end


--- Зона-тикер: частица на позиции + урон %HP каждые tick секунд, duration секунд.
function TravalerHelpers:CreateZone(caster, ability, pos, radius, duration, tick, pct, particle)
	local ticks = math.floor(duration / tick)

	local p = ParticleManager:CreateParticle(particle, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(p, 0, pos)
	ParticleManager:SetParticleControl(p, 1, Vector(radius, radius, radius))

	local elapsed = 0

	Timers:CreateTimer(tick, TravalerHelpers:SafeTimer(function()
		-- частицу гасим ДО ранних return (иначе утечка частиц);
		-- true = мгновенно: loop-ауры вроде doom_bringer_doom_aura плавно не гаснут
		elapsed = elapsed + tick

		if elapsed >= ticks * tick then
			ParticleManager:DestroyParticle(p, true)
			ParticleManager:ReleaseParticleIndex(p)
			return nil
		end

		if not IsValidEntity(caster) or not caster:IsAlive() then
			ParticleManager:DestroyParticle(p, true)
			ParticleManager:ReleaseParticleIndex(p)
			return nil
		end

		local victims = self:FindEnemies(caster:GetTeamNumber(), pos, radius)

		for _, victim in ipairs(victims) do
			self:DealDamageCustom(ability, caster, victim, 0, pct)
		end

		return tick
	end))
end


--- Обёртка таймер-колбэка: ошибка не убивает таймер молча,
--- печатается в лог и колбэк останавливается.
function TravalerHelpers:SafeTimer(fn)
	return function(...)
		local results = { pcall(fn, ...) }

		if not results[1] then
			print("[Travaler] timer error: " .. tostring(results[2]))
			return nil
		end

		table.remove(results, 1)
		return unpack(results)
	end
end
