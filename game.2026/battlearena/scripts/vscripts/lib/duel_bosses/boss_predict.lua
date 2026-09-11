-- lib/duel_bosses/boss_predict.lua
-- Предиктивные точки: куда босс должен целиться, чтобы попасть в игрока.
-- Приёмы из китайской кастомки:
--   LeadPosition — точка, где герой БУДЕТ (по скорости и направлению движения);
--   FlankPoint   — фланг движения героя (перпендикуляр + 0..30° назад);
--   BehindPoint  — за спину героя (куда он скорее всего отступит).

DuelBossPredict = DuelBossPredict or {}

function DuelBossPredict:RotateVector2D(dir, angleDeg)
	local rad = angleDeg * math.pi / 180
	local cos = math.cos(rad)
	local sin = math.sin(rad)
	return Vector(dir.x * cos - dir.y * sin, dir.x * sin + dir.y * cos, 0)
end

function DuelBossPredict:GetForward2D(hero)
	local fwd = hero:GetForwardVector()
	fwd.z = 0
	if fwd:Length2D() <= 0.1 then
		return Vector(1, 0, 0)
	end
	return fwd:Normalized()
end

-- Точка, где герой будет через flightTime секунд (лид-предиктор).
function DuelBossPredict:LeadPosition(hero, flightTime)
	local pos = hero:GetAbsOrigin()
	-- GetCurrentMovementSpeed в этой сборке не существует (nil) — фолбэк на GetIdealSpeed/константу
	local speed = 350
	if hero.GetIdealSpeed then
		local s = hero:GetIdealSpeed()
		if s and s > 0 then speed = s end
	end
	return pos + self:GetForward2D(hero) * speed * flightTime
end

-- Фланг движения: перпендикуляр к направлению движения героя + случайный
-- доворот «назад» до maxBackwardDeg. Дистанция — distance от героя.
function DuelBossPredict:FlankPoint(hero, distance, maxBackwardDeg)
	local fwd = self:GetForward2D(hero)
	local side = RandomInt(0, 1) == 0 and -90 or 90
	local extra = RandomInt(0, maxBackwardDeg or 30) * (side < 0 and -1 or 1)
	local dir = self:RotateVector2D(fwd, side + extra)

	return hero:GetAbsOrigin() + dir * distance
end

-- Точка за спиной героя (направление его движения назад).
function DuelBossPredict:BehindPoint(hero, distance)
	local fwd = self:GetForward2D(hero)
	return hero:GetAbsOrigin() - fwd * distance
end

-- Случайная точка в кольце [minDist..maxDist] вокруг pos.
function DuelBossPredict:RandomOffset(pos, minDist, maxDist)
	local dir = Vector(RandomFloat(-1, 1), RandomFloat(-1, 1), 0)
	if dir:Length2D() <= 0.01 then dir = Vector(1, 0, 0) end
	dir = dir:Normalized()
	local dist = RandomFloat(minDist, maxDist)
	return pos + dir * dist
end

-- Валидна ли точка для телепорта/движения (на земле и проходима).
function DuelBossPredict:IsWalkable(pos)
	if GridNav:IsTraversable(pos) then
		if not GridNav:IsBlocked(pos) then
			return true
		end
	end
	return false
end