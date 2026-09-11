-- creeps/duel_bosses/deadeye/deadeye_grenade.lua
-- «Контуждающая граната»: 3 залпа × 3 гранаты (по требованию пользователя).
-- Каждый залп РЕ-АИМIT threat-цель (уходящий герой получает новый кластер далеко
-- от старого — «залпы на значительном расстоянии»), кластер: 3 точки вокруг
-- LeadPosition (радиус CLUSTER_RADIUS, разнос MIN_SPACING).
-- Каждая граната: кольцо-предупреждение r280 (0.9с) → модель гранаты Снайпера по
-- дуге (tracking на dummy) → взрыв r300: 15% макс.HP + контужение
-- (modifier_duel_boss_smoke: −45% меткости, 3.5с).
-- Токен-гард: смерть/стан босса прерывают залпы (паттерн камней).

require('lib/duel_bosses/boss_cast')
require('lib/duel_bosses/boss_aim')
require('lib/duel_bosses/boss_predict')
require('lib/duel_bosses/boss_warning')
require('lib/duel_bosses/boss_damage')
require('lib/duel_bosses/modifiers/modifier_duel_boss_smoke')

local CAST_POINT = 0.8
local VOLLEYS = 3
local VOLLEY_INTERVAL = 1.4
local PER_VOLLEY = 3
-- широкий разброс (жалоба v3: «все в одну точку»): кластер 240 с разносом 150,
-- каждый следующий залп упреждает ЦЕЛИКА дальше по пути (ползущий ковёр, как у камней)
local CLUSTER_RADIUS = 240
local MIN_SPACING = 150
local VOLLEY_LEAD_STEP = 0.6
local STAGGER = 0.12
local RING_RADIUS = 280
local RING_DURATION = 0.9
local BLAST_RADIUS = 300
local DAMAGE_PCT = 15
local CONCUSS_DURATION = 3.5
local TRAVEL_TIME = 0.9
local PROJECTILE_SPEED = 900
local CHANNEL = 5.4

local GRENADE_PFX = "particles/units/heroes/hero_sniper/sniper_shard_concussive_grenade_model.vpcf"
local BOOM_PFX = "particles/units/heroes/hero_sniper/sniper_shard_concussive_grenade_impact_burst.vpcf"
local SMOKE_PFX = "particles/units/heroes/hero_sniper/sniper_shard_concussive_grenade_impact_smoke.vpcf"

ba_duel_deadeye_grenade = ba_duel_deadeye_grenade or class({})

function ba_duel_deadeye_grenade:OnAbilityPhaseStart()
	DuelBossCast:OnPhaseStart(self, { castPoint = CAST_POINT })

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return true end

	local target = DuelBossAim:GetSmartTarget(caster, 3500)
	if target then
		DuelBossAim:LockTarget(caster, target, CAST_POINT, 60)
	end

	return true
end

function ba_duel_deadeye_grenade:OnAbilityPhaseInterrupted()
	DuelBossCast:OnPhaseInterrupted(self)
end

function ba_duel_deadeye_grenade:OnSpellStart()
	DuelBossCast:OnSpellStart(self, { castDuration = CHANNEL })

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	print("[DEAD-DBG] grenade OnSpellStart")

	caster.grenade_token = DoUniqueString("ba_duel_deadeye_grenade")

	self:FireVolley(caster, 1, caster.grenade_token)
end

function ba_duel_deadeye_grenade:FireVolley(caster, volley, token)
	if not IsValidEntity(caster) or not caster:IsAlive() then return end
	if token ~= caster.grenade_token then return end
	if caster:IsStunned() or caster:IsHexed() then return end
	if volley > VOLLEYS then return end

	local ok, err = pcall(function() self:ThrowVolley(caster, volley, token) end)
	if not ok then
		print("[GRENADE] volley error: " .. tostring(err))
	end

	if volley < VOLLEYS then
		Timers:CreateTimer(VOLLEY_INTERVAL, function()
			if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
			local ok2, err2 = pcall(function() self:FireVolley(caster, volley + 1, token) end)
			if not ok2 then
				print("[GRENADE] volley timer error: " .. tostring(err2))
			end
			return nil
		end)
	end
end

function ba_duel_deadeye_grenade:ThrowVolley(caster, volley, token)
	local target = DuelBossAim:GetSmartTarget(caster, 3500)
	if not target then return end

	-- каждый следующий залп берёт всё большее упреждение — «дорожка» гранат
	-- тянется за убегающим героем, а не складывается в одну точку
	local base = DuelBossPredict:LeadPosition(target, TRAVEL_TIME + (volley - 1) * VOLLEY_LEAD_STEP)
	base = GetGroundPosition(base, caster)

	caster:StartGestureWithPlaybackRate(ACT_DOTA_ATTACK, 1.4)
	caster:EmitSound("Hero_PrimalBeast.RockThrow.Throw")

	local points = self:BuildCluster(base, PER_VOLLEY)

	for i, point in ipairs(points) do
		Timers:CreateTimer((i - 1) * STAGGER, function()
			if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
			if token ~= caster.grenade_token then return nil end

			local ok, err = pcall(function() self:ThrowSingle(caster, point) end)
			if not ok then
				print("[GRENADE] throw error: " .. tostring(err))
			end
			return nil
		end)
	end
end

function ba_duel_deadeye_grenade:BuildCluster(center, count)
	local pts = {}

	for _ = 1, count do
		local p = nil
		for _ = 1, 24 do
			local angle = RandomFloat(0, 360)
			local r = RandomFloat(0, CLUSTER_RADIUS)
			local candidate = center + Vector(math.cos(angle * math.pi / 180) * r, math.sin(angle * math.pi / 180) * r, 0)

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

		if not p then p = DuelBossPredict:RandomOffset(center, 0, CLUSTER_RADIUS) end
		p.z = center.z
		pts[#pts + 1] = p
	end

	return pts
end

function ba_duel_deadeye_grenade:ThrowSingle(caster, point)
	DuelBossWarning:Ring(caster, self, point, RING_RADIUS, RING_DURATION, { speed = 0 })

	local dummy = CreateModifierThinker(nil, self, "modifier_duel_boss_dummy", { duration = 4 }, point, DOTA_TEAM_GOODGUYS, false)
	if not dummy or dummy:IsNull() then return end

	ProjectileManager:CreateTrackingProjectile({
		Target = dummy,
		Source = caster,
		Ability = self,
		EffectName = GRENADE_PFX,
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

function ba_duel_deadeye_grenade:OnProjectileHit_ExtraData(target, location, extraData)
	local caster = self:GetCaster()
	print("[DEAD-DBG] grenade HIT")
	if not IsValidEntity(caster) or not caster:IsAlive() then return end
	if not extraData then return end

	local point = Vector(extraData.point_x, extraData.point_y, extraData.point_z)

	caster:EmitSound("Hero_Sniper.ShrapnelShatter")

	local boom = ParticleManager:CreateParticle(BOOM_PFX, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(boom, 0, point)
	ParticleManager:ReleaseParticleIndex(boom)

	local smoke = ParticleManager:CreateParticle(SMOKE_PFX, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(smoke, 0, point)
	ParticleManager:SetParticleControl(smoke, 2, point)
	ParticleManager:SetParticleControl(smoke, 3, Vector(BLAST_RADIUS, BLAST_RADIUS, BLAST_RADIUS))
	ParticleManager:ReleaseParticleIndex(smoke)

	ScreenShake(point, 10, 10, 0.25, 1200, 0, true)

	DuelBossDamage:DealToArea(self, caster, point, BLAST_RADIUS, DAMAGE_PCT, 0)

	local victims = FindUnitsInRadius(
		caster:GetTeamNumber(),
		point,
		nil,
		BLAST_RADIUS,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		0,
		FIND_ANY_ORDER,
		false
	)

	for _, v in ipairs(victims) do
		if IsValidEntity(v) and v:IsAlive() and not v:IsCourier() then
			v:AddNewModifier(caster, self, "modifier_duel_boss_smoke", { duration = CONCUSS_DURATION })
		end
	end

	if extraData.dummy then
		local d = EntIndexToHScript(extraData.dummy)
		if d and not d:IsNull() and IsValidEntity(d) then
			d:RemoveSelf()
		end
	end
end
