modifier_dark_edge_break = modifier_dark_edge_break or class({})

function modifier_dark_edge_break:IsHidden() return false end
function modifier_dark_edge_break:IsPurgable() return false end
function modifier_dark_edge_break:IsPurgeException() return true end
function modifier_dark_edge_break:RemoveOnDeath() return false end
function modifier_dark_edge_break:DestroyOnExpire() return true end
function modifier_dark_edge_break:GetEffectName() return "particles/dark_edge/dark_edge.vpcf" end

function modifier_dark_edge_break:OnCreated()
	local ability = self:GetAbility()
	if not IsValidEntity(ability) then self.move_speed_cap = 200 return end
	self.move_speed_cap = ability:GetSpecialValueFor("move_speed_cap")
end


function modifier_dark_edge_break:CheckState()
	return {
		[MODIFIER_STATE_PASSIVES_DISABLED] = true,
	}
end

function modifier_dark_edge_break:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MAX, -- GetModifierMoveSpeed_AbsoluteMax
	}
end


function modifier_dark_edge_break:GetModifierMoveSpeed_AbsoluteMax()
	return self.move_speed_cap
end
