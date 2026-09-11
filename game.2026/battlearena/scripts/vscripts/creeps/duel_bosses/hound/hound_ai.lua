-- creeps/duel_bosses/hound/hound_ai.lua
-- Гончая дуэльного босса: при рождении делает рывок на ближайшего игрока
-- (урон %HP по пути + мини-стан), затем атакует в рукопашную.

require('lib/duel_bosses/boss_aim')
require('lib/duel_bosses/boss_motion')
require('lib/duel_bosses/boss_damage')
require('lib/ai/ai_controller')
require('lib/timers')

local CHARGE_DISTANCE = 650
local CHARGE_DURATION = 0.5
local CHARGE_RADIUS = 160
local CHARGE_DAMAGE_PCT = 10
local CHARGE_STUN = 0.35

function Spawn()
	if not IsServer() then return end

	local unit = thisEntity

	Timers:CreateTimer(0.1, function()
		if not IsValidEntity(unit) or not unit:IsAlive() then return nil end

		local target = DuelBossAim:GetNearestEnemy(unit, 3000, unit:GetAbsOrigin())
		if not target then return nil end

		local start = unit:GetAbsOrigin()
		local dir = target:GetAbsOrigin() - start
		dir.z = 0
		if dir:Length2D() < 50 then return nil end
		dir = dir:Normalized()

		local endPos = start + dir * CHARGE_DISTANCE
		unit.charged = {}

		DuelBossMotion:Mover(unit, endPos, CHARGE_DURATION, function(u, pos)
			if u ~= unit then return false end

			local victims = FindUnitsInRadius(
				unit:GetTeamNumber(),
				pos,
				nil,
				CHARGE_RADIUS,
				DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
				0,
				FIND_CLOSEST,
				false
			)

			for _, v in ipairs(victims) do
				if IsValidEntity(v) and v:IsAlive() and not v:IsCourier() and not unit.charged[v:entindex()] then
					unit.charged[v:entindex()] = true
					unit:EmitSound("Hero_Spirit_Breaker.GreaterBash")
					DuelBossDamage:Deal(nil, unit, v, CHARGE_DAMAGE_PCT, 0)
					DuelBossDamage:Stun(v, unit, nil, CHARGE_STUN)
				end
			end

			return false
		end)

		Timers:CreateTimer(CHARGE_DURATION + 0.1, function()
			if IsValidEntity(unit) and unit:IsAlive() then
				-- после рывка — обычный бой через AIController
				local brain = AIController(unit, {
					aggro_radius = 1200,
				})
				brain:SetRules({
					{ action = AI_ACTIONS.ATTACK, min_enemies = 1 },
					{ action = AI_ACTIONS.RETURN, max_distance = 2000 },
				})
				brain:Start(0.5)
				unit.brain = brain
			end
			return nil
		end)

		return nil
	end)
end