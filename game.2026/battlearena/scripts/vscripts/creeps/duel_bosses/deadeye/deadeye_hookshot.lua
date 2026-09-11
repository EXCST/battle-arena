-- creeps/duel_bosses/deadeye/deadeye_hookshot.lua
-- «Гранёный крюк» — escape-скилл (КД 7, коридор 0–450, прекаст 0.35с):
--   босс стреляет хукшотом Clockwerk в ближайшую «стену» (рейкаст от босса
--   ОТ агрессора до первого GridNav-блока) и подтягивается к точке якоря за 0.4с.
--   НА ПОЗИЦИИ ГЕРОЯ (где его прижали) вырастают 5 когсов (npc_ba_duel_cog):
--   турели стреляют сами, умирают от 5 атак, живой когс сжигает 10% текущей
--   маны/сек героям в 300 (modifier_deadeye_cog), жизнь 5с.
-- Визуал цепи: rattletrap_hookshot.vpcf (CP0=ствол, CP1=якорь) + страховочная
-- Line-полоса range_finder (если у цепя не те CP-соглашения — останется видимой полоса).

require('lib/duel_bosses/boss_cast')
require('lib/duel_bosses/boss_aim')
require('lib/duel_bosses/boss_predict')
require('lib/duel_bosses/boss_warning')
require('lib/duel_bosses/boss_damage')
require('lib/duel_bosses/boss_motion')
require('lib/duel_bosses/boss_summon')

local CAST_POINT = 0.35
local BUSY = 1.0
local HOOK_MIN = 600
local HOOK_MAX = 1000
local HOOK_STEP = 50
local PULL_TIME = 0.4
local COG_COUNT = 5
local COG_RING = 140
local COG_TAG = "deadeye_cog"
local COG_MAX = 10
local CHAIN_PFX = "particles/units/heroes/hero_rattletrap/rattletrap_hookshot.vpcf"
local MUZZLE_PFX = "particles/units/heroes/hero_sniper/sniper_base_attack_explosion_flash.vpcf"
local COG_DEPLOY_PFX = "particles/units/heroes/hero_rattletrap/rattletrap_cog_deploy.vpcf"

ba_duel_deadeye_hookshot = ba_duel_deadeye_hookshot or class({})

function ba_duel_deadeye_hookshot:OnAbilityPhaseStart()
	DuelBossCast:OnPhaseStart(self, { castPoint = CAST_POINT })
	return true
end

function ba_duel_deadeye_hookshot:OnAbilityPhaseInterrupted()
	DuelBossCast:OnPhaseInterrupted(self)
end

function ba_duel_deadeye_hookshot:OnSpellStart()
	DuelBossCast:OnSpellStart(self, { castDuration = BUSY })

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	print("[DEAD-DBG] hookshot OnSpellStart")

	local origin = caster:GetAbsOrigin()

	local threat = DuelBossAim:GetNearestEnemy(caster, 800)
	local away = caster:GetForwardVector()
	if threat then
		self.aim_hero = threat
		away = origin - threat:GetAbsOrigin()
	end
	away.z = 0
	if away:Length2D() < 0.1 then away = Vector(-1, 0, 0) end
	away = away:Normalized()

	local anchor = self:FindWallAnchor(caster, origin, away)

	-- цепь: составной партикл хукшота + страховочная светящаяся полоса
	self._anchor = anchor
	local chain = ParticleManager:CreateParticle(CHAIN_PFX, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(chain, 0, origin + Vector(0, 0, 64))
	ParticleManager:SetParticleControl(chain, 1, anchor + Vector(0, 0, 48))
	ParticleManager:SetParticleControl(chain, 2, Vector(PULL_TIME + 0.3, 0, 0))
	ParticleManager:SetParticleShouldCheckFoW(chain, false)
	Timers:CreateTimer(PULL_TIME + 0.35, function()
		ParticleManager:DestroyParticle(chain, true)
		ParticleManager:ReleaseParticleIndex(chain)
		return nil
	end)

	DuelBossWarning:Line(caster, self, origin + Vector(0, 0, 64), anchor, PULL_TIME, {
		startWidth = 60,
		endWidth = 24,
		type = 2,
	})

	caster:EmitSound("Hero_Rattletrap.Hookshot.Fire")
	local flash = ParticleManager:CreateParticle(MUZZLE_PFX, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(flash)

	DuelBossMotion:Mover(caster, anchor, PULL_TIME, function(u, pos)
		return false
	end)

	Timers:CreateTimer(PULL_TIME + 0.05, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
		local ok, err = pcall(function() self:PlantCogs(caster, origin) end)
		if not ok then
			print("[HOOKSHOT] PlantCogs error: " .. tostring(err))
		end
		return nil
	end)
end

-- рейкаст из босса «от агрессора»: первый непроходимый пиксель → якорь чуть раньше стены
function ba_duel_deadeye_hookshot:FindWallAnchor(caster, origin, away)
	local last = nil

	for dist = HOOK_MIN, HOOK_MAX, HOOK_STEP do
		for _, wobble in ipairs({ 0, 18, -18, 36, -36 }) do
			local dir = DuelBossPredict:RotateVector2D(away, wobble)
			local candidate = GetGroundPosition(origin + dir * dist, caster)

			if DuelBossPredict:IsWalkable(candidate) then
				last = candidate
			else
				-- упёрлись — якорь в последней проходимой точке (или откат на dist*0.8)
				if last then return last end
				return GetGroundPosition(origin + dir * math.max(dist - 150, 300), caster)
			end
		end
	end

	if last then return last end
	return GetGroundPosition(origin + away * (HOOK_MIN - 100), caster)
end

function ba_duel_deadeye_hookshot:PlantCogs(caster, origin)
	local hero = self.aim_hero
	local center = origin
	if hero and not hero:IsNull() and IsValidEntity(hero) and hero:IsAlive() then
		center = GetGroundPosition(hero:GetAbsOrigin(), caster)
	end

	print("[DEAD-DBG] cogs planted at hero pos")

	for i = 1, COG_COUNT do
		local angle = math.pi * 2 * (i - 1) / COG_COUNT + RandomFloat(0, 0.4)
		local pos = GetGroundPosition(center + Vector(math.cos(angle) * COG_RING, math.sin(angle) * COG_RING, 0), caster)

		local cog = DuelBossSummon:Create(caster, self, "npc_ba_duel_cog", pos, COG_TAG, COG_MAX, {
			protect = 0.35,
		})

		if cog then
			local deploy = ParticleManager:CreateParticle(COG_DEPLOY_PFX, PATTACH_ABSORIGIN_FOLLOW, cog)
			ParticleManager:ReleaseParticleIndex(deploy)
		end
	end
end
