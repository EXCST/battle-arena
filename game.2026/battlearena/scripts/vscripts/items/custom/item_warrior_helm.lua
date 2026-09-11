require('items/generic_datadriven_item')


item_warrior_helm = class({})

function item_warrior_helm:GetIntrinsicModifierName()
	return "modifier_item_warrior_helm"
end
--------------------------------------------------------
------------------------------------------------------------
modifier_item_warrior_helm = class({
	IsHidden 				= function(self) return true end,
	DeclareFunctions		= function(self) return 
		{
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
		} end,
})

function modifier_item_warrior_helm:OnCreated()
	self.ability = self:GetAbility()
	self.bonus_stats = self.ability:GetSpecialValueFor("bonus_stats")
	self.bonus_armor = self.ability:GetSpecialValueFor("bonus_armor")
	self.bonus_status_resist = self.ability:GetSpecialValueFor("bonus_status_resist")
end

function modifier_item_warrior_helm:GetModifierBonusStats_Strength()
	return self.bonus_stats
end

function modifier_item_warrior_helm:GetModifierBonusStats_Agility()
	return self.bonus_stats
end

function modifier_item_warrior_helm:GetModifierBonusStats_Intellect()
	return self.bonus_stats
end

function modifier_item_warrior_helm:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_item_warrior_helm:GetModifierStatusResistanceStacking()
	return self.bonus_status_resist
end

item_warrior_helm_1 = class(item_warrior_helm)
item_warrior_helm_2 = class(item_warrior_helm)


LinkLuaModifier("modifier_item_warrior_helm", "items/custom/item_warrior_helm", LUA_MODIFIER_MOTION_NONE, modifier_item_warrior_helm)
