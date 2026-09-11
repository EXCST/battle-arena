-- creeps/duel_bosses/beast/beast_roar.lua
-- «Рёв» — 3 волны шоквейва веером в направлении игрока.
-- Между волнами — ре-aim (плавный доворот на актуальную позицию цели).
-- Каждая волна: линейный теллур + линейный снаряд → 20% HP.

require('lib/duel_bosses/boss_cast')
require('lib/duel_bosses/boss_aim')
require('lib/duel_bosses/boss_warning')
require('lib/duel_bosses/boss_damage')

local CAST_POINT = 0.7
local WAVES = 3
local WAVE_INTERVAL = 1.1
local FAN_ANGLES = { -30, 0, 30 }
local WAVE_SPEED = 1200
local WAVE_DISTANCE = 3200
local WAVE_RADIUS = 100
local WARNING_DURATION = 0.6
local DAMAGE_PCT = 8

ba_duel_beast_roar = ba_duel_beast_roar or class({})

function ba_duel_beast_roar:OnAbilityPhaseStart()
	DuelBossCast:OnPhaseStart(self, { castPoint = CAST_POINT })

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return true end

	local target = DuelBossAim:GetSmartTarget(caster, 3500)
	if target then
		DuelBossAim:LockTarget(caster, target, CAST_POINT, 60)
	end

	return true
end

function ba_duel_beast_roar:OnAbilityPhaseInterrupted()
	DuelBossCast:OnPhaseInterrupted(self)
end

function ba_duel_beast_roar:OnSpellStart()
	DuelBossCast:OnSpellStart(self, { castDuration = WAVES * WAVE_INTERVAL + 0.5 })

	self.wave_index = 0
	self:WaveNext()
end

function ba_duel_beast_roar:WaveNext()
	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	self.wave_index = self.wave_index + 1
	if self.wave_index > WAVES then return end

	caster:EmitSound("Hero_PrimalBeast.Uproar.Cast")

	local target = DuelBossAim:GetSmartTarget(caster, 3500)
	local baseDir

	if target then
		-- ре-aim перед волной: босс доворачивается на актуальную позицию цели
		DuelBossAim:LockTarget(caster, target, 0.5, 40)
		baseDir = target:GetAbsOrigin() - caster:GetAbsOrigin()
		baseDir.z = 0
	else
		baseDir = caster:GetForwardVector()
		baseDir.z = 0
	end

	if baseDir:Length2D() < 0.1 then baseDir = Vector(1, 0, 0) end
	baseDir = baseDir:Normalized()

	local start = caster:GetAbsOrigin() + baseDir * 100

	for _, angle in ipairs(FAN_ANGLES) do
		local dir = DuelBossAim:RotateVector2D(baseDir, angle)

		DuelBossWarning:Line(caster, self, start, start + dir * WAVE_DISTANCE, WARNING_DURATION, {
			startWidth = WAVE_RADIUS * 2,
			endWidth = WAVE_RADIUS * 2,
			type = 1,
		})

		ProjectileManager:CreateLinearProjectile({
			vSpawnOrigin = start,
			vVelocity = dir * WAVE_SPEED,
			fDistance = WAVE_DISTANCE,
			fStartRadius = WAVE_RADIUS,
			fEndRadius = WAVE_RADIUS,
			fExpireTime = GameRules:GetGameTime() + 5,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
			bIgnoreSource = true,
			bHasFrontalCone = true,
			EffectName = "particles/magnataur_shockwave_red.vpcf",
			Ability = self,
			Source = caster,
		})
	end

	Timers:CreateTimer(WAVE_INTERVAL, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
		self:WaveNext()
		return nil
	end)
end

function ba_duel_beast_roar:OnProjectileHit(hTarget, vLocation)
	if not hTarget or hTarget:IsNull() or not IsValidEntity(hTarget) then return true end
	if not hTarget:IsAlive() or hTarget:IsCourier() then return true end

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return true end

	DuelBossDamage:Deal(self, caster, hTarget, DAMAGE_PCT, 0)

	return true
end