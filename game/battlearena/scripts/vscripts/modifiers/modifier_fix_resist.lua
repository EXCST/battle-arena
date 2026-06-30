modifier_fix_resist = class({})

function modifier_fix_resist:IsHidden()
    return true
end

function modifier_fix_resist:IsPurgeException()
    return false
end    

function modifier_fix_resist:IsPurgable()
    return false
end

function modifier_fix_resist:RemoveOnDeath()
    return false
end

function modifier_fix_resist:OnCreated()
    print("modifier_fix_resist created")
end

function modifier_fix_resist:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DIRECT_MODIFICATION
    }
end

function modifier_fix_resist:GetModifierMagicalResistanceDirectModification()
    local parent = self:GetParent()
    if parent and parent.GetIntellect then
        return -0.1 * parent.GetIntellect(parent) -- ВАЖНО: используем "." и передаём parent как аргумент
    else
        print("[modifier_fix_resist] Error: GetIntellect is not available on parent")
        return 0
    end
end
