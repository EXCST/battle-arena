-- creeps/duel_bosses/skull_warrior/skull_smash.lua
-- «Сокрушение Пустоши» (порт elite_120): 3 залпа по 5-9 кругов r280,
-- 75% точек у случайных врагов (±420), warn-кольцо 0.8с, удар:
-- 15% макс.HP + подброс (высота 260) + стан 1с; hit-once на залп.

require('lib/duel_bosses/boss_cast')
require('lib/duel_bosses/boss_aim')
require('lib/duel_bosses/boss_warning')
require('lib/duel_bosses/boss_damage')
require('lib/duel_bosses/boss_motion')

local CAST_POINT = 0.6
local CAST_DURATION = 6
local CAST_RANGE = 1000

local SMASH_COUNT = 3
local WARNING_HIT_DELAY = 0.8
local SMASH_RADIUS = 280
local DAMAGE_PCT = 15
local POINT_MIN_COUNT = 5
local POINT_MAX_COUNT = 9
local POINT_MIN_SEPARATION = 364
local POINT_ATTEMPTS = 20
local RANDOM_MIN_DISTANCE = 180
local KNOCKUP_DURATION = 0.35
local KNOCKUP_HEIGHT = 260
local KNOCKUP_STUN = 1

local PARTICLE = "particles/units/heroes/hero_primal_beast/primal_beast_pulverize_hit.vpcf"

ba_duel_skull_smash = ba_duel_skull_smash or class({})

function ba_duel_skull_smash:OnAbilityPhaseStart()
	DuelBossCast:OnPhaseStart(self, { castPoint = CAST_POINT })

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return true end

	self.cast_sequence = 1
	caster:EmitSound("Hero_Spirit_Breaker.ChargeOfDarkness")
	return true
end

function ba_duel_skull_smash:OnAbilityPhaseInterrupted()
	DuelBossCast:OnPhaseInterrupted(self)
	self.cast_sequence = (self.cast_sequence or 0) + 1
end

function ba_duel_skull_smash:OnSpellStart()
	DuelBossCast:OnSpellStart(self, { castDuration = CAST_DURATION })

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	local seq = self.cast_sequence or 1
	self:WarningAndDamage(caster, seq)

	Timers:CreateTimer(1.5, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
		self.cast_sequence = seq + 1
		self:StartSmashRound(caster, seq + 1)
		return nil
	end)
end

function ba_duel_skull_smash:StartSmashRound(caster, sequence)
	if sequence > SMASH_COUNT then return end

	caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_1, 1)
	Timers:CreateTimer(WARNING_HIT_DELAY, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
		self:WarningAndDamage(caster, sequence)
		return nil
	end)

	if sequence < SMASH_COUNT then
		Timers:CreateTimer(WARNING_HIT_DELAY + 1.2, function()
			if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
			self:StartSmashRound(caster, sequence + 1)
			return nil
		end)
	end
end

function ba_duel_skull_smash:WarningAndDamage(caster, sequence)
	local points = self:CreateSmashPoints(caster, RandomInt(POINT_MIN_COUNT, POINT_MAX_COUNT))

	for _, point in ipairs(points) do
		DuelBossWarning:Ring(caster, self, point, SMASH_RADIUS, WARNING_HIT_DELAY, { speed = 0 })
	end

	Timers:CreateTimer(WARNING_HIT_DELAY, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
		self:ExecuteSmashRound(caster, points)
		return nil
	end)
end

function ba_duel_skull_smash:CreateSmashPoints(caster, count)
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, CAST_RANGE,
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0, FIND_ANY_ORDER, false
	)
	local alive = {}
	for _, e in ipairs(enemies) do
		if IsValidEntity(e) and e:IsAlive() then alive[#alive + 1] = e end
	end

	local points = {}
	for i = 1, count do
		local fallback, fallbackDist = nil, -1
		for attempt = 1, POINT_ATTEMPTS do
			local candidate = self:CreatePointCandidate(caster, alive)
			if GridNav:IsTraversable(candidate) and not GridNav:IsBlocked(candidate) then
				local nearest = self:GetNearestPointDistance(candidate, points)
				if nearest >= POINT_MIN_SEPARATION then
					points[#points + 1] = candidate
					fallback = nil
					break
				end
				if not fallback or nearest > fallbackDist then
					fallback, fallbackDist = candidate, nearest
				end
			end
		end
		if fallback then
			points[#points + 1] = fallback
		elseif #points < i then
			points[#points + 1] = caster:GetAbsOrigin()
		end
	end
	return points
end

function ba_duel_skull_smash:CreatePointCandidate(caster, alive)
	if #alive > 0 and RandomInt(1, 100) <= 75 then
		local enemy = alive[RandomInt(1, #alive)]
		if IsValidEntity(enemy) and enemy:IsAlive() then
			return GetGroundPosition(enemy:GetAbsOrigin() + RandomVector(RandomFloat(0, SMASH_RADIUS * 1.5)), enemy)
		end
	end
	return GetGroundPosition(caster:GetAbsOrigin() + RandomVector(RandomFloat(RANDOM_MIN_DISTANCE, CAST_RANGE)), caster)
end

function ba_duel_skull_smash:GetNearestPointDistance(point, selected)
	if #selected == 0 then return POINT_MIN_SEPARATION end
	local nearest = 99999
	for _, p in ipairs(selected) do
		local d = (point - p):Length2D()
		if d < nearest then nearest = d end
	end
	return nearest
end

function ba_duel_skull_smash:ExecuteSmashRound(caster, points)
	local hitRecord = {}

	for _, point in ipairs(points) do
		local smashPoint = GetGroundPosition(point, caster)
		local pfx = ParticleManager:CreateParticle(PARTICLE, PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(pfx, 0, smashPoint)
		ParticleManager:SetParticleControl(pfx, 1, Vector(SMASH_RADIUS, 0, 0))
		ParticleManager:ReleaseParticleIndex(pfx)
		ScreenShake(smashPoint, 10, 80, 0.25, 900, 0, true)

		local victims = FindUnitsInRadius(
			caster:GetTeamNumber(), smashPoint, nil, SMASH_RADIUS,
			DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			0, FIND_ANY_ORDER, false
		)
		for _, v in ipairs(victims) do
			if IsValidEntity(v) and v:IsAlive() and not v:IsCourier() and not hitRecord[v:entindex()] then
				hitRecord[v:entindex()] = true
				DuelBossDamage:Deal(self, caster, v, DAMAGE_PCT, 0)
				DuelBossMotion:KnockBack(v, smashPoint, 0, KNOCKUP_DURATION, KNOCKUP_HEIGHT, KNOCKUP_STUN, self)
			end
		end
	end

	caster:EmitSound("Hero_Mars.Spear.Root")
	ScreenShake(caster:GetAbsOrigin(), 20, 20, 0.6, 2900, 0, true)
end