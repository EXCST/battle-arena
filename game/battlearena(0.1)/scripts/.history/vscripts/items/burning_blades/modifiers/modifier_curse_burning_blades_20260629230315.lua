modifier_curse_burning_blades = modifier_curse_burning_blades or class({})
local mod = modifier_curse_burning_blades

function mod:IsHidden()        return false end
function mod:IsPurgable()      return true end
function mod:DestroyOnExpire() return true end
function mod:IsPurgeException()return true end

function mod:OnCreated()
    local ability = self:GetAbility()
    if not ability then return end
    -- Read slow and attack speed debuff values from the ability
    self.curseSlow      = ability:GetSpecialValueFor("curse_slow")
    self.curseAttackspeed = ability:GetSpecialValueFor("curse_attackspeed")
end

mod.OnRefresh = mod.OnCreated

function mod:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }
end

function mod:GetModifierMoveSpeedBonus_Percentage()
    return self.curseSlow
end

function mod:GetModifierAttackSpeedBonus_Constant()
    return self.curseAttackspeed
end
