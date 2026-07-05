item_vampire_fangs_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_vampire_fangs_custom"
    end
})

modifier_item_vampire_fangs_custom = class({
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
            MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_LIFESTEAL,
            MODIFIER_PROPERTY_ROSHDEF_SPELL_LIFESTEAL
        }
    end,
    GetModifierPreAttack_BonusDamage = function(self)
        return self.bonusAttackDamage
    end,
    GetModifierSpellAmplify_Percentage = function(self)
        return self.bonusSpellAmplification
    end,
    GetModifierLifestealPercantage = function(self)
        return self.bonusLifesteal
    end,
    GetModifierSpellLifestealPercantage = function(self)
        return self.bonusSpellLifesteal
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_vampire_fangs_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_vampire_fangs_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusLifesteal = self.ability:GetSpecialValueFor("attack_lifesteal")
    self.bonusSpellLifesteal = self.ability:GetSpecialValueFor("spell_lifesteal")
    self.bonusAttackDamage = self.ability:GetSpecialValueFor("bonus_damage")
    self.bonusSpellAmplification = self.ability:GetSpecialValueFor("bonus_spell_amp")
end

LinkLuaModifier("modifier_item_vampire_fangs_custom", "items/neutral_items/vampire_fangs", LUA_MODIFIER_MOTION_NONE, modifier_item_vampire_fangs_custom)