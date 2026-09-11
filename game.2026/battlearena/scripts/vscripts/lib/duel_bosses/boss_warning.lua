-- lib/duel_bosses/boss_warning.lua
-- Теллуры-предикторы (порт контракта warningEffect из китайской кастомки):
--   Line — линейная полоса range_finder_linear_<type>.vpcf
--          CP0=старт, CP1=конец (растёт за время), CP2=Vector(duration, w1, w2),
--          CP15=цвет зелёный→красный. Поддержка follow/getDirection/getStartPosition.
--   Ring — кольцо ability_warning_ring.vpcf
--          CP0=центр, CP1=Vector(radius,0,-speed*1.4), CP2=Vector(duration,0,0),
--          CP15=цвет с миганием в последние 25%.
-- Реализация без thinker'ов: контрольные точки обновляются абсолютными позициями.
-- ⚠️ БЕЗ require('lib/timers') — клиентская VM падает (см. AGENTS.md).

DuelBossWarning = DuelBossWarning or {}

local TICK = 0.03

function DuelBossWarning:SafeTimer(fn)
	return function(...)
		local results = { pcall(fn, ...) }
		if not results[1] then
			print("[DuelBossWarning] timer error: " .. tostring(results[2]))
			return nil
		end
		table.remove(results, 1)
		return unpack(results)
	end
end

--- Линейная полоса-теллур.
--- startPos/endPos — полная длина линии; duration — ПОЛНОЕ время жизни;
--- opts: startWidth, endWidth, type (1|2), follow (старт за кастером),
---       getDirection() -> Vector (динамическое направление, каждый кадр),
---       getStartPosition() -> Vector (динамический старт),
---       growTime — время «вырастания» линии (по умолчанию = duration).
---       Если growTime < duration: линия быстро вырастает и ОСТАЁТСЯ видимой
---       (красной) до конца duration — для скиллов с долгим снарядом/волной.
function DuelBossWarning:Line(unit, ability, startPos, endPos, duration, opts)
	opts = opts or {}

	if duration <= 0 then return end

	local startWidth = opts.startWidth or 128
	local endWidth = opts.endWidth or 128
	local growTime = opts.growTime or duration

	local effect = ParticleManager:CreateParticle(
		"particles/range_finder_linear_" .. tostring(opts.type or 1) .. ".vpcf",
		PATTACH_WORLDORIGIN,
		nil
	)
	ParticleManager:SetParticleShouldCheckFoW(effect, false)

	local baseDir = endPos - startPos
	local fullLength = baseDir:Length2D()
	local baseDirNorm = baseDir
	if fullLength > 0.0001 then
		baseDirNorm = baseDir:Normalized()
	end

	local lastDirection = baseDirNorm
	local lastStartPos = startPos
	local directionLocked = false
	local elapsed = 0

	local function resolveStartPos()
		if opts.getStartPosition then
			local dynamicStart = opts.getStartPosition()
			if dynamicStart ~= nil then
				return dynamicStart
			end
		end
		if opts.follow and IsValidEntity(unit) and unit:IsAlive() then
			return unit:GetAbsOrigin()
		end
		return lastStartPos
	end

	local function update()
		local t = elapsed / growTime
		local clampedT = math.max(0, math.min(1, t))

		lastStartPos = resolveStartPos()
		lastStartPos.z = startPos.z

		if opts.getDirection and not directionLocked then
			local dirVec = opts.getDirection()
			if dirVec ~= nil and dirVec:Length2D() > 0.0001 then
				dirVec.z = 0
				lastDirection = dirVec:Normalized()
			else
				directionLocked = true
			end
		end

		local currentLength = fullLength * clampedT
		local currentEnd = lastStartPos + lastDirection * currentLength
		currentEnd.z = endPos.z

		ParticleManager:SetParticleControl(effect, 0, lastStartPos)
		ParticleManager:SetParticleControl(effect, 1, currentEnd)
		ParticleManager:SetParticleControl(effect, 15, Vector(1, 1 - clampedT, 0))
	end

	ParticleManager:SetParticleControl(effect, 2, Vector(duration, startWidth, endWidth))
	update()

	Timers:CreateTimer(0, DuelBossWarning:SafeTimer(function()
		if not IsValidEntity(unit) or not unit:IsAlive() then
			ParticleManager:DestroyParticle(effect, true)
			ParticleManager:ReleaseParticleIndex(effect)
			return nil
		end

		elapsed = elapsed + TICK

		if elapsed >= duration then
			ParticleManager:SetParticleControl(effect, 15, Vector(1, 0, 0))
			ParticleManager:DestroyParticle(effect, true)
			ParticleManager:ReleaseParticleIndex(effect)
			return nil
		end

		update()
		return TICK
	end))

	return effect
end

--- Кольцо-теллур: центр, радиус, длительность.
--- opts: speed (скорость схлопывания визуала), follow (центр за кастером),
---       getCenter() -> Vector.
function DuelBossWarning:Ring(unit, ability, center, radius, duration, opts)
	opts = opts or {}

	if duration <= 0 or radius <= 0 then return end

	local speed = opts.speed or radius / duration
	local lastCenter = center

	local effect = ParticleManager:CreateParticleForTeam(
		"particles/monster/ability_warning_ring.vpcf",
		PATTACH_WORLDORIGIN,
		nil,
		DOTA_TEAM_GOODGUYS
	)
	ParticleManager:SetParticleShouldCheckFoW(effect, false)

	local function resolveCenter()
		if opts.getCenter then
			local dynamicCenter = opts.getCenter()
			if dynamicCenter ~= nil then
				return dynamicCenter
			end
		end
		if opts.follow and IsValidEntity(unit) and unit:IsAlive() then
			return unit:GetAbsOrigin()
		end
		return lastCenter
	end

	local elapsed = 0

	local function update()
		local t = elapsed / duration
		local clampedT = math.max(0, math.min(1, t))

		lastCenter = resolveCenter()
		lastCenter.z = center.z

		local flashScale = 1
		if t > 0.75 then
			local flashT = (clampedT - 0.75) / 0.2
			local phase = flashT * flashT * math.pi * 2 * 6
			local pulse = (math.sin(phase) + 1) / 2
			flashScale = 1 + pulse * 0.4
		end

		ParticleManager:SetParticleControl(effect, 0, lastCenter)
		ParticleManager:SetParticleControl(effect, 1, Vector(radius, 0, -speed * 1.4))
		ParticleManager:SetParticleControl(effect, 2, Vector(duration, 0, 0))
		ParticleManager:SetParticleControl(effect, 15, Vector(0.7 * flashScale, 0.7 * (1 - clampedT) * flashScale, 0))
	end

	update()

	Timers:CreateTimer(0, DuelBossWarning:SafeTimer(function()
		if not IsValidEntity(unit) or not unit:IsAlive() then
			ParticleManager:DestroyParticle(effect, false)
			ParticleManager:ReleaseParticleIndex(effect)
			return nil
		end

		elapsed = elapsed + TICK

		if elapsed >= duration then
			ParticleManager:SetParticleControl(effect, 15, Vector(1, 0, 0))
			ParticleManager:DestroyParticle(effect, false)
			ParticleManager:ReleaseParticleIndex(effect)
			return nil
		end

		update()
		return TICK
	end))

	return effect
end

--- Красный круг-теллур поверх (наши проверенные частицы, для зон/ударов).
function DuelBossWarning:RedCircle(unit, ability, position, radius, duration)
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

	Timers:CreateTimer(duration, DuelBossWarning:SafeTimer(function()
		ParticleManager:DestroyParticle(ground, false)
		ParticleManager:ReleaseParticleIndex(ground)
		ParticleManager:DestroyParticle(edge, false)
		ParticleManager:ReleaseParticleIndex(edge)
		return nil
	end))

	return { ground, edge }
end

--- Экранный эффект всем командам (затемнение/вспышка на весь экран).
--- Паттерн BS CreateGlobalParticle (проверен в игре на экране ульты артаса):
--- частица на фонтаны каждой команды с PATTACH_EYES_FOLLOW; авто-уничтожение.
function DuelBossWarning:ScreenFX(name, duration)
	if not IsServer() then return end

	local ps = {}
	local attached = 0

	for team = DOTA_TEAM_FIRST, DOTA_TEAM_CUSTOM_MAX do
		local fountain = Entities:FindByName(nil, "dota_fountain_" .. GetTeamName(team))
		if fountain then
			local p = ParticleManager:CreateParticleForTeam(name, PATTACH_EYES_FOLLOW, fountain, team)
			ps[#ps + 1] = p
			attached = attached + 1
		end
	end

	if attached == 0 then
		local p = ParticleManager:CreateParticle(name, PATTACH_EYES_FOLLOW, nil)
		ps[#ps + 1] = p
	end

	Timers:CreateTimer(duration, DuelBossWarning:SafeTimer(function()
		for _, p in ipairs(ps) do
			ParticleManager:DestroyParticle(p, false)
			ParticleManager:ReleaseParticleIndex(p)
		end
		return nil
	end))
end