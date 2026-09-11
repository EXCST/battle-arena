-- ============================================================
-- BATTLE ARENA — Travaler: прыжок по дуге на цель
-- MOTION_BOTH: горизонталь — линейная, вертикаль — парабола.
-- OnDestroy: урон + стан в точке приземления.
-- ============================================================

modifier_travaler_leap = modifier_travaler_leap or class({})

local mod = modifier_travaler_leap

require('creeps/boss/travaler/travaler_helpers')


function mod:IsHidden() 		return true end
function mod:IsPurgable() 		return false end
function mod:DestroyOnExpire() 	return true end


function mod:OnCreated(kv)
	if not IsServer() then return end

	self.start_pos = self:GetParent():GetAbsOrigin()
	self.target_pos = Vector(tonumber(kv.target_x), tonumber(kv.target_y), tonumber(kv.target_z))
	self.duration = tonumber(kv.duration) or 0.7
	self.arc = tonumber(kv.arc) or 300
	self.aoe = tonumber(kv.aoe) or 300
	self.damage_pct = tonumber(kv.damage_pct) or 8
	self.stun = tonumber(kv.stun) or 0.75
	self.elapsed = 0

	if not self:ApplyHorizontalMotionController() then self:Destroy() return end
	if not self:ApplyVerticalMotionController() then self:Destroy() return end
end


function mod:UpdateHorizontalMotion(me, dt)
	if not IsServer() then return end

	self.elapsed = self.elapsed + dt

	local pct = math.min(1, self.elapsed / self.duration)
	local parent = self:GetParent()

	if not IsValidEntity(parent) then return end

	parent:SetAbsOrigin(self.start_pos + (self.target_pos - self.start_pos) * pct)

	if pct >= 1 then
		parent:InterruptMotionControllers(true)
		self:Destroy()
	end
end


function mod:UpdateVerticalMotion(me, dt)
	if not IsServer() then return end

	local parent = self:GetParent()

	if not IsValidEntity(parent) then return end

	local pct = math.min(1, self.elapsed / self.duration)
	local arc = self.arc * 2 * pct * (1 - pct)
	local pos = parent:GetAbsOrigin()

	parent:SetAbsOrigin(Vector(pos.x, pos.y, pos.z + arc))
end


function mod:OnHorizontalMotionInterrupted()
	self:Destroy()
end


function mod:OnDestroy()
	if not IsServer() then return end

	local caster = self:GetParent()

	if not IsValidEntity(caster) then return end

	caster:InterruptMotionControllers(true)

	local pos = caster:GetAbsOrigin()

	local p = ParticleManager:CreateParticle("particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_c.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(p, 0, pos)
	ParticleManager:SetParticleControl(p, 1, Vector(self.aoe, 0, 0))
	ParticleManager:ReleaseParticleIndex(p)

	caster:EmitSound("Boss_Travaler.Leap.Land")

	local victims = TravalerHelpers:FindEnemies(caster:GetTeamNumber(), pos, self.aoe)

	for _, enemy in ipairs(victims) do
		if IsValidEntity(enemy) then
			TravalerHelpers:DealDamageCustom(nil, caster, enemy, 0, self.damage_pct)
			TravalerHelpers:Stun(enemy, caster, nil, self.stun)
		end
	end
end
