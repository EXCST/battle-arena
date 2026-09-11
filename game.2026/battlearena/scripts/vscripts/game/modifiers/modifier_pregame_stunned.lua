modifier_pregame_stunned = class({})

function modifier_pregame_stunned:IsHidden() return false end
function modifier_pregame_stunned:IsDebuff() return true end
function modifier_pregame_stunned:IsPurgable() return false end
function modifier_pregame_stunned:RemoveOnExpire() return false end

function modifier_pregame_stunned:OnCreated()
	print("[STUN] modifier_pregame_stunned created on: " .. self:GetParent():GetUnitName())
end

function modifier_pregame_stunned:OnDestroy()
	print("[STUN] modifier_pregame_stunned removed from: " .. self:GetParent():GetUnitName())
end

function modifier_pregame_stunned:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end
