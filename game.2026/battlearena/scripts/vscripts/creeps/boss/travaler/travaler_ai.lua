-- ============================================================
-- BATTLE ARENA — Travaler boss AI («Странник Разломов»)
-- Фазовый босс-перемещение:
--   фаза 1 — Врата Миров (стан), Схлопывание (вакуум+удар),
--            Прыжок Разлома (анти-кайт)
--   фаза 2 — + Разлом Измерений (трещина), Сдвиг Миров (серия
--            телепортаций игроков)
--   фаза 3 — + Хватка Пустоты (бросок героя) и ярость
-- Движок: lib/ai/ai_controller.lua (AIController)
-- ============================================================

require('lib/ai/ai_controller')
require('creeps/boss/travaler/travaler_helpers')

LinkLuaModifier("modifier_travaler_phases", "creeps/boss/travaler/modifiers/modifier_travaler_phases", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_travaler_phase_invuln", "creeps/boss/travaler/modifiers/modifier_travaler_phase_invuln", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_travaler_stun", "creeps/boss/travaler/modifiers/modifier_travaler_stun", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_travaler_leap", "creeps/boss/travaler/modifiers/modifier_travaler_leap", LUA_MODIFIER_MOTION_BOTH)
LinkLuaModifier("modifier_travaler_pull", "creeps/boss/travaler/modifiers/modifier_travaler_pull", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_travaler_knockback", "creeps/boss/travaler/modifiers/modifier_travaler_knockback", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_travaler_throw", "creeps/boss/travaler/modifiers/modifier_travaler_throw", LUA_MODIFIER_MOTION_BOTH)
LinkLuaModifier("modifier_travaler_armor_break", "creeps/boss/travaler/modifiers/modifier_travaler_armor_break", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_travaler_grabbed", "creeps/boss/travaler/modifiers/modifier_travaler_grabbed", LUA_MODIFIER_MOTION_NONE)

-- ============================================================
-- Прыжок Разлома (анти-кайт)
-- ============================================================

local HOME_RANGE = 1200

local LEAP_TRIGGER_DIST = 600
local LEAP_DURATION = 0.7
local LEAP_ARC = 300
local LEAP_AOE = 300
local LEAP_PCT = 8
local LEAP_STUN = 0.75
local LEAP_MARK_TIME = 1.0

local MARK_PARTICLE = "particles/econ/items/ogre_magi/ogre_magi_arcana/ogre_magi_arcana_stunned_orbit.vpcf"


local function GetNearestEnemy(brain)
	local best = nil
	local best_d = nil

	for _, e in ipairs(brain.enemies or {}) do
		if IsValidEntity(e) and e:IsAlive() and not e:IsCourier() then
			local d = (e:GetAbsOrigin() - brain.entity:GetAbsOrigin()):Length2D()

			if not best_d or d < best_d then
				best = e
				best_d = d
			end
		end
	end

	return best, best_d
end


local function LeapRule(self, rule)
	local unit = self.entity
	local enemy, dist = GetNearestEnemy(self)

	if not enemy or not dist or dist <= LEAP_TRIGGER_DIST then return false end

	local target_pos = enemy:GetAbsOrigin()

	-- маркер над целью (индекс держим до уничтожения — паттерн possessed_doom_leap)
	local mark = ParticleManager:CreateParticle(MARK_PARTICLE, PATTACH_OVERHEAD_FOLLOW, enemy)

	unit:EmitSound("Boss_Travaler.Leap.Cast")

	Timers:CreateTimer(LEAP_MARK_TIME, TravalerHelpers:SafeTimer(function()
		if mark then
			ParticleManager:DestroyParticle(mark, false)
			ParticleManager:ReleaseParticleIndex(mark)
			mark = nil
		end

		if not IsValidEntity(unit) or not unit:IsAlive() then return end

		unit:AddNewModifier(unit, nil, "modifier_travaler_leap", {
			duration = LEAP_DURATION,
			target_x = target_pos.x,
			target_y = target_pos.y,
			target_z = target_pos.z,
			arc = LEAP_ARC,
			aoe = LEAP_AOE,
			damage_pct = LEAP_PCT,
			stun = LEAP_STUN,
		})
	end))

	return true
end


-- ============================================================
-- Схлопывание (вакуум + удар + отброс + сломанная броня)
-- ============================================================

local COLLAPSE_RADIUS = 700
local COLLAPSE_TELEGRAPH = 1.0
local PULL_SPEED = 900
local PULL_DURATION = 0.8
local PUNCH_PCT = 6
local KNOCKBACK_DIST = 500
local KNOCKBACK_DURATION = 0.4
local ARMOR_BREAK_DURATION = 5.0


local function CollapseRule(self, rule)
	local unit = self.entity
	local center = unit:GetAbsOrigin()

	local enemies = TravalerHelpers:FindEnemies(unit:GetTeamNumber(), center, COLLAPSE_RADIUS)

	if #enemies == 0 then return false end

	-- теллур-кольцо + жест
	local telegraph = TravalerHelpers:CreateTelegraph(center, COLLAPSE_RADIUS)

	unit:StartGesture(ACT_DOTA_CAST_ABILITY_1)
	unit:EmitSound("Boss_Travaler.Collapse.Cast")

	Timers:CreateTimer(COLLAPSE_TELEGRAPH, TravalerHelpers:SafeTimer(function()
		TravalerHelpers:DestroyTelegraph(telegraph)

		if not IsValidEntity(unit) or not unit:IsAlive() then return end

		-- втягивание всех к центру
		local victims = TravalerHelpers:FindEnemies(unit:GetTeamNumber(), center, COLLAPSE_RADIUS)

		for _, victim in ipairs(victims) do
			if IsValidEntity(victim) then
				victim:AddNewModifier(unit, nil, "modifier_travaler_pull", {
					duration = PULL_DURATION,
					speed = PULL_SPEED,
					point_x = center.x,
					point_y = center.y,
					point_z = center.z,
				})
			end
		end

		-- удар после втягивания
		Timers:CreateTimer(PULL_DURATION, TravalerHelpers:SafeTimer(function()
			if not IsValidEntity(unit) or not unit:IsAlive() then return end

			local p = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_warstomp.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(p, 0, center)
			ParticleManager:SetParticleControl(p, 1, Vector(COLLAPSE_RADIUS, 0, 0))
			ParticleManager:ReleaseParticleIndex(p)

			unit:EmitSound("Boss_Travaler.Collapse.Punch")

			local hit = TravalerHelpers:FindEnemies(unit:GetTeamNumber(), center, COLLAPSE_RADIUS)

			for _, victim in ipairs(hit) do
				if IsValidEntity(victim) then
					TravalerHelpers:DealDamageCustom(nil, unit, victim, 0, PUNCH_PCT)
					victim:AddNewModifier(unit, nil, "modifier_travaler_knockback", {
						duration = KNOCKBACK_DURATION,
						radius = KNOCKBACK_DIST,
						point = tostring(center.x) .. " " .. tostring(center.y) .. " " .. tostring(center.z),
					})
					victim:AddNewModifier(unit, nil, "modifier_travaler_armor_break", { duration = ARMOR_BREAK_DURATION })
				end
			end
		end))
	end))

	return true
end


-- ============================================================
-- Хватка Пустоты (бросок героя на 2000 от босса)
-- ============================================================

local THROW_GRAB_RANGE = 600
local THROW_DIST = 2000
local GRAB_DURATION = 0.8
local THROW_DURATION = 1.2
local THROW_ARC = 400
local THROW_PCT = 10
local THROW_STUN = 1.0
local THROW_COLLISION_PCT = 6
local THROW_LAND_MARK = 250


local function ThrowRule(self, rule)
	local unit = self.entity

	local enemy = GetNearestEnemy(self)

	if not enemy then return false end

	local dist = (enemy:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D()

	if dist > THROW_GRAB_RANGE then return false end

	-- жертва «поднята»
	enemy:AddNewModifier(unit, nil, "modifier_travaler_grabbed", { duration = GRAB_DURATION })

	-- точка приземления: строго от босса по лучу
	local dir = (enemy:GetAbsOrigin() - unit:GetAbsOrigin())
	dir.z = 0

	if dir:Length2D() < 1 then return false end

	dir = dir:Normalized()

	local end_pos = GetGroundPosition(unit:GetAbsOrigin() + dir * THROW_DIST, unit)
	local telegraph = TravalerHelpers:CreateTelegraph(end_pos, THROW_LAND_MARK)

	unit:StartGesture(ACT_DOTA_CAST_ABILITY_3)
	unit:EmitSound("Boss_Travaler.Throw.Cast")

	Timers:CreateTimer(GRAB_DURATION, TravalerHelpers:SafeTimer(function()
		TravalerHelpers:DestroyTelegraph(telegraph)

		if not IsValidEntity(unit) or not unit:IsAlive() then return end
		if not IsValidEntity(enemy) or not enemy:IsAlive() then return end

		enemy:AddNewModifier(unit, nil, "modifier_travaler_throw", {
			duration = THROW_DURATION,
			end_x = end_pos.x,
			end_y = end_pos.y,
			end_z = end_pos.z,
			arc = THROW_ARC,
			damage_pct = THROW_PCT,
			stun = THROW_STUN,
			collision_pct = THROW_COLLISION_PCT,
		})

		-- КОМБО: жертва приземлилась → босс сразу прыгает ей на голову
		Timers:CreateTimer(THROW_DURATION + 0.1, TravalerHelpers:SafeTimer(function()
			if not IsValidEntity(unit) or not unit:IsAlive() then return end
			if not IsValidEntity(enemy) or not enemy:IsAlive() then return end

			local pos = enemy:GetAbsOrigin()

			unit:AddNewModifier(unit, nil, "modifier_travaler_leap", {
				duration = LEAP_DURATION,
				target_x = pos.x,
				target_y = pos.y,
				target_z = pos.z,
				arc = LEAP_ARC,
				aoe = LEAP_AOE,
				damage_pct = LEAP_PCT,
				stun = LEAP_STUN,
			})
		end))
	end))

	return true
end


-- ============================================================
-- Spawn
-- ============================================================

function Spawn()
	if not IsServer() then return end

	local unit = thisEntity

	-- фазовый контроллер
	unit.travaler_phase = 1
	unit:AddNewModifier(unit, nil, "modifier_travaler_phases", {})

	-- точка спавна (для телепортов Сдвига Миров) — на первом валидном тике
	Timers:CreateTimer(0.5, function()
		if IsValidEntity(unit) then
			local o = unit:GetAbsOrigin()

			if o:Length2D() > 1 then
				unit.travaler_spawn = o
			end
		end
	end)

	local brain = AIController(unit, {
		aggro_radius = 1200,
	})

	brain:SetRules({
		-- фаза 2+: сдвиг миров (серия телепортаций)
		{
			action = AI_ACTIONS.CAST,
			ability = "travaler_shift",
			min_enemies = 1,
			cooldown = 45,
			check = function(self, rule)
				return unit.travaler_phase >= 2
			end,
		},

		-- фаза 3: хватка пустоты (бросок героя)
		{
			action = ThrowRule,
			cooldown = 20,
			check = function(self, rule)
				return unit.travaler_phase >= 3
			end,
		},

		-- схлопывание (вакуум + удар) при толпе
		{
			action = CollapseRule,
			min_enemies = 2,
			cooldown = 15,
		},

		-- фаза 2+: разлом измерений (трещина)
		{
			action = AI_ACTIONS.CAST,
			ability = "travaler_rift_wall",
			min_enemies = 1,
			check = function(self, rule)
				return unit.travaler_phase >= 2
			end,
		},

		-- врата миров (стан)
		{ action = AI_ACTIONS.CAST, ability = "travaler_stun", min_enemies = 1 },

		-- привязка к спавну: ушёл дальше 1200 — возвращается (даже если враги рядом)
		{ action = AI_ACTIONS.RETURN, max_distance = HOME_RANGE, current_enemies = 0 },

		-- анти-кайт: прыжок к врагу, который держит дистанцию (только в зоне спавна)
		{
			action = LeapRule,
			cooldown = 12,
			check = function(self, rule)
				if not self.home then return false end

				local enemy = GetNearestEnemy(self)

				if not enemy then return false end

				return (enemy:GetAbsOrigin() - self.home):Length2D() <= HOME_RANGE
			end,
		},

		-- ближний бой
		{ action = AI_ACTIONS.ATTACK, min_enemies = 1 },

		-- возврат домой, если рядом нет врагов
		{ action = AI_ACTIONS.RETURN, max_distance = HOME_RANGE, current_enemies = 0 },
	})

	brain:Start(0.5)

	unit.brain = brain
end
