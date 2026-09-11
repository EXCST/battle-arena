-- lib/duel_bosses/modifiers/modifier_duel_boss_skull_arena.lua
-- Арена-зона «Воина Пустоши» (порт elite_042):
--   modifier_duel_boss_skull_arena_zone     — thinker-аура круга (враги внутри получают границу)
--   modifier_duel_boss_skull_arena_boundary — «не выпускает из круга» (кламп + FindClearSpace)
--   modifier_duel_boss_skull_arena_buff     — +100 AS на время зоны
-- ⚠️ БЕЗ require('lib/timers') — Timers глобал сервера.

LinkLuaModifier("modifier_duel_boss_skull_arena_zone", "lib/duel_bosses/modifiers/modifier_duel_boss_skull_arena", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_duel_boss_skull_arena_boundary", "lib/duel_bosses/modifiers/modifier_duel_boss_skull_arena", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_duel_boss_skull_arena_buff", "lib/duel_bosses/modifiers/modifier_duel_boss_skull_arena", LUA_MODIFIER_MOTION_NONE)

modifier_duel_boss_skull_arena_zone = modifier_duel_boss_skull_arena_zone or class({})

function modifier_duel_boss_skull_arena_zone:OnCreated(params)
	if not IsServer() then return end
	self._center = Vector(params.center_x or 0, params.center_y or 0, params.center_z or 0)
	self._radius = params.radius or 850
	self._caster = self:GetCaster()
	self._pfx = params.pfx
	self:StartIntervalThink(0.5)
end

-- зона живёт, пока жив кастер (иначе 15с держит игроков в круге после кила босса)
function modifier_duel_boss_skull_arena_zone:OnIntervalThink()
	if not IsServer() then return end
	if not IsValidEntity(self._caster) or not self._caster:IsAlive() then
		self:Destroy()
	end
end

function modifier_duel_boss_skull_arena_zone:OnRefresh(params)
	self:OnCreated(params)
end

function modifier_duel_boss_skull_arena_zone:IsAura() return true end
function modifier_duel_boss_skull_arena_zone:GetAuraRadius() return self._radius end
function modifier_duel_boss_skull_arena_zone:GetModifierAura() return "modifier_duel_boss_skull_arena_boundary" end
function modifier_duel_boss_skull_arena_zone:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_duel_boss_skull_arena_zone:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_duel_boss_skull_arena_zone:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_duel_boss_skull_arena_zone:GetAuraDuration() return 0.2 end
function modifier_duel_boss_skull_arena_zone:IsHidden() return true end
function modifier_duel_boss_skull_arena_zone:IsPurgable() return false end


modifier_duel_boss_skull_arena_boundary = modifier_duel_boss_skull_arena_boundary or class({})

function modifier_duel_boss_skull_arena_boundary:OnCreated()
	if not IsServer() then return end

	local owner = self:GetAuraOwner()
	local zone = owner and owner:FindModifierByName("modifier_duel_boss_skull_arena_zone")
	if zone then
		self._center = zone._center
		self._radius = zone._radius
	end

	if not self._center then
		self:Destroy()
		return
	end

	self:StartIntervalThink(FrameTime())
end

function modifier_duel_boss_skull_arena_boundary:OnIntervalThink()
	if not IsServer() then return end

	local parent = self:GetParent()
	if not IsValidEntity(parent) or not parent:IsAlive() or not self._center then
		self:Destroy()
		return
	end

	local origin = parent:GetAbsOrigin()
	local delta = origin - self._center
	local dist = delta:Length2D()
	local hull = parent:GetHullRadius() or 0
	local maxDist = math.max(self._radius - hull, 0)

	if dist > maxDist then
		local dir = delta
		if dist > 1 then dir = delta / dist else dir = Vector(1, 0, 0) end
		local clampPos = self._center + dir * maxDist
		clampPos.z = origin.z
		FindClearSpaceForUnit(parent, clampPos, true)
	end
end

function modifier_duel_boss_skull_arena_boundary:IsHidden() return true end
function modifier_duel_boss_skull_arena_boundary:IsPurgable() return false end


modifier_duel_boss_skull_arena_buff = modifier_duel_boss_skull_arena_buff or class({})

function modifier_duel_boss_skull_arena_buff:GetModifierAttackSpeedBonus_Constant()
	return 100
end

function modifier_duel_boss_skull_arena_buff:IsPurgable() return false end
function modifier_duel_boss_skull_arena_buff:IsHidden() return false end