-- ============================================================
-- BATTLE ARENA — Travaler: Разлом Измерений (фаза 2)
-- Стиль Elder Titan Earth Splitter: поле из 8 разломов,
-- расставленных «шашечкой» (сетка 4x4, клетки одного цвета).
-- Все теллуры сразу (1.2с), взрыв быстрой волной: урон + стан.
-- На месте взрывов остаются трещины-зоны (3с, тик %HP).
-- ============================================================

travaler_rift_wall = travaler_rift_wall or class({})

local ability = travaler_rift_wall

require('lib/ability_kv')
require('creeps/boss/travaler/travaler_helpers')

LinkLuaModifier("modifier_travaler_stun", "creeps/boss/travaler/modifiers/modifier_travaler_stun", LUA_MODIFIER_MOTION_NONE)

local CAST_GESTURE = ACT_DOTA_CAST_ABILITY_2
local BURST_PARTICLE = "particles/units/heroes/hero_elder_titan/elder_titan_earth_splitter.vpcf"
local CRACK_PARTICLE = "particles/units/heroes/hero_doom_bringer/doom_bringer_doom_aura.vpcf"


function ability:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local center = caster:GetAbsOrigin()

	local aoe 			= AbilityKV:Get(self, "aoe")
	local delay 		= AbilityKV:Get(self, "delay")
	local step 			= AbilityKV:Get(self, "step")
	local stun_duration = AbilityKV:Get(self, "stun_duration")
	local grid_step 	= AbilityKV:Get(self, "grid_step")
	local center_offset = AbilityKV:Get(self, "center_offset")

	local crack_radius 	= AbilityKV:Get(self, "crack_radius")
	local crack_dur 	= AbilityKV:Get(self, "crack_duration")
	local crack_tick 	= AbilityKV:Get(self, "crack_tick")
	local crack_pct 	= AbilityKV:Get(self, "crack_pct")

	caster:StartGesture(CAST_GESTURE)

	-- направление: на случайного врага поблизости, иначе случайный угол
	local dir
	local enemy = TravalerHelpers:GetRandomEnemy(caster:GetTeamNumber(), center, 1200)

	if enemy then
		dir = (enemy:GetAbsOrigin() - center)
	else
		dir = RandomVector(1)
	end

	dir.z = 0
	if dir:Length2D() < 0.01 then dir = Vector(1, 0, 0) end
	dir = dir:Normalized()

	-- перпендикуляр (для сетки «шашечкой»)
	local side = Vector(-dir.y, dir.x, 0)

	-- центр поля: в 600 от босса по направлению к врагу
	local field_center = center + dir * center_offset

	-- 8 разломов: сетка 4x4, клетки одного цвета (шахматка)
	local cells = {}

	for gx = 0, 3 do
		for gy = 0, 3 do
			if (gx + gy) % 2 == 0 then
				local off_x = (gx - 1.5) * grid_step
				local off_y = (gy - 1.5) * grid_step

				cells[#cells + 1] = field_center + dir * off_x + side * off_y
			end
		end
	end

	-- теллуры всех разломов сразу
	local telegraphs = {}

	for i = 1, #cells do
		telegraphs[i] = TravalerHelpers:CreateTelegraph(cells[i], aoe)
	end

	caster:EmitSound("Boss_Travaler.RiftWall.Cast")

	-- взрыв быстрой волной от центра поля
	for i = 1, #cells do
		Timers:CreateTimer(delay + (i - 1) * step, TravalerHelpers:SafeTimer(function()
			-- маркер гасим ДО ранних return
			TravalerHelpers:DestroyTelegraph(telegraphs[i])

			if not IsValidEntity(caster) or not caster:IsAlive() then return end

			local pos = cells[i]
			local victims = TravalerHelpers:FindEnemies(caster:GetTeamNumber(), pos, aoe)

			for _, victim in ipairs(victims) do
				if IsValidEntity(victim) then
					TravalerHelpers:DealDamage(self, caster, victim)
					TravalerHelpers:Stun(victim, caster, self, stun_duration)
				end
			end

			local burst = ParticleManager:CreateParticle(BURST_PARTICLE, PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(burst, 0, pos)
			ParticleManager:SetParticleControl(burst, 1, Vector(aoe, 1, 1))
			ParticleManager:ReleaseParticleIndex(burst)

			EmitSoundOnLocationWithCaster(pos, "Boss_Travaler.RiftWall.Explode", caster)

			-- остаточная трещина (зона-тикер)
			TravalerHelpers:CreateZone(caster, self, pos, crack_radius, crack_dur, crack_tick, crack_pct, CRACK_PARTICLE)
		end))
	end
end
