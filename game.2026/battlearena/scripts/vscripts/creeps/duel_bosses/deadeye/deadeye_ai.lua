-- creeps/duel_bosses/deadeye/deadeye_ai.lua
-- AI дуэльного босса «Deadeye» kit v3 (снайпер-ганслингер).
-- Фаза — gate (HP≤60, один раз). Пул: шрапнель / граната / крюк (в упор —
-- приоритет, вес 1800). «Дыхание» и анти-повтор — штатные от DuelBossCast/BossPool.

require('lib/duel_bosses/boss_ai')
require('lib/timers')

function Spawn()
	if not IsServer() then return end

	local unit = thisEntity

	unit.duel_debug = true -- [TEMP-DEBUG] убрать после отладки пула

	-- точка спавна для фазового возврата (в первые тики позиция может быть (0,0,0))
	Timers:CreateTimer(0.1, function()
		if not IsValidEntity(unit) or not unit:IsAlive() then return nil end
		local o = unit:GetAbsOrigin()
		if o:Length2D() > 1 then
			unit.duel_spawn_pos = o
			return nil
		end
		return 0.1
	end)

	DuelBossAI:Create(unit, {
		aggro_radius = 3000,
		leash = 1200,
		interval = 0.4,
		cast_range = 3500,
		phase_ability = "ba_duel_deadeye_phase",
		phase_pct = 60,
		abilities = {
			ba_duel_deadeye_shrapnel = { w = 1000, min = 450, max = 3000 },
			ba_duel_deadeye_grenade  = { w = 1000, min = 400, max = 3000 },
			ba_duel_deadeye_hookshot = { w = 1800, min = 0,   max = 450 },
		},
	})
end
