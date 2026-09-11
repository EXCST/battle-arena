modifier_possessed_chains_pull = modifier_possessed_chains_pull or class({})
local mod = modifier_possessed_chains_pull


function mod:IsHidden() return false end
function mod:IsPurgable() return false end
function mod:IsDebuff() return true end
function mod:DestroyOnExpire() return true end


function mod:OnCreated(kv)
	if not IsServer() then return end

	self.point = Vector(tonumber(kv.point_x), tonumber(kv.point_y), tonumber(kv.point_z))
	self.speed = 700

	if not self:ApplyHorizontalMotionController() then
		self:Destroy()
	end
end


function mod:UpdateHorizontalMotion(me, dt)
	if not IsServer() then return end

	local parent = self:GetParent()

	if not IsValidEntity(parent) or not parent:IsAlive() then
		self:Destroy()
		return
	end

	local parent_pos = parent:GetAbsOrigin()
	local to_point = self.point - parent_pos

	if to_point:Length2D() > 100 then
		local new_pos = parent_pos + to_point:Normalized() * (self.speed * dt)
		parent:SetAbsOrigin(new_pos)
		FindClearSpaceForUnit(parent, new_pos, false)
	else
		self:Destroy()
	end
end


function mod:OnHorizontalMotionInterrupted()
	self:Destroy()
end


function mod:OnDestroy()
	if not IsServer() then return end

	self:GetParent():InterruptMotionControllers(true)
end


function mod:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
	}
end
