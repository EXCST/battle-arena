require('items/generic_datadriven_item')

item_octarine_custom = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_octarine_custom"
	end
})

item_octarine_custom_1 = class(item_octarine_custom)
item_octarine_custom_2 = class(item_octarine_custom)
item_octarine_custom_3 = class(item_octarine_custom)

item_rememberme_1 = class(item_octarine_custom)
item_rememberme_2 = class(item_octarine_custom)
item_rememberme_3 = class(item_octarine_custom)

item_chalice_of_avarice_1 = class(item_octarine_custom)
item_chalice_of_avarice_2 = class(item_octarine_custom)
item_chalice_of_avarice_3 = class(item_octarine_custom)

modifier_item_octarine_custom = class({
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
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_ROSHDEF_COOLDOWN_REDUCTION_STACKING_UNIQUE
	    }
    end
})

function modifier_item_octarine_custom:OnCreated()
    self.ability = self:GetAbility()
	self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_octarine_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
	self.bonus_int = self.ability:GetSpecialValueFor("bonus_int")
    self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
    self.cooldown_reduction = self.ability:GetSpecialValueFor("cooldown_reduction")
end

function modifier_item_octarine_custom:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_octarine_custom:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_octarine_custom:GetModifierBonusStats_Intellect()
    return self.bonus_allstats + self.bonus_int
end

function modifier_item_octarine_custom:GetModifierPercentageCooldownStackingUnique()
	return self.cooldown_reduction
end

LinkLuaModifier("modifier_item_octarine_custom", "items/item_octarine_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_octarine_custom)