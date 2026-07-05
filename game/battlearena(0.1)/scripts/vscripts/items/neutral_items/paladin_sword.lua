item_paladin_sword_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_paladin_sword_custom"
    end
})

modifier_item_paladin_sword_custom = class({
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
            MODIFIER_PROPERTY_ROSHDEF_LIFESTEAL,
            MODIFIER_PROPERTY_ROSHDEF_SPELL_LIFESTEAL,
            MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_HEAL_RECEIVED_PERCENTAGE
        }
    end,
    GetModifierPreAttack_BonusDamage = function(self)
        return self.bonusAttackDamage
    end,
    GetModifierLifestealPercantage = function(self)
        return self.bonusLifesteal
    end,
    GetModifierSpellLifestealPercantage = function(self)
        return self.bonusSpellLifesteal
    end,
    GetModifierLifestealRegenAmplify_Percentage = function(self)
        return self.bonusLifestealAmp
    end,
    GetModifierSpellLifestealRegenAmplify_Percentage = function(self)
        return self.bonusLifestealAmp
    end,
    GetModifierHPRegenAmplify_Percentage = function(self)
        return self.bonusLifestealAmp
    end,
    GetModifierHealReceived_Percentage = function(self)
        return self.bonusLifestealAmp
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_paladin_sword_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_paladin_sword_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusLifesteal = self.ability:GetSpecialValueFor("bonus_lifesteal")
    self.bonusSpellLifesteal = self.ability:GetSpecialValueFor("bonus_spell_lifesteal")
    self.bonusAttackDamage = self.ability:GetSpecialValueFor("bonus_damage")
    self.bonusLifestealAmp = self.ability:GetSpecialValueFor("bonus_amp")
end

LinkLuaModifier("modifier_item_paladin_sword_custom", "items/neutral_items/paladin_sword", LUA_MODIFIER_MOTION_NONE, modifier_item_paladin_sword_custom)