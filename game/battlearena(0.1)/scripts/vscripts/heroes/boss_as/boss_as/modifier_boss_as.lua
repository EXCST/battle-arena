modifier_boss_as = class({})

-----------------------------------------------------------------------------
function modifier_boss_as:IsHidden()
    return true
end

--------------------------------------------------------------------------------
function modifier_boss_as:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
function modifier_boss_as:OnCreated(kv)
    self.duration = self:GetAbility():GetSpecialValueFor("duration")
    self.target = nil
end

-------------------------------------------------------------------------------
function modifier_boss_as:OnRefresh(kv)
    self.duration = self:GetAbility():GetSpecialValueFor("duration")
end

-------------------------------------------------------------------------------
function modifier_boss_as:DeclareFunctions()
    local funcs = {
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
    }
    return funcs
end

-------------------------------------------------------------------------------
function modifier_boss_as:GetModifierProcAttack_Feedback(params)
	local parent = self:GetParent()
    if not parent or parent:PassivesDisabled() then return end
    if not IsServer() then return end
	
	if parent:IsIllusion() then return end

	parent:AddNewModifier(parent, self:GetAbility(), "modifier_boss_as_effect", { duration = self.duration })
	local stack_count = params.attacker:GetModifierStackCount("modifier_boss_as_effect", parent)
	
	if self.target == params.target then
		self:SetStacksCustom(stack_count + 1)
	else
		self:SetStacksCustom(1)
	end
	self.target = params.target
end

-------------------------------------------------------------------------------
function modifier_boss_as:SetStacksCustom(value)
    local attacker = self:GetParent()
    attacker:SetModifierStackCount("modifier_boss_as_effect", attacker, value)
end
