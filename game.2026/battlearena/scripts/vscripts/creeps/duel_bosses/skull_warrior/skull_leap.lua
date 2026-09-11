-- creeps/duel_bosses/skull_warrior/skull_leap.lua
-- «Прыжок Пустоши» (порт elite_041): зарядка → прыжок-дуга к цели−300,
-- приземление: 25%→10% макс.HP по дистанции + стан 2с в 500.
-- Прыжок — Bezier-дуга (высота 400, полёт 1.03с), warning-кольцо перед посадкой.

require('lib/duel_bosses/boss_cast')
require('lib/duel_bosses/boss_aim')
require('lib/duel_bosses/boss_motion')
require('lib/duel_bosses/boss_warning')
require('lib/duel_bosses/boss_damage')

local CAST_POINT = 0.6
local CAST_DURATION = 2.33
local SEARCH_RANGE = 1500

local AIR_TIME = 1.03
local JUMP_HEIGHT = 400
local LAND_OFFSET = 300

local LAND_RADIUS = 500
local LAND_DAMAGE_PCT = 25
local LAND_MIN_DAMAGE_PCT = 10
local LAND_STUN = 2.0

local DUST_PARTICLE = "particles/units/heroes/hero_dawnbreaker/dawnbreaker_elated_fury_landing_dust.vpcf"
local CORE_PARTICLE = "particles/units/heroes/hero_primal_beast/primal_beast_pulverize_hit.vpcf"
local WAVE_PARTICLE = "particles/units/heroes/hero_primal_beast/primal_beast_rock_throw_impact.vpcf"

ba_duel_skull_leap = ba_duel_skull_leap or class({})

function ba_duel_skull_leap:OnAbilityPhaseStart()
	DuelBossCast:OnPhaseStart(self, { castPoint = CAST_POINT })

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return true end

	-- пыль на разгон (за 0.2с до прыжка)
	Timers:CreateTimer(CAST_POINT - 0.2, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
		local origin = caster:GetAbsOrigin()
		local p = ParticleManager:CreateParticle(DUST_PARTICLE, PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(p, 0, origin)
		ParticleManager:SetParticleControl(p, 1, origin)
		ParticleManager:SetParticleControl(p, 2, Vector(550, 550, 550))
		ParticleManager:ReleaseParticleIndex(p)
		return nil
	end)

	return true
end

function ba_duel_skull_leap:OnAbilityPhaseInterrupted()
	DuelBossCast:OnPhaseInterrupted(self)
end

function ba_duel_skull_leap:OnSpellStart()
	DuelBossCast:OnSpellStart(self, { castDuration = CAST_DURATION })

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	caster:EmitSound("Hero_Spirit_Breaker.ChargeOfDarkness")

	local origin = caster:GetAbsOrigin()
	local target = DuelBossAim:GetNearestEnemy(caster, SEARCH_RANGE)
	local landPos = origin

	if target then
		local dir = target:GetAbsOrigin() - origin
		dir.z = 0
		local dist = dir:Length2D()
		if dist > 0.01 then
			dir = dir / dist
			local landDist = math.max(dist - LAND_OFFSET, 0)
			landPos = origin + dir * landDist
			DuelBossAim:LockTarget(caster, target, 0.8)
		end
	end

	landPos.z = GetGroundPosition(landPos, caster).z
	self.land_pos = landPos

	local forward = landPos - origin
	forward.z = 0
	if forward:Length2D() > 0.01 then
		caster:SetForwardVector(forward:Normalized())
	end

	local control = origin + (landPos - origin) * 0.5 + Vector(0, 0, JUMP_HEIGHT)

	-- warning-кольцо за 0.2с до посадки
	Timers:CreateTimer(AIR_TIME - 0.2, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
		DuelBossWarning:Ring(caster, self, landPos + caster:GetForwardVector() * 300, 450, 0.3, { speed = 0 })
		return nil
	end)

	DuelBossMotion:Bezier(caster, origin, control, landPos, AIR_TIME, function(u, pos)
		return false
	end)

	-- приземление
	Timers:CreateTimer(AIR_TIME, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
		self:PlayLandingImpact(caster)
		return nil
	end)
end

function ba_duel_skull_leap:PlayLandingImpact(caster)
	caster:EmitSound("Hero_Mars.Spear.Root")

	local forward = caster:GetForwardVector()
	forward.z = 0
	local center = caster:GetAbsOrigin() + forward * 300
	center.z = GetGroundPosition(center, caster).z

	local core = ParticleManager:CreateParticle(CORE_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(core, 0, center)
	ParticleManager:SetParticleControl(core, 1, Vector(400, 0, 0))
	ParticleManager:SetParticleControl(core, 3, center)
	ParticleManager:ReleaseParticleIndex(core)

	EmitSoundOnLocationWithCaster(center, "Hero_Mars.Spear.Target", caster)
	Timers:CreateTimer(0.03, function()
		local p = ParticleManager:CreateParticle(WAVE_PARTICLE, PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(p, 3, center)
		ParticleManager:ReleaseParticleIndex(p)
		return nil
	end)

	ScreenShake(center, 25, 25, 1, 2500, 0, true)

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(), center, nil, LAND_RADIUS,
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0, FIND_ANY_ORDER, false
	)
	for _, enemy in ipairs(enemies) do
		if IsValidEntity(enemy) and enemy:IsAlive() and not enemy:IsCourier() then
			local dist = math.min((enemy:GetAbsOrigin() - center):Length2D(), LAND_RADIUS)
			local t = dist / LAND_RADIUS
			local pct = LAND_DAMAGE_PCT - (LAND_DAMAGE_PCT - LAND_MIN_DAMAGE_PCT) * t
			DuelBossDamage:Deal(self, caster, enemy, pct, 0)
			DuelBossDamage:Stun(enemy, caster, self, LAND_STUN)
		end
	end
end