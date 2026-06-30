require('items/generic_datadriven_item')

item_heart_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_heart_custom"
    end
})

item_heart_custom_1 = class(item_heart_custom)
item_heart_custom_2 = class(item_heart_custom)
item_heart_custom_3 = class(item_heart_custom)

item_malice_armor_1 = class(item_heart_custom)
item_malice_armor_2 = class(item_heart_custom)
item_malice_armor_3 = class(item_heart_custom)

item_haunted_armor_1 = class(item_heart_custom)
item_haunted_armor_2 = class(item_heart_custom)
item_haunted_armor_3 = class(item_heart_custom)

modifier_item_heart_custom = class({
	IsHidden = function() 
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
        return {
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_ROSHDEF_HEALTH_REGEN_PERCENTAGE_UNIQUE
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end
})

function modifier_item_heart_custom:OnCreated( params )
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_heart_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_str = self.ability:GetSpecialValueFor("bonus_str")
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.hp_regen_pct = self.ability:GetSpecialValueFor("hp_regen_pct")
end

function modifier_item_heart_custom:GetModifierBonusStats_Strength()
    return self.bonus_str
end

function modifier_item_heart_custom:GetModifierBonusHealth()
	return self.bonus_health
end

function modifier_item_heart_custom:GetModifierHealthRegenBasedOnMaxHPUnique()
    return self.hp_regen_pct
end

LinkLuaModifier("modifier_item_heart_custom", "items/item_heart_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_heart_custom)