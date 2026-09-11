-- ============================================================
-- BATTLE ARENA — Travaler: отброс от точки (удар Схлопывания)
-- MOTION_HORIZONTAL, направление от центра удара.
-- ============================================================

modifier_travaler_knockback = modifier_travaler_knockback or class({})

local mod = modifier_travaler_knockback


function mod:IsHidden() 		return true end
function mod:IsPurgable() 		return false end
function mod:DestroyOnExpire() 	return true end


function mod:OnCreated(kv)
	if not IsServer() then return end

	local vals = {}
	for i in kv.point:gmatch("%S+") do
		table.insert(vals, i)
	end

	self.point = Vector(tonumber(vals[1]), tonumber(vals[2]), tonumber(vals[3]))
	self.duration = tonumber(kv.dur) or 0.4
	self.radius = tonumber(kv.radius) or 500
	self.step = self.radius / self.duration
	self.target = self:GetParent()
	self.dir = (self.target:GetAbsOrigin() - self.point):Normalized()

	if not self:ApplyHorizontalMotionController() then
		self:Destroy()
	end
end


function mod:UpdateHorizontalMotion(me, dt)
	if not IsServer() then return end

	if self and self:GetParent() and self:GetParent():IsAlive() then
		local step = self.dir * (self.step * dt)
		local origin = self:GetParent():GetAbsOrigin()
		self:GetParent():SetAbsOrigin(origin + step)
	else
		if self and self:GetParent() then
			self:GetParent():InterruptMotionControllers(true)
		end
	end
end


function mod:OnHorizontalMotionInterrupted()
	if not IsServer() then return end
	self:Destroy()
end


function mod:OnDestroy()
	if not IsServer() then return end

	if self and self.target and IsValidEntity(self.target) then
		self.target:InterruptMotionControllers(true)
	end
end
