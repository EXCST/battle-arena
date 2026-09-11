-- lib/duel_bosses/boss_phase.lua
-- Фазовый переход (адапт. BossPhaseTransitionAbility_CS):
--   возврат к точке спавна (Mover) → окно неуязвимости (NO_HEALTH_BAR) →
--   бафф второй фазы. С 2026-09-03 кастуется как ОБЫЧНЫЙ скилл из пула
--   (рандомно, КД 6) — guard «один раз за бой» (duel_phase_done) убран.

require('lib/duel_bosses/boss_motion')
require('lib/duel_bosses/modifiers/modifier_duel_boss_phase')
-- ⚠️ БЕЗ require('lib/timers') — клиентская VM падает (см. AGENTS.md); Timers — глобал

DuelBossPhase = DuelBossPhase or {}

-- opts: returnDur (сек, возврат к спавну), window (сек, неуязвимость),
--       buff (bool, давать ли бафф 2-й фазы), onWindowEnd(unit) — колбэк в конце окна.
function DuelBossPhase:Run(unit, ability, opts)
	opts = opts or {}

	local returnDur = opts.returnDur or 0.8
	local window = opts.window or 6

	local spawnPoint = unit.duel_spawn_pos or unit:GetAbsOrigin()

	DuelBossMotion:Mover(unit, spawnPoint, returnDur, function(u, pos)
		if u == unit then
			unit:AddNewModifier(unit, ability, "modifier_duel_boss_phase_window", { duration = window })
			print("[PHASE] window applied")
			return true
		end
		return false
	end)

	-- onWindowEnd вызывается ПОСЛЕ окончания окна неуязвимости (призывы и т.п.)
	Timers:CreateTimer(returnDur + window + 0.3, function()
		if not IsValidEntity(unit) or not unit:IsAlive() then return nil end

		if opts.onWindowEnd then
			local ok, err = pcall(opts.onWindowEnd, unit)
			if not ok then
				print("[DuelBossPhase] onWindowEnd error: " .. tostring(err))
			else
				print("[PHASE] onWindowEnd done")
			end
		end

		if opts.buff ~= false then
			unit:AddNewModifier(unit, ability, "modifier_duel_boss_phase_buff", { duration = -1 })
			print("[PHASE] buff applied")
		end

		return nil
	end)

	print("[DuelBossPhase] phase transition started")
end