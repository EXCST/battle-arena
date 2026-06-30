-- Modifier for maim effect from Demon's Fury
-- Reduces target's attack speed and movement speed

modifier_item_demons_fury_maim = class({})

function modifier_item_demons_fury_maim:IsHidden() return false end
function modifier_item_demons_fury_maim:IsPurgable() return false end
function modifier_item_demons_fury_maim:IsDebuff() return true end

function modifier_item_demons_fury_maim:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end

function modifier_item_demons_fury_maim:OnCreated(kv)
    if IsServer() then
        local ability = self:GetAbility()
        if ability then
            self.movementSlow = ability:GetSpecialValueFor("maim_decrease_ms")
            self.attackSpeedSlow = ability:GetSpecialValueFor("maim_attackspeed")
        end
    end
end

function modifier_item_demons_fury_maim:GetModifierPercentageMoveSpeedBonus()
    return -self.movementSlow
end

function modifier_item_demons_fury_maim:GetModifierAttackSpeedBonus_Constant()
    return -self.attackSpeedSlow
end
