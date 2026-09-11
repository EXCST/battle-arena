-- ============================================================
-- BATTLE ARENA — Possessed Demon boss AI
-- Движок: lib/ai/ai_controller.lua (AIController)
-- Оригинальный набор: Ring of Fire, Infernal Chains,
-- Doom Leap, Mark of the Damned, Annihilation (фаза).
-- ============================================================

require('lib/ai/ai_controller')

function Spawn()
	if not IsServer() then return end

	local brain = AIController(thisEntity, {
		aggro_radius = 1200,
	})

	brain:SetRules({
		-- печать порчи: на случайного врага, взрыв через 3с
		{ action = AI_ACTIONS.CAST, ability = "possessed_mark_of_damned", min_enemies = 1 },

		-- огненное кольцо: наказать сгруппировавшихся, когда нас потрепали
		{ action = AI_ACTIONS.CAST, ability = "possessed_ring_fire", min_enemies = 1, health_pct = 75 },

		-- цепи: притянуть случайную цель
		{ action = AI_ACTIONS.CAST, ability = "possessed_infernal_chains", min_enemies = 1 },

		-- адский прыжок: разбить строй
		{ action = AI_ACTIONS.CAST, ability = "possessed_doom_leap", min_enemies = 1, health_pct = 80 },

		-- фаза истребления: один раз при HP < 30%
		{ action = AI_ACTIONS.CAST, ability = "possessed_annihilation", min_enemies = 1, health_pct = 30 },

		-- поводок: дальше 1250 от спавна босс уходит домой, игнорируя атаки
		{ action = AI_ACTIONS.RETURN, max_distance = 1250, current_enemies = 0 },

		-- в ближнем бою — обычные атаки
		{ action = AI_ACTIONS.ATTACK, min_enemies = 1 },
	})

	brain:Start(0.5)

	thisEntity.brain = brain
end
