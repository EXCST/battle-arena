item_elven_tunic_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_elven_tunic_custom"
    end
})

modifier_item_elven_tunic_custom = class({
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
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
            MODIFIER_PROPERTY_ROSHDEF_EVASION_CONSTANT,
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
        }
    end,
    GetModifierBonusStats_Agility = function(self)
        return self.bonusAgility
    end,
    GetModifierAttackSpeedBonus_Constant = function(self)
        return self.bonusAttackSpeed
    end,
    GetModifierEvasion_Constant = function(self)
        return self.bonusEvasion
    end,
    GetModifierMoveSpeedBonus_Percentage = function(self)
        return self.bonusMovespeedPct
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_elven_tunic_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_elven_tunic_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAgility = self.ability:GetSpecialValueFor("bonus_agility")
    self.bonusAttackSpeed = self.ability:GetSpecialValueFor("bonus_attack_speed")
    self.bonusEvasion = self.ability:GetSpecialValueFor("evasion")
    self.bonusMovespeedPct = self.ability:GetSpecialValueFor("movement")
end

LinkLuaModifier("modifier_item_elven_tunic_custom", "items/neutral_items/elven_tunic", LUA_MODIFIER_MOTION_NONE, modifier_item_elven_tunic_custom)