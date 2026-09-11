-- creeps/duel_bosses/skull_warrior/skull_miner_ai.lua
-- AI кентавра-шахтёра (саммон Воина Пустоши): ближний бой + возврат на поводок.

require('lib/ai/ai_controller')

function Spawn()
	if not IsServer() then return end

	local brain = AIController(thisEntity, { aggro_radius = 1200 })
	brain:SetRules({
		{ action = AI_ACTIONS.ATTACK, min_enemies = 1 },
		{ action = AI_ACTIONS.RETURN, max_distance = 2000 },
	})
	brain:Start(0.5)

	thisEntity.brain = brain
end