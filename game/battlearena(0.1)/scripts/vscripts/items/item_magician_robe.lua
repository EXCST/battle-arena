require('items/generic_datadriven_item')

item_magician_robe = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_magician_robe"
    end
})

item_magician_robe_1 = class(item_magician_robe)
item_magician_robe_2 = class(item_magician_robe)
item_magician_robe_3 = class(item_magician_robe)

modifier_item_magician_robe = class({
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
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_ROSHDEF_SPELL_LIFESTEAL
	    
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end
})

function modifier_item_magician_robe:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_magician_robe:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_int = self:GetAbility():GetSpecialValueFor("bonus_int")
    self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
    self.magic_lifesteal_pct = self:GetAbility():GetSpecialValueFor("magic_lifesteal_pct")
end

function modifier_item_magician_robe:GetModifierBonusStats_Intellect()
    return self.bonus_int
end

function modifier_item_magician_robe:GetModifierBonusHealth()
	return self.bonus_health
end

function modifier_item_magician_robe:GetModifierSpellLifestealPercantage()
    return self.magic_lifesteal_pct
end

LinkLuaModifier("modifier_item_magician_robe", "items/item_magician_robe", LUA_MODIFIER_MOTION_NONE, modifier_item_magician_robe)