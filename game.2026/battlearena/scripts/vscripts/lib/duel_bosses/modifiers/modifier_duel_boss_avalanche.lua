-- lib/duel_bosses/modifiers/modifier_duel_boss_avalanche.lua
-- Каменная волна дуэльного босса: медленно движущийся фронт-мысль — поведение
-- 1-в-1 как elite_025 «Обвал» из референса (досье docs/boss_ai_reference.md §11):
-- thinker идёт по dir 500 u/s 3с, фронт tiny_avalanche_lvl4 (CP1=радиус),
-- каждые 0.3с — крок-залп tiny_avalanche_projectile_lvl4, каждые 0.2с —
-- ТИКОВЫЙ урон 8% макс.HP + стан 0.1с всем в радиусе 250 (дрожание-лок,
-- без hit-map — «вариться» в волне нельзя).
-- ⚠️ НЕ требовать lib/timers — Timers глобал на сервере; клиентские ветки не
-- должны обращаться к Timers/GetRemainingTime до IsServer-guard.

modifier_duel_boss_avalanche = modifier_duel_boss_avalanche or class({})

local SPEED = 500
local RADIUS = 250
local BURST_INTERVAL = 0.3
local DAMAGE_INTERVAL = 0.2
local DAMAGE_PCT = 8
local STUN_DURATION = 0.1

local AVALANCHE_PFX = "particles/units/heroes/hero_tiny/tiny_avalanche_lvl4.vpcf"
local BURST_PFX = "particles/units/heroes/hero_tiny/tiny_avalanche_projectile_lvl4.vpcf"

function modifier_duel_boss_avalanche:IsHidden()        return true  end
function modifier_duel_boss_avalanche:IsPurgable()      return false end
function modifier_duel_boss_avalanche:IsDebuff()         return false end
function modifier_duel_boss_avalanche:DestroyOnExpire() return true  end

function modifier_duel_boss_avalanche:OnCreated(params)
	if not IsServer() then return end

	local parent = self:GetParent()
	self._dir = Vector(params.dir_x or 1, params.dir_y or 0, 0)
	local len = self._dir:Length2D()
	if len < 0.001 then self._dir = Vector(1, 0, 0) else self._dir = self._dir:Normalized() end

	self._burstT = BURST_INTERVAL
	self._damageT = 0

	self._pfx = ParticleManager:CreateParticle(AVALANCHE_PFX, PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControlTransformForward(self._pfx, 0, parent:GetAbsOrigin(), self._dir)
	ParticleManager:SetParticleControl(self._pfx, 1, Vector(RADIUS, RADIUS, RADIUS))
	self:AddParticle(self._pfx, false, false, -1, false, false)

	self:StartIntervalThink(FrameTime())
end

function modifier_duel_boss_avalanche:OnIntervalThink()
	if not IsServer() then return end

	local parent = self:GetParent()
	if not IsValidEntity(parent) or parent:IsNull() then
		self:Destroy()
		return
	end

	local dt = FrameTime()
	local pos = parent:GetAbsOrigin()
	local newPos = pos + self._dir * (SPEED * dt)
	newPos.z = GetGroundPosition(newPos, parent).z
	parent:SetAbsOrigin(newPos)

	self._burstT = self._burstT + dt
	if self._burstT >= BURST_INTERVAL then
		self._burstT = self._burstT - BURST_INTERVAL
		local proj = ParticleManager:CreateParticle(BURST_PFX, PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(proj, 0, newPos)
		ParticleManager:SetParticleControl(proj, 1, self._dir * 100)
		Timers:CreateTimer(BURST_INTERVAL, function()
			ParticleManager:DestroyParticle(proj, false)
			ParticleManager:ReleaseParticleIndex(proj)
			return nil
		end)
	end

	self._damageT = self._damageT + dt
	if self._damageT >= DAMAGE_INTERVAL then
		self._damageT = self._damageT - DAMAGE_INTERVAL

		local caster = self:GetCaster()
		if not IsValidEntity(caster) or not caster:IsAlive() then return end

		local enemies = FindUnitsInRadius(
			caster:GetTeamNumber(),
			newPos,
			nil,
			RADIUS,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false
		)

		-- тиковый урон + стан-дрожание (паттерн elite_025): пока волна на цели,
		-- каждая 0.2с — 8% макс.HP и стан 0.1с напрямую (без частиц-спама)
		require('lib/duel_bosses/boss_damage')
		for _, enemy in ipairs(enemies) do
			if IsValidEntity(enemy) and enemy:IsAlive() and not enemy:IsCourier() then
				enemy:AddNewModifier(caster, self:GetAbility(), "modifier_stunned", { duration = STUN_DURATION })
				DuelBossDamage:Deal(self:GetAbility(), caster, enemy, DAMAGE_PCT, 0)
			end
		end
	end
end

function modifier_duel_boss_avalanche:OnDestroy()
	if not IsServer() then return end
	local parent = self:GetParent()
	if parent and IsValidEntity(parent) and not parent:IsNull() then
		parent:RemoveSelf()
	end
end
