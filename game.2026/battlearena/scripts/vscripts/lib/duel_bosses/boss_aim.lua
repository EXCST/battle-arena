-- lib/duel_bosses/boss_aim.lua
-- Наведение на героя: выбор ближайшей цели + плавный доворот (LockTargetForSpeed).
-- Это главный приём «живости»: босс доворачивается на цель в течение всего
-- прекаста, поэтому снаряды/рывки летят по актуальному направлению.
-- ⚠️ БЕЗ require('lib/timers') — клиентская VM падает (см. AGENTS.md); Timers — глобал

DuelBossAim = DuelBossAim or {}

-- «Умная» цель: сначала самая «наглая» (threat — по кому больше всего бьют босса),
-- иначе ближайшая. Паттерн GetAggroTarget из референса (досье §6/§10).
function DuelBossAim:GetSmartTarget(unit, range, point)
	require('lib/duel_bosses/modifiers/modifier_duel_boss_frame')
	local target = DuelBossFrameUtil:GetBestThreatTarget(unit, range)
	if target and IsValidEntity(target) and target:IsAlive() then
		return target
	end
	return self:GetNearestEnemy(unit, range, point)
end

function DuelBossAim:GetNearestEnemy(unit, range, point)
	local pos = point or unit:GetAbsOrigin()

	local enemies = FindUnitsInRadius(
		unit:GetTeamNumber(),
		pos,
		nil,
		range,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		FIND_CLOSEST,
		false
	)

	for _, enemy in ipairs(enemies) do
		if IsValidEntity(enemy) and enemy:IsAlive() and not enemy:IsCourier() and not enemy:IsInvulnerable() and not enemy:IsOutOfGame() then
			return enemy
		end
	end

	return nil
end

-- Плавный доворот юнита на target в течение duration секунд.
-- turnSpeed: градусов в секунду (90+ = мгновенный доворот).
function DuelBossAim:LockTarget(unit, target, duration, turnSpeed)
	if not IsValidEntity(unit) or not unit:IsAlive() then return end
	if not IsValidEntity(target) then return end

	turnSpeed = turnSpeed or 60
	local interval = 0.03
	local elapsed = 0

	Timers:CreateTimer(interval, function()
		elapsed = elapsed + interval
		if elapsed >= duration or not IsValidEntity(unit) or not unit:IsAlive() or not IsValidEntity(target) or target:IsNull() then
			return nil
		end

		local dir = target:GetAbsOrigin() - unit:GetAbsOrigin()
		dir.z = 0
		if dir:Length2D() <= 1 then return interval end
		dir = dir:Normalized()

		local cur = unit:GetForwardVector()
		cur.z = 0
		if cur:Length2D() <= 0.1 then cur = Vector(1, 0, 0) end

		local angle = DuelBossAim:AngleBetween(cur, dir)
		local step = turnSpeed * interval

		if step >= angle or turnSpeed >= 90 then
			unit:SetForwardVector(dir)
		else
			local rotated = DuelBossAim:RotateVector2D(cur, step * (DuelBossAim:CrossZ(cur, dir) < 0 and -1 or 1))
			unit:SetForwardVector(rotated)
		end

		return interval
	end)
end

-- Угол между двумя 2D-векторами в градусах.
function DuelBossAim:AngleBetween(a, b)
	local cos = math.max(-1, math.min(1, a.x * b.x + a.y * b.y))
	return math.acos(cos) * 180 / math.pi
end

-- Z-компонента векторного произведения (знак поворота).
function DuelBossAim:CrossZ(a, b)
	return a.x * b.y - a.y * b.x
end

-- Поворот 2D-вектора на angleDeg градусов.
function DuelBossAim:RotateVector2D(dir, angleDeg)
	local rad = angleDeg * math.pi / 180
	local cos = math.cos(rad)
	local sin = math.sin(rad)
	return Vector(dir.x * cos - dir.y * sin, dir.x * sin + dir.y * cos, 0)
end