item_pirate_hat_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_pirate_hat_custom"
    end
})

modifier_item_pirate_hat_custom = class({
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
            MODIFIER_PROPERTY_ROSHDEF_BONUS_BASE_ATTACK_TIME_PERCENTAGE,
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
        }
    end,
    GetModifierAttackSpeedBonus_Constant = function(self)
        return self.bonusAttackSpeed
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_pirate_hat_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_pirate_hat_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAttackSpeed = self.ability:GetSpecialValueFor("bonus_attack_speed")
    self.bonusBatPercentage = self.ability:GetSpecialValueFor("bat_decrease_pct") * -1
end

function modifier_item_pirate_hat_custom:GetModifierBonusBaseAttackTimePercentage()
    return self.bonusBatPercentage
end

LinkLuaModifier("modifier_item_pirate_hat_custom", "items/neutral_items/pirate_hat", LUA_MODIFIER_MOTION_NONE, modifier_item_pirate_hat_custom)