-- lib/duel_bosses/boss_motion.lua
-- Движение боссов «как у игрока»: линейные моверы и безье-дуги (прыжки).
-- Реализовано через SetAbsOrigin-тики (паттерн моторов possessed/travaler),
-- с ранним стопом по колбэку и FindClearSpace на финише.
-- ⚠️ БЕЗ require('lib/timers') — клиентская VM падает (см. AGENTS.md);
-- Timers — глобал, определён addon_game_mode.lua на сервере.

DuelBossMotion = DuelBossMotion or {}

local TICK = 0.03

-- Линейное движение unit в dest за duration.
-- callback(unit, pos) — вызывается каждый тик; вернул true → ранний стоп.
function DuelBossMotion:Mover(unit, dest, duration, callback, force)
	if not IsValidEntity(unit) or not unit:IsAlive() then return end

	local start = unit:GetAbsOrigin()
	local dist = (dest - start):Length2D()

	if dist < 1 then
		if callback then callback(unit, dest) end
		return
	end

	unit:InterruptMotionControllers(true)
	unit:Stop()

	local t = 0
	Timers:CreateTimer(TICK, function()
		t = t + TICK

		if not IsValidEntity(unit) or not unit:IsAlive() then return nil end

		local k = math.min(1, t / duration)
		local pos = start + (dest - start) * k

		unit:SetAbsOrigin(pos)

		if callback then
			local ok, stop = pcall(callback, unit, pos)
			if not ok then
				print("[DuelBossMotion] callback error: " .. tostring(stop))
			elseif stop then
				return nil
			end
		end

		if t >= duration then
			FindClearSpaceForUnit(unit, dest, true)
			return nil
		end

		return TICK
	end)
end

-- Безье-дуга (квадратичная): start → control → end. Для прыжков/подлётов.
-- callback(unit, pos) как у Mover.
function DuelBossMotion:Bezier(unit, start, control, endPos, duration, callback)
	if not IsValidEntity(unit) or not unit:IsAlive() then return end

	unit:InterruptMotionControllers(true)
	unit:Stop()

	local t = 0
	Timers:CreateTimer(TICK, function()
		t = t + TICK

		if not IsValidEntity(unit) or not unit:IsAlive() then return nil end

		local k = math.min(1, t / duration)
		local inv = 1 - k
		local pos = start * (inv * inv) + control * (2 * inv * k) + endPos * (k * k)

		unit:SetAbsOrigin(pos)

		if callback then
			local ok, stop = pcall(callback, unit, pos)
			if not ok then
				print("[DuelBossMotion] bezier callback error: " .. tostring(stop))
			elseif stop then
				return nil
			end
		end

		if t >= duration then
			FindClearSpaceForUnit(unit, endPos, true)
			return nil
		end

		return TICK
	end)
end

-- Отброс: юнит летит ОТ sourcePos на distance по дуге высотой height.
function DuelBossMotion:KnockBack(unit, sourcePos, distance, duration, height, stunDuration, ability)
	if not IsValidEntity(unit) or not unit:IsAlive() then return end

	local dir = unit:GetAbsOrigin() - sourcePos
	dir.z = 0
	if dir:Length2D() < 1 then dir = Vector(1, 0, 0) else dir = dir:Normalized() end

	local start = unit:GetAbsOrigin()
	local endPos = start + dir * distance
	local control = start + dir * (distance / 2) + Vector(0, 0, height or 0)

	self:Bezier(unit, start, control, endPos, duration, function(u, pos)
		if u == unit then
			if stunDuration and stunDuration > 0 and ability then
				-- стан на приземлении
			end
		end
		return false
	end)

	if stunDuration and stunDuration > 0 then
		Timers:CreateTimer(duration, function()
			if IsValidEntity(unit) and unit:IsAlive() then
				require('lib/duel_bosses/boss_damage')
				DuelBossDamage:Stun(unit, unit, ability, stunDuration)
			end
			return nil
		end)
	end
end