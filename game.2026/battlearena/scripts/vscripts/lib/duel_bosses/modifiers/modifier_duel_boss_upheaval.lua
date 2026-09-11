-- lib/duel_bosses/modifiers/modifier_duel_boss_upheaval.lua
-- «Upheaval-давление» дуэльного босса (своя реализация идеи Warlock Upheaval из
-- референса, досье §11): на время фазового окна босс несёт ОГРОМНУЮ видимую зону
-- (фиолетовое кольцо r=2500), которая каждые 1с накладывает стаки:
--   стак: -12% скорости передвижения, -7% радиуса обзора (в %), до 10 стаков.
-- По окончании окна (смерть ауры-держателя) ВСЕ стаки снимаются — давление
-- живёт ровно столько, сколько фаза. IsDebuff=true → BKB/иммунитеты режут.
-- ⚠️ БЕЗ require('lib/timers'); Timers — глобал, usage только под IsServer.

modifier_duel_boss_upheaval_zone = modifier_duel_boss_upheaval_zone or class({})

local STACK_INTERVAL = 1.0
local STACK_DURATION = 4.0
local DEFAULT_RADIUS = 2000
local ZONE_COLOR = Vector(150, 0, 255)

function modifier_duel_boss_upheaval_zone:IsHidden()        return true  end
function modifier_duel_boss_upheaval_zone:IsPurgable()      return false end
function modifier_duel_boss_upheaval_zone:IsDebuff()         return false end
function modifier_duel_boss_upheaval_zone:DestroyOnExpire() return true  end

function modifier_duel_boss_upheaval_zone:OnCreated(params)
	if not IsServer() then return end

	local parent = self:GetParent()
	self._radius = (params and params.radius) or DEFAULT_RADIUS
	self._affected = {}

	-- WORLDORIGIN (не ABSORIGIN_FOLLOW): паттерн рабочих теллуров травалера и
	-- DuelBossWarning:RedCircle — ABSORIGIN_FOLLOW с этими частицами не рисует кольцо
	self._ground = ParticleManager:CreateParticle("particles/ui_mouseactions/tower_range_indicator_alt_ground.vpcf", PATTACH_WORLDORIGIN, nil)
	self._edge = ParticleManager:CreateParticle("particles/ui_mouseactions/tower_range_indicator_alt_edge_sharp.vpcf", PATTACH_WORLDORIGIN, nil)
	self:UpdateZoneParticles(parent)

	self._lastStack = 0
	self:StartIntervalThink(0.5)

	-- первый стак сразу при старте зоны
	self:ApplyStacks()
end

function modifier_duel_boss_upheaval_zone:UpdateZoneParticles(parent)
	local pos = parent:GetAbsOrigin()
	ParticleManager:SetParticleControl(self._ground, 0, pos)
	ParticleManager:SetParticleControl(self._ground, 2, pos)
	ParticleManager:SetParticleControl(self._ground, 3, Vector(self._radius, self._radius, self._radius))
	ParticleManager:SetParticleControl(self._ground, 4, ZONE_COLOR)
	ParticleManager:SetParticleControl(self._edge, 0, pos)
	ParticleManager:SetParticleControl(self._edge, 2, pos)
	ParticleManager:SetParticleControl(self._edge, 3, Vector(self._radius, self._radius, self._radius))
	ParticleManager:SetParticleControl(self._edge, 4, ZONE_COLOR)
end

function modifier_duel_boss_upheaval_zone:ApplyStacks()
	local parent = self:GetParent()
	if not IsValidEntity(parent) or not parent:IsAlive() then return end

	LinkLuaModifier("modifier_duel_boss_upheaval", "lib/duel_bosses/modifiers/modifier_duel_boss_upheaval", LUA_MODIFIER_MOTION_NONE)

	local enemies = FindUnitsInRadius(
		parent:GetTeamNumber(),
		parent:GetAbsOrigin(),
		nil,
		self._radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	for _, enemy in ipairs(enemies) do
		if IsValidEntity(enemy) and enemy:IsAlive() then
			enemy:AddNewModifier(parent, self:GetAbility(), "modifier_duel_boss_upheaval", { duration = STACK_DURATION })
			self._affected[enemy:entindex()] = true
		end
	end
end

function modifier_duel_boss_upheaval_zone:OnIntervalThink()
	if not IsServer() then return end

	local parent = self:GetParent()
	if not IsValidEntity(parent) or not parent:IsAlive() then return end

	-- зона следует за боссом (WORLDORIGIN — обновляем позицию колец тиком)
	self:UpdateZoneParticles(parent)

	self._lastStack = self._lastStack + 0.5
	if self._lastStack >= STACK_INTERVAL then
		self._lastStack = 0
		self:ApplyStacks()
	end
end

function modifier_duel_boss_upheaval_zone:OnDestroy()
	if not IsServer() then return end

	if self._ground then
		ParticleManager:DestroyParticle(self._ground, false)
		ParticleManager:ReleaseParticleIndex(self._ground)
	end
	if self._edge then
		ParticleManager:DestroyParticle(self._edge, false)
		ParticleManager:ReleaseParticleIndex(self._edge)
	end

	-- конец фазы = конец давления: снимаем стаки со всех задетых
	for idx, _ in pairs(self._affected or {}) do
		local unit = EntIndexToHScript(idx)
		if unit and not unit:IsNull() and IsValidEntity(unit) then
			unit:RemoveModifierByName("modifier_duel_boss_upheaval")
		end
	end
	self._affected = {}
end


-- ─── стак-дебафф ───

modifier_duel_boss_upheaval = modifier_duel_boss_upheaval or class({})

local MAX_STACKS = 10
local MS_PER_STACK = 12
local VISION_PER_STACK = 7

function modifier_duel_boss_upheaval:IsHidden()       return false end
function modifier_duel_boss_upheaval:IsPurgable()     return false end
function modifier_duel_boss_upheaval:IsDebuff()        return true  end
function modifier_duel_boss_upheaval:RemoveOnDeath()  return true  end

function modifier_duel_boss_upheaval:OnCreated()
	if not IsServer() then return end
	self:SetStackCount(1)
end

function modifier_duel_boss_upheaval:OnRefresh()
	if not IsServer() then return end
	if self:GetStackCount() < MAX_STACKS then
		self:SetStackCount(self:GetStackCount() + 1)
	end
end

function modifier_duel_boss_upheaval:GetTexture()
	return "warlock_upheaval"
end

function modifier_duel_boss_upheaval:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_BONUS_VISION_PERCENTAGE,
	}
end

function modifier_duel_boss_upheaval:GetModifierMoveSpeedBonus_Percentage()
	return -MS_PER_STACK * self:GetStackCount()
end

function modifier_duel_boss_upheaval:GetBonusVisionPercentage()
	return -VISION_PER_STACK * self:GetStackCount()
end
