-- Modifier for maim effect from Demon's Fury
-- Reduces target's attack speed and movement speed

modifier_item_demons_fury_maim = class({})

function modifier_item_demons_fury_maim:IsHidden() return false end
function modifier_item_demons_fury_maim:IsPurgable() return true end
function modifier_item_demons_fury_maim:IsDebuff() return true end
function modifier_item_demons_fury_maim:DestroyOnExpire() return true end

function modifier_item_demons_fury_maim:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end

function modifier_item_demons_fury_maim:OnCreated(kv)
    self:OnRefresh(kv)
end

function modifier_item_demons_fury_maim:OnRefresh(kv)
    local ability = self:GetAbility()
    if ability then
        self.movementSlow = ability:GetSpecialValueFor("curse_slow")
        self.attackSpeedSlow = ability:GetSpecialValueFor("curse_attackspeed")
    else
        self.movementSlow = -30
        self.attackSpeedSlow = -140
    end
end

function modifier_item_demons_fury_maim:GetModifierMoveSpeedBonus_Percentage()
    return self.movementSlow or -30
end

function modifier_item_demons_fury_maim:GetModifierAttackSpeedBonus_Constant()
    return self.attackSpeedSlow or -140
end
