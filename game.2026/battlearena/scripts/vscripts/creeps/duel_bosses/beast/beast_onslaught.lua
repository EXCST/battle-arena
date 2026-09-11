-- creeps/duel_bosses/beast/beast_onslaught.lua
-- «Рывок зверя» — цепочка из 2 рывков на игрока.
-- Прекаст: range-finder наводящийся на цель (follow + getDirection) + плавный доворот.
-- Во время рывка — урон %HP по пути + стан. Срыв прекаста → само-стан 4с.

require('lib/duel_bosses/boss_cast')
require('lib/duel_bosses/boss_aim')
require('lib/duel_bosses/boss_motion')
require('lib/duel_bosses/boss_warning')
require('lib/duel_bosses/boss_damage')

local CAST_POINT = 1.3
local MAX_DASH_DISTANCE = 1100
local DASH_COUNT = 2
local DASH_RADIUS = 280
local DASH_DAMAGE_PCT = 25
local STUN_DURATION = 1
local DASH_SPEED = 1300

ba_duel_beast_onslaught = ba_duel_beast_onslaught or class({})

function ba_duel_beast_onslaught:OnAbilityPhaseStart()
	print("[BEAST] onslaught phase start")
	DuelBossCast:OnPhaseStart(self, { castPoint = CAST_POINT })

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return true end

	caster:EmitSound("Hero_PrimalBeast.Onslaught.Channel")

	local target = DuelBossAim:GetSmartTarget(caster, 3500)
	if target then
		self.aim_target = target
		DuelBossAim:LockTarget(caster, target, CAST_POINT, 70)

		local start = caster:GetAbsOrigin()
		DuelBossWarning:Line(caster, self, start, start + Vector(1, 0, 0) * MAX_DASH_DISTANCE, CAST_POINT, {
			startWidth = 280,
			endWidth = 280,
			type = 1,
			follow = true,
			getDirection = function()
				local t = DuelBossAim:GetSmartTarget(caster, 3500)
				if not t then return Vector(1, 0, 0) end
				local d = t:GetAbsOrigin() - caster:GetAbsOrigin()
				d.z = 0
				return d
			end,
		})
	end

	return true
end

function ba_duel_beast_onslaught:OnAbilityPhaseInterrupted()
	DuelBossCast:OnPhaseInterrupted(self)
end

function ba_duel_beast_onslaught:OnSpellStart()
	print("[BEAST] onslaught spell start")
	DuelBossCast:OnSpellStart(self, { castDuration = 3.4 })

	self.dash_index = 0
	self.dashed = {}
	self:StartNextDash()
end

function ba_duel_beast_onslaught:StartNextDash()
	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	self.dash_index = self.dash_index + 1
	if self.dash_index > DASH_COUNT then return end

	local ok, err = pcall(function() self:StartDash(caster) end)
	if not ok then
		print("[ONSLAUGHT] StartNextDash error: " .. tostring(err))
	end

	Timers:CreateTimer(1.6, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
		local ok2, err2 = pcall(function() self:StartNextDash() end)
		if not ok2 then
			print("[ONSLAUGHT] dash timer error: " .. tostring(err2))
		end
		return nil
	end)
end

function ba_duel_beast_onslaught:StartDash(caster)
	caster:EmitSound("Hero_PrimalBeast.Onslaught.Cast")

	local target = self.aim_target
	if not target or target:IsNull() or not IsValidEntity(target) or not target:IsAlive() then
		target = DuelBossAim:GetSmartTarget(caster, 3500)
	end

	local start = caster:GetAbsOrigin()
	local dir
	local endPos

	if target then
		dir = target:GetAbsOrigin() - start
		dir.z = 0
		if dir:Length2D() < 50 then
			dir = caster:GetForwardVector()
			dir.z = 0
		end
		if dir:Length2D() < 0.1 then dir = Vector(1, 0, 0) end
		dir = dir:Normalized()

		local dist = math.min(MAX_DASH_DISTANCE, (target:GetAbsOrigin() - start):Length2D())
		endPos = start + dir * math.max(dist, 400)
	else
		dir = caster:GetForwardVector()
		dir.z = 0
		if dir:Length2D() < 0.1 then dir = Vector(1, 0, 0) end
		dir = dir:Normalized()
		endPos = start + dir * MAX_DASH_DISTANCE
	end

	local duration = math.max(0.25, (endPos - start):Length2D() / DASH_SPEED)

	DuelBossMotion:Mover(caster, endPos, duration, function(u, pos)
		if u ~= caster then return false end

		-- «наказание за стену»: врезался — рывок сломан, стан+постура (паттерн референса)
		local ahead = pos + caster:GetForwardVector() * 90
		if GridNav:IsBlocked(ahead) or not GridNav:IsTraversable(ahead) then
			DuelBossCast:CrashPunish(caster, self, 0.9)
			return true
		end

		local victims = FindUnitsInRadius(
			caster:GetTeamNumber(),
			pos,
			nil,
			DASH_RADIUS,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			0,
			FIND_CLOSEST,
			false
		)

		for _, v in ipairs(victims) do
			if IsValidEntity(v) and v:IsAlive() and not v:IsCourier() and not self.dashed[v:entindex()] then
				self.dashed[v:entindex()] = true
				caster:EmitSound("Hero_Spirit_Breaker.GreaterBash")
				DuelBossDamage:Deal(self, caster, v, DASH_DAMAGE_PCT, 0)
				DuelBossDamage:Stun(v, caster, self, STUN_DURATION)
				DuelBossMotion:KnockBack(v, pos, 150, 0.25, 0, 0, self)
			end
		end

		return false
	end)
end