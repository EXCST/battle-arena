require('items/generic_datadriven_item')

item_taras_heart = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_taras_heart"
    end
})

item_taras_heart_1 = class(item_taras_heart)
item_taras_heart_2 = class(item_taras_heart)
item_taras_heart_3 = class(item_taras_heart)

modifier_item_taras_heart = class({
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

function modifier_item_taras_heart:OnCreated( params )
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_taras_heart:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_str = self.ability:GetSpecialValueFor("bonus_str")
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.hp_regen_pct = self.ability:GetSpecialValueFor("hp_regen_pct")
end

function modifier_item_taras_heart:GetModifierBonusStats_Strength()
    return self.bonus_str
end

function modifier_item_taras_heart:GetModifierBonusHealth()
	return self.bonus_health
end

function modifier_item_taras_heart:GetModifierHealthRegenBasedOnMaxHPUnique()
    return self.hp_regen_pct
end

LinkLuaModifier("modifier_item_taras_heart", "items/item_taras_heart", LUA_MODIFIER_MOTION_NONE, modifier_item_taras_heart)