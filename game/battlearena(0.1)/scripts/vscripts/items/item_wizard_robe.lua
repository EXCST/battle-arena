require('items/generic_datadriven_item')

item_wizard_robe = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_wizard_robe"
    end
})

modifier_item_wizard_robe = class({
	IsHidden = function() 
        return true 
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
	DeclareFunctions  = function() 
        return 
        {
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
            MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_SPELL_LIFESTEAL,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
	    
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end
})

function modifier_item_wizard_robe:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_wizard_robe:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_int = self.ability:GetSpecialValueFor("bonus_int")
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.bonus_mana = self.ability:GetSpecialValueFor("bonus_mana")
    self.bonus_mp_regen = self.ability:GetSpecialValueFor("bonus_mp_regen")
    self.magic_amplify_pct = self.ability:GetSpecialValueFor("magic_amplify_pct")
    self.magic_lifesteal_pct = self.ability:GetSpecialValueFor("magic_lifesteal_pct")
end

function modifier_item_wizard_robe:GetModifierBonusStats_Intellect()
    return self.bonus_int
end

function modifier_item_wizard_robe:GetModifierConstantManaRegen()
    return self.bonus_mp_regen
end

function modifier_item_wizard_robe:GetModifierBonusHealth()
    return self.bonus_health
end

function modifier_item_wizard_robe:GetModifierExtraManaBonus()
    return self.bonus_mana
end

function modifier_item_wizard_robe:GetModifierSpellAmplify_Percentage()
    return self.magic_amplify_pct
end

function modifier_item_wizard_robe:GetModifierSpellLifestealPercantage()
    return self.magic_lifesteal_pct
end

LinkLuaModifier("modifier_item_wizard_robe", "items/item_wizard_robe", LUA_MODIFIER_MOTION_NONE, modifier_item_wizard_robe)
