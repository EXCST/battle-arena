modifier_boss_as_effect = class({})

function modifier_boss_as_effect:IsHidden()
    return false
end

function modifier_boss_as_effect:GetTexture()
    return "troll_warlord_fervor"
end

function modifier_boss_as_effect:OnTooltip()
    return "Attack Speed: +" .. (15 * self:GetStackCount()) .. " (max 10 stacks)"
end

function modifier_boss_as_effect:IsPurgable()
    return false
end

function modifier_boss_as_effect:IsDebuff()
    return false
end

function modifier_boss_as_effect:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }
end

function modifier_boss_as_effect:GetModifierPreAttack_BonusDamage(params)
    return 0
end

function modifier_boss_as_effect:GetModifierAttackSpeedBonus_Constant(params)
    return 15 * self:GetStackCount()
end
