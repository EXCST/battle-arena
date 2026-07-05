require('items/generic_datadriven_item')


item_base_allstats = class({})

function item_base_allstats:GetIntrinsicModifierName()
	return "modifier_item_base_allstats"
end

item_base_allstats_1 = class(item_base_allstats)
item_base_allstats_2 = class(item_base_allstats)
item_base_allstats_3 = class(item_base_allstats)
item_base_allstats_4 = class(item_base_allstats)
item_base_allstats_5 = class(item_base_allstats)

modifier_item_base_allstats = class({
	IsHidden 		= function(self) return true end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}end,
})

function modifier_item_base_allstats:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
end

function modifier_item_base_allstats:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
end

function modifier_item_base_allstats:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_base_allstats:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_base_allstats:GetModifierBonusStats_Intellect()
    return self.bonus_allstats
end

LinkLuaModifier("modifier_item_base_allstats", "items/baseitems/item_base_allstats", LUA_MODIFIER_MOTION_NONE, modifier_item_base_allstats)
