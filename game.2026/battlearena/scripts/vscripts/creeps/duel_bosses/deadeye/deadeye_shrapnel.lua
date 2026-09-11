-- creeps/duel_bosses/deadeye/deadeye_shrapnel.lua
-- «Шрапнель» (по требованию пользователя): залпы по 5 областей вдоль линии на
-- героя, каждая зона живёт 2с и тикает уроном, всего 3 залпа.
--   прекаст 0.9с → залп1; интервал 1.6с; зоны: r250, падение 0.7с (кольцо-
--   предупреждение схлопывается), тик 0.5с × 5% (=10%/сек, решение пользователя).
-- Токен-гард: смерть/стан босса прерывают оставшиеся залпы (паттерн камней).

require('lib/duel_bosses/boss_cast')
require('lib/duel_bosses/boss_aim')
require('lib/duel_bosses/boss_predict')
require('lib/duel_bosses/boss_warning')
require('lib/duel_bosses/boss_damage')

local CAST_POINT = 0.9
local VOLLEYS = 3
local VOLLEY_INTERVAL = 1.6
local ZONES = 5
local ZONE_RADIUS = 250
local FALL_TIME = 0.7
local ZONE_DURATION = 2.0
local TICK_INTERVAL = 0.5
local TICK_PCT = 5
local FIRST_DIST = 400
local ZONE_STEP = 350
local JITTER = 80
local CHANNEL = 6.6

local IMPACT_PFX = "particles/units/heroes/hero_sniper/sniper_shrapnel_impacts.vpcf"

ba_duel_deadeye_shrapnel = ba_duel_deadeye_shrapnel or class({})

function ba_duel_deadeye_shrapnel:OnAbilityPhaseStart()
	DuelBossCast:OnPhaseStart(self, { castPoint = CAST_POINT })

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return true end

	local target = DuelBossAim:GetSmartTarget(caster, 3500)
	if target then
		DuelBossAim:LockTarget(caster, target, CAST_POINT, 90)
	end

	return true
end

function ba_duel_deadeye_shrapnel:OnAbilityPhaseInterrupted()
	DuelBossCast:OnPhaseInterrupted(self)
end

function ba_duel_deadeye_shrapnel:OnSpellStart()
	DuelBossCast:OnSpellStart(self, { castDuration = CHANNEL })

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	print("[DEAD-DBG] shrapnel OnSpellStart")

	caster.shrapnel_token = DoUniqueString("ba_duel_deadeye_shrapnel")

	self:FireVolley(caster, 1, caster.shrapnel_token)
end

function ba_duel_deadeye_shrapnel:FireVolley(caster, volley, token)
	if not IsValidEntity(caster) or not caster:IsAlive() then return end
	if token ~= caster.shrapnel_token then return end
	if caster:IsStunned() or caster:IsHexed() then return end
	if volley > VOLLEYS then return end

	local ok, err = pcall(function() self:Barrage(caster, volley) end)
	if not ok then
		print("[SHRAPNEL] volley error: " .. tostring(err))
	end

	if volley < VOLLEYS then
		Timers:CreateTimer(VOLLEY_INTERVAL, function()
			if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
			local ok2, err2 = pcall(function() self:FireVolley(caster, volley + 1, token) end)
			if not ok2 then
				print("[SHRAPNEL] volley timer error: " .. tostring(err2))
			end
			return nil
		end)
	end
end

function ba_duel_deadeye_shrapnel:Barrage(caster, volley)
	local target = DuelBossAim:GetSmartTarget(caster, 3500)
	if not target then return end

	caster:StartGestureWithPlaybackRate(ACT_DOTA_ATTACK, 1.3)
	caster:EmitSound("Hero_Sniper.PreAttack")

	local origin = caster:GetAbsOrigin()
	local dir = target:GetAbsOrigin() - origin
	dir.z = 0
	if dir:Length2D() < 1 then return end
	dir = dir:Normalized()

	-- перпендикуляр для джиттера вдоль линии
	local perp = Vector(-dir.y, dir.x, 0)

	--Lead для «упегающего» героя: цепочка берёт упреждение по концу линии
	local lineLead = DuelBossPredict:LeadPosition(target, (FIRST_DIST + ZONES * ZONE_STEP) / 1400)
	local leadDir = lineLead - origin
	leadDir.z = 0
	if leadDir:Length2D() > 1 then
		dir = leadDir:Normalized()
		perp = Vector(-dir.y, dir.x, 0)
	end

	for i = 1, ZONES do
		local dist = FIRST_DIST + (i - 1) * ZONE_STEP + RandomFloat(-JITTER, JITTER)
		local point = origin + dir * dist + perp * RandomFloat(-JITTER, JITTER)
		point = GetGroundPosition(point, caster)

		self:DropZone(caster, point)
	end
end

function ba_duel_deadeye_shrapnel:DropZone(caster, point)
	-- предупреждение: схлопывающееся кольцо на время падения
	DuelBossWarning:Ring(caster, self, point, ZONE_RADIUS, FALL_TIME)

	Timers:CreateTimer(FALL_TIME, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end

		caster:EmitSound("Hero_Sniper.ShrapnelShatter")

		-- видимая зона горения (проверенный primitive; частица shrapnel_impacts
		-- безизвестных CP-соглашений могла не рисоваться)
		DuelBossWarning:RedCircle(caster, self, point, ZONE_RADIUS, FALL_TIME + ZONE_DURATION)

		local impact = ParticleManager:CreateParticle(IMPACT_PFX, PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(impact, 0, point)
		ParticleManager:SetParticleControl(impact, 2, point)
		ParticleManager:SetParticleControl(impact, 3, Vector(ZONE_RADIUS, ZONE_RADIUS, ZONE_RADIUS))
		ParticleManager:SetParticleShouldCheckFoW(impact, false)
		Timers:CreateTimer(ZONE_DURATION, function()
			ParticleManager:DestroyParticle(impact, false)
			ParticleManager:ReleaseParticleIndex(impact)
			return nil
		end)

		local ticks = math.floor(ZONE_DURATION / TICK_INTERVAL)

		Timers:CreateTimer(TICK_INTERVAL, function()
			if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
			DuelBossDamage:DealToArea(self, caster, point, ZONE_RADIUS, TICK_PCT, 0)
			ticks = ticks - 1
			if ticks <= 0 then return nil end
			return TICK_INTERVAL
		end)

		return nil
	end)
end
