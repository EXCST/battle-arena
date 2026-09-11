-- creeps/duel_bosses/deadeye/deadeye_phase.lua
-- Фаза «Барраж» ≤60% (один раз, gate в DuelBossAI): окно неуязвимости 6.2с
-- (DuelBossPhase штатный бафф после) → СРАЗУ по концу окна — 360°-веер пуль по
-- схеме phantome_ab6 из референса (облегчённый): кольца 10/13/16 снарядов, шаг 1с,
-- шахматный доворот колец + случайный твист, speed 1100, дальность 2600, r60,
-- 15% макс.HP за попадание (без hit-map — в упор ловишь несколько пуль), hit-once
-- на снаряд. Плюс прежний «Транс канонира» (−25% КД, GetModifierPercentageCooldown
-- += по инвертированному знаку сборки).

require('lib/duel_bosses/boss_cast')
require('lib/duel_bosses/boss_phase')
require('lib/duel_bosses/boss_damage')
require('lib/duel_bosses/boss_aim')

local CAST_DURATION = 8.2
local WINDOW = 6.2
local ROUNDS = { 10, 13, 16 }
local ROUND_INTERVAL = 1.0
local SPEED = 1100
local DISTANCE = 2600
local RADIUS = 60
local DAMAGE_PCT = 15
local TRANCE_PARTICLE = "particles/units/heroes/hero_sniper/sniper_take_aim_overhead.vpcf"
-- линейные снаряды: проверенный ванильный «красный шоквейв» тонкого радиуса
-- (снайперский base_attack как EffectName у linear-снаряда в этой сборке не виден)
local BULLET_PFX = "particles/magnataur_shockwave_red.vpcf"
local MUZZLE_PFX = "particles/units/heroes/hero_sniper/sniper_base_attack_explosion_flash.vpcf"

LinkLuaModifier("modifier_deadeye_trance", "creeps/duel_bosses/deadeye/deadeye_phase", LUA_MODIFIER_MOTION_NONE)

ba_duel_deadeye_phase = ba_duel_deadeye_phase or class({})

function ba_duel_deadeye_phase:OnAbilityPhaseInterrupted()
	-- прерывание фазы = только КД, без само-стана (как у skull_phase)
	if IsServer() and not self:IsCooldownReady() then
		self:StartCooldown(self:GetCooldown(0))
	end
end

function ba_duel_deadeye_phase:OnSpellStart()
	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	DuelBossCast:OnSpellStart(self, { castDuration = CAST_DURATION })

	print("[DEAD-DBG] phase OnSpellStart")

	caster.duel_phase_done = true

	require('lib/duel_bosses/modifiers/modifier_duel_boss_frame')
	DuelBossFrameUtil:ResetPosture(caster)

	caster:EmitSound("Hero_PrimalBeast.Uproar.Cast")
	ScreenShake(caster:GetAbsOrigin(), 12, 12, 0.4, 2000, 0, true)

	DuelBossPhase:Run(caster, self, {
		window = WINDOW,
		returnDur = 0,
		buff = true,
		onWindowEnd = function(unit)
			LinkLuaModifier("modifier_deadeye_trance", "creeps/duel_bosses/deadeye/deadeye_phase", LUA_MODIFIER_MOTION_NONE)
			unit:AddNewModifier(unit, self, "modifier_deadeye_trance", { duration = -1 })

			for i, count in ipairs(ROUNDS) do
				Timers:CreateTimer((i - 1) * ROUND_INTERVAL, function()
					if not IsValidEntity(unit) or not unit:IsAlive() then return nil end
					local ok, err = pcall(function() self:FireRing(unit, i, count) end)
					if not ok then
						print("[DEADEYE] barrage ring error: " .. tostring(err))
					end
					return nil
				end)
			end
		end,
	})
end

function ba_duel_deadeye_phase:FireRing(caster, round, count)
	print("[DEAD-DBG] barrage ring " .. tostring(round) .. " x" .. tostring(count))

	local origin = caster:GetAbsOrigin()
	local angleStep = 360 / count
	local twist = RandomFloat(0, angleStep)
	local baseAngle = (round - 1) * angleStep / 2 + twist

	caster:StartGestureWithPlaybackRate(ACT_DOTA_ATTACK, 1.8)
	caster:EmitSound("Hero_Sniper.AssassinateProjectile")

	local flash = ParticleManager:CreateParticle(MUZZLE_PFX, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(flash)
	ScreenShake(origin, 8, 8, 0.2, 1400, 0, true)

	local spawn = origin + Vector(0, 0, 60)

	for i = 1, count do
		local angle = math.rad(baseAngle + (i - 1) * angleStep)
		local dir = Vector(math.cos(angle), math.sin(angle), 0)

		ProjectileManager:CreateLinearProjectile({
			Ability = self,
			Source = caster,
			vSpawnOrigin = spawn,
			vVelocity = dir * SPEED,
			fDistance = DISTANCE,
			fStartRadius = RADIUS,
			fEndRadius = RADIUS,
			fExpireTime = GameRules:GetGameTime() + DISTANCE / SPEED + 0.5,
			EffectName = BULLET_PFX,
			bDodgeable = false,
			bIgnoreSource = true,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			iUnitTargetFlags = 0,
		})
	end
end

function ba_duel_deadeye_phase:OnProjectileHit(hTarget, vLocation)
	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return false end
	if not IsValidEntity(hTarget) or not hTarget:IsAlive() then return true end
	if hTarget:IsCourier() then return false end

	DuelBossDamage:Deal(self, caster, hTarget, DAMAGE_PCT, 0)
	hTarget:EmitSound("Hero_Sniper.AssassinateDamage")

	return true
end

-- ─── транс канонира ───

modifier_deadeye_trance = modifier_deadeye_trance or class({})

function modifier_deadeye_trance:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
	}
end

-- ⚠️ В этой сборке знак ИНВЕРТИРОВАН: положительное = снижение КД
function modifier_deadeye_trance:GetModifierPercentageCooldown()
	return 25
end

function modifier_deadeye_trance:IsHidden() return false end
function modifier_deadeye_trance:IsPurgable() return false end
function modifier_deadeye_trance:RemoveOnDeath() return false end

function modifier_deadeye_trance:GetTexture()
	return "sniper_take_aim"
end

function modifier_deadeye_trance:GetEffectName()
	return TRANCE_PARTICLE
end

function modifier_deadeye_trance:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
