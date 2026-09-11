-- creeps/duel_bosses/beast/beast_rocks.lua
-- «Камни» — вольвовая система как у китайцев (boss_beast_2):
--   4 залпа (интервал 1.5с) по 5..7 камней; каждый залп РЕ-АИМ на цель,
--   база = предиктивная точка игрока, камни кластером вокруг неё
--   (радиус ≤ CLUSTER_RADIUS, мин. разнос MIN_SPACING).
-- Кольцо-теллур на каждую точку → tracking-снаряд на думающего → 12% HP + стан 1с.
-- Guard НЕТ (по решению): если в игрока попало несколько камней — всё бьёт.
-- Токен-гард: прерывание/смерть/стан босса отменяет оставшиеся залпы.

require('lib/duel_bosses/boss_cast')
require('lib/duel_bosses/boss_aim')
require('lib/duel_bosses/boss_predict')
require('lib/duel_bosses/boss_warning')
require('lib/duel_bosses/boss_damage')

local CAST_POINT = 0.7
local VOLLEY_COUNT = 4
local VOLLEY_INTERVAL = 1.5
local ROCKS_MIN = 5
local ROCKS_MAX = 7
local ROCK_STAGGER = 0.06
local CLUSTER_RADIUS = 160
local MIN_SPACING = 70
local RING_RADIUS = 220
local RING_DURATION = 0.9
local IMPACT_RADIUS = 180
local DAMAGE_PCT = 12
local STUN_DURATION = 1
local TRAVEL_TIME = 1.0
local PROJECTILE_SPEED = 1000

ba_duel_beast_rocks = ba_duel_beast_rocks or class({})

function ba_duel_beast_rocks:OnAbilityPhaseStart()
	DuelBossCast:OnPhaseStart(self, { castPoint = CAST_POINT })

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return true end

	local target = DuelBossAim:GetSmartTarget(caster, 3500)
	if target then
		DuelBossAim:LockTarget(caster, target, CAST_POINT, 60)
	end

	return true
end

function ba_duel_beast_rocks:OnAbilityPhaseInterrupted()
	DuelBossCast:OnPhaseInterrupted(self)
end

function ba_duel_beast_rocks:OnSpellStart()
	-- канал = 4 залпа × 1.5с + запас на полёт
	DuelBossCast:OnSpellStart(self, { castDuration = VOLLEY_COUNT * VOLLEY_INTERVAL + 1.2 })

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	-- токен залпов: новый каст/смерть/стан отменяет незавершённые
	caster.rocks_token = DoUniqueString("ba_duel_beast_rocks")

	local ok, err = pcall(function() self:FireVolley(caster, 1, caster.rocks_token) end)
	if not ok then
		print("[ROCKS] OnSpellStart error: " .. tostring(err))
	end
end

function ba_duel_beast_rocks:FireVolley(caster, volley_index, token)
	if not IsValidEntity(caster) or not caster:IsAlive() then return end
	if token ~= caster.rocks_token then return end

	-- стан босса = прерывание залпов (токен остаётся, канал завершается «молча»)
	if caster:IsStunned() or caster:IsHexed() then return end

	if volley_index > VOLLEY_COUNT then return end

	local ok, err = pcall(function() self:ThrowVolley(caster, volley_index, token) end)
	if not ok then
		print("[ROCKS] FireVolley error: " .. tostring(err))
	end

	if volley_index < VOLLEY_COUNT then
		Timers:CreateTimer(VOLLEY_INTERVAL, function()
			if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
			if token ~= caster.rocks_token then return nil end

			local ok2, err2 = pcall(function() self:FireVolley(caster, volley_index + 1, token) end)
			if not ok2 then
				print("[ROCKS] FireVolley timer error: " .. tostring(err2))
			end
			return nil
		end)
	end
end

function ba_duel_beast_rocks:ThrowVolley(caster, volley_index, token)
	-- ре-аим на каждый залп: цель и её предиктивная точка свежие
	local target = DuelBossAim:GetSmartTarget(caster, 3500)
	if not target then return end

	local base = DuelBossPredict:LeadPosition(target, TRAVEL_TIME)
	base.z = target:GetAbsOrigin().z

	local count = RandomInt(ROCKS_MIN, ROCKS_MAX)
	local points = self:BuildCluster(base, count)

	for i, point in ipairs(points) do
		Timers:CreateTimer((i - 1) * ROCK_STAGGER, function()
			if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
			if token ~= caster.rocks_token then return nil end

			local ok, err = pcall(function() self:ThrowSingle(caster, point) end)
			if not ok then
				print("[ROCKS] ThrowSingle error: " .. tostring(err))
			end
			return nil
		end)
	end
end

-- Кластер из `count` точек вокруг центра: радиус ≤ CLUSTER_RADIUS,
-- мин. разнос MIN_SPACING (ретраи), фолбэк — случайная точка без проверки.
function ba_duel_beast_rocks:BuildCluster(center, count)
	local pts = {}
	local attempts = count * 12

	for i = 1, count do
		local p = nil

		for _ = 1, attempts do
			local angle = RandomFloat(0, 360)
			local r = RandomFloat(0, CLUSTER_RADIUS)
			local candidate = center + Vector(
				math.cos(angle * math.pi / 180) * r,
				math.sin(angle * math.pi / 180) * r,
				0
			)

			local spaced = true
			for _, existing in ipairs(pts) do
				if (existing - candidate):Length2D() < MIN_SPACING then
					spaced = false
					break
				end
			end

			if spaced then
				p = candidate
				break
			end
		end

		if not p then
			local angle = RandomFloat(0, 360)
			local r = RandomFloat(0, CLUSTER_RADIUS)
			p = center + Vector(
				math.cos(angle * math.pi / 180) * r,
				math.sin(angle * math.pi / 180) * r,
				0
			)
		end

		p.z = center.z
		pts[#pts + 1] = p
	end

	return pts
end

function ba_duel_beast_rocks:ThrowSingle(caster, point)
	caster:EmitSound("Hero_PrimalBeast.RockThrow.Throw")

	-- кольцо-теллур в точке приземления
	DuelBossWarning:Ring(caster, self, point, RING_RADIUS, RING_DURATION)

	-- думающий-«мишень» для tracking-снаряда
	local dummy = CreateModifierThinker(nil, self, "modifier_duel_boss_dummy", { duration = 3 }, point, DOTA_TEAM_GOODGUYS, false)

	if not dummy or dummy:IsNull() then
		return
	end

	ProjectileManager:CreateTrackingProjectile({
		Target = dummy,
		Source = caster,
		Ability = self,
		EffectName = "particles/primal_beast_rock_throw_arc.vpcf",
		iMoveSpeed = PROJECTILE_SPEED,
		bDodgeable = false,
		bVisibleToEnemies = true,
		ExtraData = {
			dummy = dummy:entindex(),
			point_x = point.x,
			point_y = point.y,
			point_z = point.z,
		},
	})
end

function ba_duel_beast_rocks:OnProjectileHit_ExtraData(target, location, extraData)
	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end
	if not extraData then return end

	local point = Vector(extraData.point_x, extraData.point_y, extraData.point_z)

	caster:EmitSound("Hero_PrimalBeast.RockThrow.Impact")
	DuelBossDamage:DealToArea(self, caster, point, IMPACT_RADIUS, DAMAGE_PCT, 0)

	local victims = FindUnitsInRadius(
		caster:GetTeamNumber(),
		point,
		nil,
		IMPACT_RADIUS,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		FIND_CLOSEST,
		false
	)

	for _, v in ipairs(victims) do
		if IsValidEntity(v) and v:IsAlive() and not v:IsCourier() then
			caster:EmitSound("Hero_PrimalBeast.RockThrow.Stun")
			DuelBossDamage:Stun(v, caster, self, STUN_DURATION)
		end
	end

	if extraData.dummy then
		local d = EntIndexToHScript(extraData.dummy)
		if d and not d:IsNull() and IsValidEntity(d) then
			d:RemoveSelf()
		end
	end
end