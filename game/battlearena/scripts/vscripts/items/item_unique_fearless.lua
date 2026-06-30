require('items/generic_datadriven_item')


item_unique_fearless = class({})

function item_unique_fearless:GetIntrinsicModifierName()
	return "modifier_item_unique_fearless"
end

modifier_item_unique_fearless = class({
	IsHidden 		= function(self) return true end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_ROSHDEF_COOLDOWN_REDUCTION_STACKING_UNIQUE,
	}end,
})

function modifier_item_unique_fearless:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    self:StartIntervalThink(0.1)

    if(not IsServer()) then
        return
    end
end

function modifier_item_unique_fearless:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
    self.bonus_armor = self.ability:GetSpecialValueFor("bonus_armor")
    self.bonus_hp_regen = self.ability:GetSpecialValueFor("bonus_hp_regen")
    self.cooldown_reduction = self.ability:GetSpecialValueFor("cooldown_reduction")

end

function modifier_item_unique_fearless:OnIntervalThink()
     if(not IsServer()) then
        return
    end
    
    local hero_level = self:GetCaster():GetLevel()
    local index_check = 0    
    local level_require = self.ability:GetLevelSpecialValueFor("level_require", index_check)
    while hero_level>=level_require do
        index_check = index_check + 1
        level_require = self.ability:GetLevelSpecialValueFor("level_require", index_check)
    end
    self.ability:SetLevel(index_check)
    self:OnRefresh()
end

function modifier_item_unique_fearless:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_unique_fearless:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_unique_fearless:GetModifierBonusStats_Intellect()
    return self.bonus_allstats
end

function modifier_item_unique_fearless:GetModifierPhysicalArmorBonus()
    return self.bonus_armor
end

function modifier_item_unique_fearless:GetModifierConstantHealthRegen()
    return self.bonus_hp_regen
end

function modifier_item_unique_fearless:GetModifierPercentageCooldownStacking()
    return self.cooldown_reduction
end

LinkLuaModifier("modifier_item_unique_fearless", "items/item_unique_fearless", LUA_MODIFIER_MOTION_NONE, modifier_item_unique_fearless)
