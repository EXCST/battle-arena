require('items/generic_datadriven_item')

item_eye_of_void = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_eye_of_void"
    end
})

item_eye_of_void_1 = class(item_eye_of_void)
item_eye_of_void_2 = class(item_eye_of_void)
item_eye_of_void_3 = class(item_eye_of_void)

modifier_item_eye_of_void = class({
    IsHidden  = function() 
        return true 
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
	GetAttributes = function() 
        return MODIFIER_ATTRIBUTE_MULTIPLE 
    end,
	DeclareFunctions = function() 
        return 
        {
            MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_ROSHDEF_SPELL_LIFESTEAL
	    
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end
})

function modifier_item_eye_of_void:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_eye_of_void:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_mana = self:GetAbility():GetSpecialValueFor("bonus_mana")
    self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
    self.magic_lifesteal_pct = self:GetAbility():GetSpecialValueFor("magic_lifesteal_pct")
end

function modifier_item_eye_of_void:GetModifierExtraManaBonus()
    return self.bonus_mana
end

function modifier_item_eye_of_void:GetModifierBonusHealth()
	return self.bonus_health
end

function modifier_item_eye_of_void:GetModifierSpellLifestealPercantage()
    return self.magic_lifesteal_pct
end

LinkLuaModifier("modifier_item_eye_of_void", "items/item_eye_of_void", LUA_MODIFIER_MOTION_NONE, modifier_item_eye_of_void)