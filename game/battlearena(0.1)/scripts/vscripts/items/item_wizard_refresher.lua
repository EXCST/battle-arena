require('items/generic_datadriven_item')

require("items/item_refresher_orb")

item_wizard_refresher = class(item_refresher_orb)

function item_wizard_refresher:GetIntrinsicModifierName()
    return "modifier_item_wizard_refresher"
end

modifier_item_wizard_refresher = class({
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
        return 
        {
            MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
            MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_ROSHDEF_COOLDOWN_REDUCTION_STACKING_UNIQUE
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end
})

function modifier_item_wizard_refresher:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_wizard_refresher:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  

    self.bonus_mana = self.ability:GetSpecialValueFor("bonus_mana")
    self.bonus_mp_regen = self.ability:GetSpecialValueFor("bonus_mp_regen")
    self.bonus_int = self.ability:GetSpecialValueFor("bonus_int")
    self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
    self.cooldown_reduction = self.ability:GetSpecialValueFor("cooldown_reduction")
end

function modifier_item_wizard_refresher:GetModifierBonusHealth()
		return self.bonus_health
end

function modifier_item_wizard_refresher:GetModifierExtraManaBonus()
	if(self.parent:IsRealHero() == true) then
		return self.bonus_mana
	end
	return 0
end

function modifier_item_wizard_refresher:GetModifierExtraManaBonus()
	if(self.parent:IsRealHero() == true) then
		return 0
	end
	return self.bonus_mana
end

function modifier_item_wizard_refresher:GetModifierConstantManaRegen()
    return self.bonus_mp_regen
end

function modifier_item_wizard_refresher:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_wizard_refresher:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_wizard_refresher:GetModifierBonusStats_Intellect()
    return self.bonus_allstats + self.bonus_int
end

function modifier_item_wizard_refresher:GetModifierPercentageCooldownStackingUnique()
	return self.cooldown_reduction
end

LinkLuaModifier("modifier_item_wizard_refresher", "items/item_wizard_refresher", LUA_MODIFIER_MOTION_NONE, modifier_item_wizard_refresher)
