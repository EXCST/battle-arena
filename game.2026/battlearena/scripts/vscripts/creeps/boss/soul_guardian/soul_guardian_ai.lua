-- ============================================================
-- BATTLE ARENA — Soul Guardian AI («Страж Душ»)
-- Легаси-порядок приоритетов (Ring → Heal → Steal → Rage → Attack):
--   HeroesRing   — поле героев, если враг в 800 (анти-стак AOE)
--   PureHeal     — хил при HP <= 40%
--   DamageSteal  — стакающийся дебафф на урон атаки, враг в 450
--   HolyRage     — энрейдж при HP <= 40% (сброс КД, пул урона)
-- Движок: lib/ai/ai_controller.lua (AIController)
-- ============================================================

require('lib/ai/ai_controller')

local RING_RADIUS = 800
local STEAL_RADIUS = 450
local HOME_RANGE = 900

local RING_MODIFIER = "modifier_soul_guardian_heroes_ring_in_caster"
local STEAL_MODIFIER = "modifier_soul_guardian_damage_in_caster"


--- Есть ли живой враг в радиусе от босса.
local function HasEnemyWithin(brain, radius)
	local unit = brain.entity

	for _, e in ipairs(brain.enemies or {}) do
		if IsValidEntity(e) and e:IsAlive() and not e:IsCourier() then
			if (e:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D() <= radius then
				return true
			end
		end
	end

	return false
end


--- Босс занят «каналом» кольца/стила — другие касты не выполняем.
local function IsBusy(unit)
	return unit:HasModifier(RING_MODIFIER) or unit:HasModifier(STEAL_MODIFIER)
end


function Spawn()
	if not IsServer() then return end

	local unit = thisEntity

	local brain = AIController(unit, {
		aggro_radius = 1200,
	})

	brain:SetRules({
		-- 1. Поле героев (главный урон): враг в радиусе кольца
		{
			action = AI_ACTIONS.CAST,
			ability = "soul_guardian_heroes_ring",
			min_enemies = 1,
			check = function(self, rule)
				if IsBusy(unit) then return false end
				return HasEnemyWithin(self, RING_RADIUS)
			end,
		},

		-- 2. Самохил при низком HP (диспелл негатива)
		{
			action = AI_ACTIONS.CAST,
			ability = "soul_guardian_pure_heal",
			check = function(self, rule)
				if IsBusy(unit) then return false end
				return unit:GetHealthPercent() <= 40
			end,
		},

		-- 3. Стил урона атаки: враг в радиусе канала
		{
			action = AI_ACTIONS.CAST,
			ability = "soul_guardian_damage_steal",
			min_enemies = 1,
			check = function(self, rule)
				if IsBusy(unit) then return false end
				return HasEnemyWithin(self, STEAL_RADIUS)
			end,
		},

		-- 4. Ярость при низком HP (пул урона + сброс КД)
		{
			action = AI_ACTIONS.CAST,
			ability = "soul_guardian_holy_rage",
			check = function(self, rule)
				return unit:GetHealthPercent() <= 40
			end,
		},

		-- 5. Ближний бой
		{ action = AI_ACTIONS.ATTACK, min_enemies = 1 },

		-- 6. Поводок: ушёл дальше 900 от спавна — возврат
		{ action = AI_ACTIONS.RETURN, max_distance = HOME_RANGE, current_enemies = 0 },
	})

	brain:Start(0.5)

	unit.brain = brain
end
