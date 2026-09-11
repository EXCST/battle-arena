-- ============================================================
-- BATTLE ARENA — Travaler: Сдвиг Миров (фаза 2)
-- Серия из 3-5 волн телепортаций с интервалом 5с. Каждая волна:
-- красные теллуры под врагами дальше min_dist от босса (1.5с),
-- затем телепорт на рандомную валидную точку ~teleport_dist
-- от точки спавна босса + урон %HP + замедление.
-- ============================================================

travaler_shift = travaler_shift or class({})

local ability = travaler_shift

require('lib/ability_kv')
require('creeps/boss/travaler/travaler_helpers')

LinkLuaModifier("modifier_travaler_shift_slow", "creeps/boss/travaler/modifiers/modifier_travaler_shift_slow", LUA_MODIFIER_MOTION_NONE)

local CAST_GESTURE = ACT_DOTA_CAST_ABILITY_3
local LAND_PARTICLE = "particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf"


--- Рандомная валидная точка на dist от базовой (GridNav-проверка).
local function GetValidPoint(base, unit, dist)
	for i = 1, 10 do
		local p = GetGroundPosition(base + RandomVector(dist), unit)

		if GridNav:CanFindPath(base, p) then
			return p
		end
	end

	return GetGroundPosition(base + RandomVector(dist), unit)
end


function ability:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()

	local waves_min 	= AbilityKV:Get(self, "waves_min")
	local waves_max 	= AbilityKV:Get(self, "waves_max")
	local interval 		= AbilityKV:Get(self, "interval")

	local waves = RandomInt(waves_min, waves_max)

	caster:StartGesture(CAST_GESTURE)
	caster:EmitSound("Boss_Travaler.Shift.Cast")

	for w = 1, waves do
		Timers:CreateTimer((w - 1) * interval, TravalerHelpers:SafeTimer(function()
			if not IsValidEntity(caster) or not caster:IsAlive() then return end

			self:Wave(caster, w)
		end))
	end
end


function ability:Wave(caster, wave)
	local center = caster:GetAbsOrigin()

	local radius 		= AbilityKV:Get(self, "radius")
	local min_dist 		= AbilityKV:Get(self, "min_dist")
	local teleport_dist = AbilityKV:Get(self, "teleport_dist")
	local delay 		= AbilityKV:Get(self, "delay")
	local damage_pct 	= AbilityKV:Get(self, "damage_pct")
	local slow_duration = AbilityKV:Get(self, "slow_duration")
	local mark_radius 	= AbilityKV:Get(self, "mark_radius")

	-- точка спавна босса (захвачена AI на первом валидном тике)
	local base = caster.travaler_spawn

	if not base or base:Length2D() < 1 then base = center end

	-- враги дальше min_dist от босса
	local enemies = TravalerHelpers:FindEnemies(caster:GetTeamNumber(), center, radius)
	local marks = {}

	for _, enemy in ipairs(enemies) do
		if IsValidEntity(enemy) and (enemy:GetAbsOrigin() - center):Length2D() > min_dist then
			marks[#marks + 1] = {
				unit = enemy,
				pos = enemy:GetAbsOrigin(),
				telegraph = TravalerHelpers:CreateTelegraph(enemy:GetAbsOrigin(), mark_radius),
			}
		end
	end

	if #marks == 0 then return end

	EmitSoundOnLocationWithCaster(center, "Boss_Travaler.Shift.Wave", caster)

	Timers:CreateTimer(delay, TravalerHelpers:SafeTimer(function()
		-- маркеры гасим ДО ранних return
		for _, mark in ipairs(marks) do
			TravalerHelpers:DestroyTelegraph(mark.telegraph)
		end

		if not IsValidEntity(caster) or not caster:IsAlive() then return end

		for _, mark in ipairs(marks) do
			local target = mark.unit

			if IsValidEntity(target) and target:IsAlive() then
				local point = GetValidPoint(base, target, teleport_dist)

				MinimapEvent(caster:GetTeam(), target, point.x, point.y, DOTA_MINIMAP_EVENT_ENEMY_TELEPORTING, target:GetEntityIndex())

				local p = ParticleManager:CreateParticle(LAND_PARTICLE, PATTACH_WORLDORIGIN, nil)
				ParticleManager:SetParticleControl(p, 0, point)
				ParticleManager:SetParticleControl(p, 1, Vector(200, 1, 1))
				ParticleManager:ReleaseParticleIndex(p)

				FindClearSpaceForUnit(target, point, true)
				target:Stop()

				TravalerHelpers:DealDamageCustom(self, caster, target, 0, damage_pct)
				target:AddNewModifier(caster, self, "modifier_travaler_shift_slow", { duration = slow_duration })

				EmitSoundOnLocationWithCaster(point, "Boss_Travaler.Teleport.Land", caster)
			end
		end
	end))
end
