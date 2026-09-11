-- ============================================================
-- BATTLE ARENA — Travaler: полёт жертвы по дуге (Хватка Пустоты)
-- MOTION_BOTH: жертва летит от босса по дуге.
-- OnDestroy: приземление — урон + стан; если в точке приземления
-- другой герой — оба получают доп. урон (столкновение).
-- ============================================================

modifier_travaler_throw = modifier_travaler_throw or class({})

local mod = modifier_travaler_throw

require('creeps/boss/travaler/travaler_helpers')


function mod:IsHidden() 		return true end
function mod:IsPurgable() 		return false end
function mod:DestroyOnExpire() 	return true end


function mod:OnCreated(kv)
	if not IsServer() then return end

	self.start_pos = self:GetParent():GetAbsOrigin()
	self.end_pos = Vector(tonumber(kv.end_x), tonumber(kv.end_y), tonumber(kv.end_z))
	self.duration = tonumber(kv.duration) or 1.2
	self.arc = tonumber(kv.arc) or 400
	self.damage_pct = tonumber(kv.damage_pct) or 10
	self.stun = tonumber(kv.stun) or 1.0
	self.collision_pct = tonumber(kv.collision_pct) or 6
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

	parent:SetAbsOrigin(self.start_pos + (self.end_pos - self.start_pos) * pct)

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

	local target = self:GetParent()

	if not IsValidEntity(target) then return end

	target:InterruptMotionControllers(true)

	local caster = self:GetCaster()
	local pos = target:GetAbsOrigin()

	local p = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(p, 0, pos)
	ParticleManager:SetParticleControl(p, 1, Vector(250, 1, 1))
	ParticleManager:ReleaseParticleIndex(p)

	EmitSoundOnLocationWithCaster(pos, "Boss_Travaler.Teleport.Land", caster)

	if not IsValidEntity(caster) then return end

	-- урон + стан приземления
	TravalerHelpers:DealDamageCustom(nil, caster, target, 0, self.damage_pct)
	TravalerHelpers:Stun(target, caster, nil, self.stun)

	-- столкновение: другой герой в точке приземления — оба получают урон
	local others = TravalerHelpers:FindEnemies(caster:GetTeamNumber(), pos, 250)

	for _, other in ipairs(others) do
		if IsValidEntity(other) and other ~= target then
			TravalerHelpers:DealDamageCustom(nil, caster, other, 0, self.collision_pct)
			TravalerHelpers:DealDamageCustom(nil, caster, target, 0, self.collision_pct)
		end
	end
end
