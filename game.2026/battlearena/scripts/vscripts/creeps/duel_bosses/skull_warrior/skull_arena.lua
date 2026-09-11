-- creeps/duel_bosses/skull_warrior/skull_arena.lua
-- «Арена Пустоши» (порт elite_042): зона r850 на 15с — стан 1.5с по входу,
-- враги НЕ могут выйти из круга (boundary), босс получает +100 AS.
-- КД 15с в KV = «не чаще раза в 15с» (анти-повтор без canCast).

require('lib/duel_bosses/boss_cast')
require('lib/duel_bosses/boss_warning')
require('lib/duel_bosses/boss_damage')
require('lib/duel_bosses/modifiers/modifier_duel_boss_skull_arena')

local CAST_POINT = 1.3
local CAST_DURATION = 1.3
local ZONE_RADIUS = 850
local ZONE_DURATION = 15
local STUN_DURATION = 1.5
local AS_BUFF_DURATION = 15

local ZONE_PARTICLE = "particles/unit/elite_042.vpcf"

ba_duel_skull_arena = ba_duel_skull_arena or class({})

function ba_duel_skull_arena:OnAbilityPhaseStart()
	DuelBossCast:OnPhaseStart(self, { castPoint = CAST_POINT })
	return true
end

function ba_duel_skull_arena:OnAbilityPhaseInterrupted()
	DuelBossCast:OnPhaseInterrupted(self)
end

function ba_duel_skull_arena:OnSpellStart()
	DuelBossCast:OnSpellStart(self, { castDuration = CAST_DURATION })

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	local center = caster:GetAbsOrigin()
	center.z = GetGroundPosition(center, caster).z

	-- само-бафф +100 AS на время зоны
	caster:AddNewModifier(caster, self, "modifier_duel_boss_skull_arena_buff", { duration = AS_BUFF_DURATION })

	-- визуал зоны (zone-мод гасит его при смерти кастера; таймер = страховка)
	local pfx = ParticleManager:CreateParticle(ZONE_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(pfx, 0, center)
	ParticleManager:SetParticleControl(pfx, 1, Vector(ZONE_RADIUS - 50, ZONE_RADIUS, ZONE_RADIUS))
	ParticleManager:SetParticleControl(pfx, 2, center)
	Timers:CreateTimer(ZONE_DURATION, function()
		ParticleManager:DestroyParticle(pfx, false)
		ParticleManager:ReleaseParticleIndex(pfx)
		return nil
	end)

	EmitSoundOnLocationWithCaster(center, "Hero_Mars.ArenaOfBlood.Start", caster)

	-- стан по входу
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(), center, nil, ZONE_RADIUS,
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0, FIND_ANY_ORDER, false
	)
	for _, enemy in ipairs(enemies) do
		if IsValidEntity(enemy) and enemy:IsAlive() and not enemy:IsCourier() then
			DuelBossDamage:Stun(enemy, caster, self, STUN_DURATION)
		end
	end

	-- thinker-аура «не выпускает из круга»; частицу зоны гасит zone-мод
	CreateModifierThinker(
		caster,
		self,
		"modifier_duel_boss_skull_arena_zone",
		{
			duration = ZONE_DURATION,
			radius = ZONE_RADIUS,
			center_x = center.x,
			center_y = center.y,
			center_z = center.z,
			pfx = pfx,
		},
		center,
		caster:GetTeamNumber(),
		false
	)
end