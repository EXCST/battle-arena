-- creeps/duel_bosses/deadeye/deadeye_cog_ai.lua
-- ИИ когса «Гранёного крюка»: неподвижная турель. UseNeutralCreepBehavior 1 не
-- инициирует атаку (нейтралы отвечают только на агрессию), поэтому свой
-- AIController с единственным правилом ATTACK (агро-радиус = дальность).

require('lib/ai/ai_controller')

function Spawn()
	if not IsServer() then return end

	local unit = thisEntity

	local brain = AIController(unit, { aggro_radius = 550 })
	brain:SetRules({
		{ action = AI_ACTIONS.ATTACK, min_enemies = 1 },
	})
	brain:Start(0.5)
	unit.brain = brain
end
