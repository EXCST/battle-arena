-- creeps/duel_bosses/skull_warrior/skull_phase.lua
-- Фаза «Воина Пустоши» (порт boss_bone_warrior_phase_summon): HP ≤ 60% один раз.
-- Окно 6.2с (инвулн+NO_HEALTH_BAR, DuelBossPhase): 2 прыжка-смэша (t=0/3.6,
-- импакт 1.33с, r500: 20% макс.HP + стан 2с), каждый призыв 3 минеров,
-- само-хил 5%×2; после окна — штатный бафф фазы 2 (+10%/-10%/+20% MS/AS).

require('lib/duel_bosses/boss_cast')
require('lib/duel_bosses/boss_aim')
require('lib/duel_bosses/boss_motion')
require('lib/duel_bosses/boss_warning')
require('lib/duel_bosses/boss_damage')
require('lib/duel_bosses/boss_phase')
require('lib/duel_bosses/boss_summon')

local CAST_DURATION = 8.2
local WINDOW = 6.2
local ROUND_COUNT = 2
local ROUND_INTERVAL = 3.6

local IMPACT_TIME = 1.33
local JUMP_HEIGHT = 420
local SEARCH_RANGE = 2500
local LAND_OFFSET = 160

local IMPACT_RADIUS = 500
local IMPACT_DAMAGE_PCT = 20
local IMPACT_STUN = 2.0

local SUMMON_NAME = "npc_ba_duel_skull_miner"
local SUMMON_TAG = "skull_miner"
local SUMMON_COUNT_PER_ROUND = 3
local SUMMON_MAX = 6
local SUMMON_RADIUS = 320

local SELF_HEAL_PCT = 5

local IMPACT_PARTICLE = "particles/econ/items/earthshaker/deep_magma/deep_magma_10th/deep_magma_10th_echoslam_start.vpcf"
local SUMMON_CREATE_PARTICLE = "particles/items2_fx/ward_die_generic_sentry.vpcf"
local SELF_HEAL_PARTICLE = "particles/killstreak/killstreak_ti10_hud_lv2.vpcf"

ba_duel_skull_phase = ba_duel_skull_phase or class({})

function ba_duel_skull_phase:OnAbilityPhaseInterrupted()
	-- прерывание фазы = только КД, без само-стана 4с (как в референсе)
	if IsServer() and not self:IsCooldownReady() then
		self:StartCooldown(self:GetCooldown(0))
	end
end

function ba_duel_skull_phase:OnSpellStart()
	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	DuelBossCast:OnSpellStart(self, { castDuration = CAST_DURATION })

	-- фазовый переход срабатывает один раз
	caster.duel_phase_done = true

	require('lib/duel_bosses/modifiers/modifier_duel_boss_frame')
	DuelBossFrameUtil:ResetPosture(caster)

	caster:EmitSound("Hero_EarthShaker.EchoSlam")

	-- окно фазы: инвулн + скрытие HP-бара + бафф фазы 2 после окна
	DuelBossPhase:Run(caster, self, {
		window = WINDOW,
		returnDur = 0,
		buff = true,
	})

	-- 2 прыжка-смэша внутри окна
	for round = 1, ROUND_COUNT do
		Timers:CreateTimer((round - 1) * ROUND_INTERVAL, function()
			if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
			local ok, err = pcall(function() self:StartSmashRound(caster, round) end)
			if not ok then
				print("[SKULL-PHASE] round error: " .. tostring(err))
			end
			return nil
		end)
	end
end

function ba_duel_skull_phase:StartSmashRound(caster, round)
	local landPos = self:ResolveLandingTarget(caster)

	DuelBossWarning:Ring(caster, self, landPos, IMPACT_RADIUS, IMPACT_TIME, { speed = 0 })
	caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_4, 1)

	local origin = caster:GetAbsOrigin()
	local control = origin + (landPos - origin) * 0.5 + Vector(0, 0, JUMP_HEIGHT)

	DuelBossMotion:Bezier(caster, origin, control, landPos, IMPACT_TIME, function(u, pos)
		return false
	end)

	Timers:CreateTimer(IMPACT_TIME, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
		local ok, err = pcall(function() self:ResolveSmashImpact(caster, round) end)
		if not ok then
			print("[SKULL-PHASE] impact error: " .. tostring(err))
		end
		return nil
	end)
end

function ba_duel_skull_phase:ResolveLandingTarget(caster)
	local origin = caster:GetAbsOrigin()
	local landPos = origin
	local target = DuelBossAim:GetNearestEnemy(caster, SEARCH_RANGE)

	if target then
		local dir = target:GetAbsOrigin() - origin
		dir.z = 0
		local dist = dir:Length2D()
		if dist > 0.01 then
			dir = dir / dist
			landPos = origin + dir * math.max(dist - LAND_OFFSET, 0)
		end
	end

	landPos.z = GetGroundPosition(landPos, caster).z

	local f = landPos - origin
	f.z = 0
	if f:Length2D() > 0.01 then
		caster:SetForwardVector(f:Normalized())
	end

	return landPos
end

function ba_duel_skull_phase:ResolveSmashImpact(caster, round)
	local impactPos = GetGroundPosition(caster:GetAbsOrigin(), caster)
	caster:SetAbsOrigin(impactPos)
	FindClearSpaceForUnit(caster, impactPos, true)

	-- эффект приземления
	local pfx = ParticleManager:CreateParticle(IMPACT_PARTICLE, PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(pfx, 0, impactPos)
	ParticleManager:SetParticleControl(pfx, 1, impactPos)
	ParticleManager:SetParticleShouldCheckFoW(pfx, false)
	ParticleManager:ReleaseParticleIndex(pfx)

	EmitSoundOnLocationWithCaster(impactPos, "Hero_EarthShaker.EchoSlam", caster)
	ScreenShake(impactPos, 18, 18, 0.35, 2200, 0, true)

	-- урон + стан
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(), impactPos, nil, IMPACT_RADIUS,
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0, FIND_ANY_ORDER, false
	)
	for _, enemy in ipairs(enemies) do
		if IsValidEntity(enemy) and enemy:IsAlive() and not enemy:IsCourier() then
			DuelBossDamage:Deal(self, caster, enemy, IMPACT_DAMAGE_PCT, 0)
			DuelBossDamage:Stun(enemy, caster, self, IMPACT_STUN)
		end
	end

	-- призыв минеров
	for i = 1, SUMMON_COUNT_PER_ROUND do
		local angle = math.pi * 2 * (i - 1) / SUMMON_COUNT_PER_ROUND + math.rad(40) * (round - 1)
		local offset = Vector(math.cos(angle) * SUMMON_RADIUS, math.sin(angle) * SUMMON_RADIUS, 0)
		local summonPos = GetGroundPosition(impactPos + offset, caster)
		local summon = DuelBossSummon:Create(caster, self, SUMMON_NAME, summonPos, SUMMON_TAG, SUMMON_MAX, {
			protect = 0.6,
			chase = true,
		})
		if summon then
			local sp = ParticleManager:CreateParticle(SUMMON_CREATE_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, summon)
			ParticleManager:ReleaseParticleIndex(sp)
			summon:StartGestureWithPlaybackRate(ACT_DOTA_SPAWN, 0.8)
		end
	end

	self:ApplySelfHeal(caster)
end

function ba_duel_skull_phase:ApplySelfHeal(caster)
	local healAmount = caster:GetMaxHealth() * SELF_HEAL_PCT / 100

	caster:StartGestureWithPlaybackRate(ACT_DOTA_ATTACK, 1.5)
	local pfx = ParticleManager:CreateParticle(SELF_HEAL_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, caster)

	caster:Heal(healAmount, caster)
	caster:EmitSound("Hero_EarthShaker.Totem")

	Timers:CreateTimer(2, function()
		if IsValidEntity(caster) and caster:IsAlive() then
			caster:Heal(healAmount, caster)
		end
		ParticleManager:DestroyParticle(pfx, false)
		ParticleManager:ReleaseParticleIndex(pfx)
		return nil
	end)
end