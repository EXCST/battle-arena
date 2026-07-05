item_blood_dagger = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_blood_dagger"
    end
})

modifier_item_blood_dagger = class({
    IsHidden = function() 
        return true 
    end,
    IsDebuff = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS
        }
    end,
    GetModifierPreAttack_BonusDamage = function(self)
        return self.bonusAttackDamage
    end,
    GetModifierAttackSpeedBonus_Constant = function(self)
        return self.bonusAttackSpeed
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_blood_dagger:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_blood_dagger:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAttackSpeed = self.ability:GetSpecialValueFor("bonus_attack_speed") + self.ability:GetSpecialValueFor("as_increase")
    self.bonusAttackDamage = self.ability:GetSpecialValueFor("bonus_damage")
    self.bonusHealthDecrease = self.ability:GetSpecialValueFor("hp_decrease") * -1
end

function modifier_item_blood_dagger:GetModifierBonusHealth()
    return self.bonusHealthDecrease
end

LinkLuaModifier("modifier_item_blood_dagger", "items/neutral_items/blood_dagger", LUA_MODIFIER_MOTION_NONE, modifier_item_blood_dagger)