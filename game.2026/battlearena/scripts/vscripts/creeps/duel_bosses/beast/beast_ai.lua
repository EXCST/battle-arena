-- creeps/duel_bosses/beast/beast_ai.lua
-- AI дуэльного босса «Зверь»: DuelBossAI (AIController + взвешенный пул).
-- Приоритет: фаза (HP≤60%, один раз) → случайный скилл из пула (×0.618)
-- → ATTACK → RETURN (поводок 1200).

require('lib/duel_bosses/boss_ai')
require('lib/timers')

function Spawn()
	if not IsServer() then return end

	local unit = thisEntity

	-- отладка: какие способности реально созданы на юните
	local slots = {}
	for i = 0, 15 do
		local ab = unit:GetAbilityByIndex(i)
		if ab then
			slots[#slots + 1] = ab:GetAbilityName() .. "@" .. ab:GetLevel()
		end
	end
	print("[BEAST] abilities:", table.concat(slots, ", "))

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
		-- фаза ЧЕРЕЗ GATE (HP≤60, один раз), а не пулом: каст фазы из пула при
		-- полном HP вешает «дыхание» ~КД(30)+канал(3.4)+джиттер ≈ 35с тишины
		phase_ability = "ba_duel_beast_phase",
		phase_pct = 60,
		abilities = {
			-- {w=вес, min/max=дистанционный коридор до цели (паттерн референса)}
			ba_duel_beast_onslaught = { w = 1000, min = 600, max = 3000 },
			ba_duel_beast_rocks     = { w = 1000, min = 600, max = 3000 },
			ba_duel_beast_roar      = { w = 1000, min = 350, max = 2800 },
			ba_duel_beast_stomp     = { w = 1000, min = 0,   max = 620 },
		},
		pre_rules = {
			{
				action = AI_ACTIONS.CAST,
				ability = "ba_duel_beast_stomp",
				check = function(self, rule)
					-- приоритетный мили-ответ, когда кто-то уткнулся в босса
					if self.entity:HasModifier("modifier_duel_boss_stagger") then return false end
					local dist = 99999
					for _, e in ipairs(self.enemies or {}) do
						local d = (e:GetOrigin() - self.entity:GetOrigin()):Length2D()
						if d < dist then dist = d end
					end
					return dist <= 550
				end,
			},
		},
	})
end