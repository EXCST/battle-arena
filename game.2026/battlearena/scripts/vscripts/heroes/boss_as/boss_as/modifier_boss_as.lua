modifier_boss_as = class({})

function modifier_boss_as:IsHidden()
    return true
end

function modifier_boss_as:IsPurgable()
    return false
end

function modifier_boss_as:DeclareFunctions()
    return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_boss_as:OnAttackLanded(params)
    if not IsServer() then return end
    if params.attacker ~= self:GetParent() then return end
    local parent = self:GetParent()
    if parent:PassivesDisabled() then return end

    local target = params.target
    if not target or target:IsNull() then return end

    if self.target ~= target then
        self.target = target
        self.stacks = 1
    else
        self.stacks = math.min((self.stacks or 1) + 1, 10)
    end

    parent:AddNewModifier(parent, nil, "modifier_boss_as_effect", { duration = 5 })
    parent:SetModifierStackCount("modifier_boss_as_effect", parent, self.stacks)
end
