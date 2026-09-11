-- creeps/duel_bosses/skull_warrior/skull_warrior_ai.lua
-- AI дуэльного босса «Воин Пустоши» (порт bone_warrior, monster_11052):
--   DuelBossAI (пул ×0.618, анти-повтор, пере-роллы) + фазовый переход
--   на HP ≤ 60% (один раз) через phase_ability.
-- Коридоры: wave 300-1400, leap 0-1500, arena 0-900 (мили), smash 0-1100.

require('lib/duel_bosses/boss_ai')
require('lib/timers')

function Spawn()
	if not IsServer() then return end

	local unit = thisEntity

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
		phase_ability = "ba_duel_skull_phase",
		phase_pct = 60,
		abilities = {
			ba_duel_skull_wave   = { w = 1000, min = 300, max = 1400 },
			ba_duel_skull_leap   = { w = 1000, min = 0,   max = 1500 },
			ba_duel_skull_arena  = { w = 800,  min = 0,   max = 900 },
			ba_duel_skull_smash  = { w = 1000, min = 0,   max = 1100 },
		},
	})
end