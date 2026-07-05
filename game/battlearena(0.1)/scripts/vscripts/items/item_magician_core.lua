require('items/generic_datadriven_item')

item_magician_core = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_magician_core"
	end
})

item_magician_core_1 = class(item_magician_core)
item_magician_core_2 = class(item_magician_core)
item_magician_core_3 = class(item_magician_core)

modifier_item_magician_core = class({
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
			MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
			MODIFIER_PROPERTY_ROSHDEF_COOLDOWN_REDUCTION_STACKING_UNIQUE
	    
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end
})

function modifier_item_magician_core:OnCreated()
    self.ability = self:GetAbility()
	self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_magician_core:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
	self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.bonus_mana = self.ability:GetSpecialValueFor("bonus_mana")
    self.cooldown_reduction = self.ability:GetSpecialValueFor("cooldown_reduction")
end

function modifier_item_magician_core:GetModifierExtraManaBonus()
	if(self.parent:IsRealHero() == true) then
		return self.bonus_mana
	end
	return 0
end

function modifier_item_magician_core:GetModifierExtraManaBonus()
	if(self.parent:IsRealHero() == true) then
		return 0
	end
	return self.bonus_mana
end

function modifier_item_magician_core:GetModifierBonusHealth()
	return self.bonus_health
end

function modifier_item_magician_core:GetModifierPercentageCooldownStackingUnique()
	return self.cooldown_reduction
end

LinkLuaModifier("modifier_item_magician_core", "items/item_magician_core", LUA_MODIFIER_MOTION_NONE, modifier_item_magician_core)