-- creeps/duel_bosses/skull_warrior/skull_wave.lua
-- «Волна Пустоши» (порт elite_040): зарядка → ударная волна-конус
-- (15% макс.HP + стан 1.4с) → вращающийся рывок (12%/хит, hit-once, нокбек).

require('lib/duel_bosses/boss_cast')
require('lib/duel_bosses/boss_aim')
require('lib/duel_bosses/boss_motion')
require('lib/duel_bosses/boss_warning')
require('lib/duel_bosses/boss_damage')

local CAST_POINT = 1.57
local CAST_DURATION = 3.2
local SEARCH_RANGE = 1000

local WAVE_LENGTH = 1200
local WAVE_HALF_ANGLE = 50
local WAVE_DAMAGE_PCT = 15
local WAVE_STUN = 1.4

local SPIN_RADIUS = 500
local SPIN_MOVE_DISTANCE = 700
local SPIN_MOVE_DURATION = 0.96
local SPIN_DAMAGE_PCT = 12
local SPIN_KNOCKBACK_DIST = 280
local SPIN_KNOCKBACK_DUR = 0.3
local SPIN_KNOCKBACK_HEIGHT = 100

local WAVE_PARTICLE = "particles/unit/elite_032.vpcf"
local SPIN_PARTICLE = "particles/unit/elite_040.vpcf"

ba_duel_skull_wave = ba_duel_skull_wave or class({})

function ba_duel_skull_wave:OnAbilityPhaseStart()
	DuelBossCast:OnPhaseStart(self, { castPoint = CAST_POINT })

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return true end

	local origin = caster:GetAbsOrigin()
	local forward = caster:GetForwardVector()
	forward.z = 0
	if forward:Length2D() < 0.1 then forward = Vector(1, 0, 0) end
	forward = forward:Normalized()

	-- растущий линейный телеграф по направлению взгляда (ре-айм за боссом)
	DuelBossWarning:Line(caster, self, origin, origin + forward * 500, CAST_POINT, {
		startWidth = 200,
		endWidth = 700,
		type = 1,
		getDirection = function()
			local f = caster:GetForwardVector()
			f.z = 0
			return f
		end,
	})

	Timers:CreateTimer(0.1, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
		local target = DuelBossAim:GetNearestEnemy(caster, SEARCH_RANGE)
		if target then
			DuelBossAim:LockTarget(caster, target, 0.9)
		end
		return nil
	end)

	return true
end

function ba_duel_skull_wave:OnAbilityPhaseInterrupted()
	DuelBossCast:OnPhaseInterrupted(self)
end

function ba_duel_skull_wave:OnSpellStart()
	DuelBossCast:OnSpellStart(self, { castDuration = CAST_DURATION })

	local caster = self:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	local origin = caster:GetAbsOrigin()
	local forward = caster:GetForwardVector()
	forward.z = 0
	if forward:Length2D() < 0.1 then forward = Vector(1, 0, 0) end
	forward = forward:Normalized()

	caster:EmitSound("Hero_Magnataur.ShockWave.Cast")
	caster:EmitSound("Hero_Magnataur.ShockWave.Particle")

	-- частица-волна
	local pfx = ParticleManager:CreateParticle(WAVE_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControlTransformForward(pfx, 0, origin + forward * 50, forward)
	ParticleManager:SetParticleControl(pfx, 11, Vector(WAVE_LENGTH, 0, 0))
	Timers:CreateTimer(2, function()
		ParticleManager:DestroyParticle(pfx, false)
		ParticleManager:ReleaseParticleIndex(pfx)
		return nil
	end)

	-- урон+стан волной (конус ±50°)
	local hitEnemies = {}
	local minDot = math.cos(math.rad(WAVE_HALF_ANGLE))
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(), origin, nil, WAVE_LENGTH,
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0, FIND_ANY_ORDER, false
	)
	for _, enemy in ipairs(enemies) do
		if IsValidEntity(enemy) and enemy:IsAlive() and not enemy:IsCourier() then
			local delta = enemy:GetAbsOrigin() - origin
			local dist = delta:Length2D()
			if dist > 0.01 and dist <= WAVE_LENGTH then
				local dir = Vector(delta.x / dist, delta.y / dist, 0)
				local dot = forward.x * dir.x + forward.y * dir.y
				if dot >= minDot then
					hitEnemies[#hitEnemies + 1] = enemy
					DuelBossDamage:Deal(self, caster, enemy, WAVE_DAMAGE_PCT, 0)
					DuelBossDamage:Stun(enemy, caster, self, WAVE_STUN)
				end
			end
		end
	end

	ScreenShake(origin, 20, 20, 0.3, 2500, 0, true)

	-- направление спина: к случайному задетому, иначе по forward
	local spinDir = forward
	if #hitEnemies > 0 then
		local t = hitEnemies[RandomInt(1, #hitEnemies)]
		if IsValidEntity(t) and t:IsAlive() then
			local d = t:GetAbsOrigin() - origin
			d.z = 0
			if d:Length2D() > 0.01 then spinDir = d:Normalized() end
		end
	end
	self.spin_direction = spinDir

	Timers:CreateTimer(CAST_DURATION - 1, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
		self:StartSpinAttack(caster)
		return nil
	end)
end

function ba_duel_skull_wave:StartSpinAttack(caster)
	caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_2, 1)
	self.spin_hit = {}
	Timers:CreateTimer(1.0, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
		self:BeginSpinAdvance(caster)
		return nil
	end)
end

function ba_duel_skull_wave:BeginSpinAdvance(caster)
	self:PlaySpinEffect(caster)
	caster:EmitSound("Hero_Mars.Shield.Cast")

	local origin = caster:GetAbsOrigin()
	local dir = self.spin_direction or caster:GetForwardVector()
	dir.z = 0
	if dir:Length2D() < 0.1 then dir = Vector(1, 0, 0) end
	dir = dir:Normalized()
	caster:SetForwardVector(dir)

	local endPos = origin + dir * SPIN_MOVE_DISTANCE
	ScreenShake(origin, 10, 10, 0.8, 1500, 0, true)

	DuelBossMotion:Mover(caster, endPos, SPIN_MOVE_DURATION, function(u, pos)
		if u ~= caster then return false end

		local victims = FindUnitsInRadius(
			caster:GetTeamNumber(), pos, nil, SPIN_RADIUS * 0.9,
			DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			0, FIND_ANY_ORDER, false
		)
		for _, v in ipairs(victims) do
			if IsValidEntity(v) and v:IsAlive() and not v:IsCourier() and not self.spin_hit[v:entindex()] then
				self.spin_hit[v:entindex()] = true
				caster:EmitSound("Hero_Mars.Spear.Root")
				DuelBossDamage:Deal(self, caster, v, SPIN_DAMAGE_PCT, 0)
				DuelBossMotion:KnockBack(v, pos, SPIN_KNOCKBACK_DIST, SPIN_KNOCKBACK_DUR, SPIN_KNOCKBACK_HEIGHT, 0, self)
			end
		end
		return false
	end)
end

function ba_duel_skull_wave:PlaySpinEffect(caster)
	local function spawn(offset)
		local p = ParticleManager:CreateParticle(SPIN_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(p, 0, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(p, 1, Vector(SPIN_RADIUS, SPIN_RADIUS, SPIN_RADIUS))
		Timers:CreateTimer(3.17, function()
			ParticleManager:DestroyParticle(p, false)
			ParticleManager:ReleaseParticleIndex(p)
			return nil
		end)
	end
	spawn(0)
	Timers:CreateTimer(0.5, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return nil end
		spawn(0)
		return nil
	end)
end