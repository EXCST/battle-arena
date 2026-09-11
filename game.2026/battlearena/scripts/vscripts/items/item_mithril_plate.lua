require('items/generic_datadriven_item')


item_mithril_plate = class({})

function item_mithril_plate:GetIntrinsicModifierName()
	return "modifier_item_mithril_plate"
end


item_mithril_plate_1 = class(item_mithril_plate)
item_mithril_plate_2 = class(item_mithril_plate)
item_mithril_plate_3 = class(item_mithril_plate)

item_atlant_armor_1 = class(item_mithril_plate)
item_atlant_armor_2 = class(item_mithril_plate)
item_atlant_armor_3 = class(item_mithril_plate)

--------------------------------------------------------
------------------------------------------------------------
modifier_item_mithril_plate = class({
	IsHidden 				= function(self) return true end,
	DeclareFunctions		= function(self) return 
		{
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		} end,
})

function modifier_item_mithril_plate:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.bonusStrength = self.ability:GetSpecialValueFor("bonus_str")
	self.bonusArmor = self.ability:GetSpecialValueFor("bonus_armor")
	self.bonusDamageReductionPct = self.ability:GetSpecialValueFor("damage_reduction_pct")
end

function modifier_item_mithril_plate:GetModifierBonusStats_Strength()
	return self.bonusStrength
end

function modifier_item_mithril_plate:GetModifierPhysicalArmorBonus()
	return self.bonusArmor
end

function modifier_item_mithril_plate:GetModifierIncomingDamageResistance_Percentage()
	return self.bonusDamageReductionPct
end


LinkLuaModifier("modifier_item_mithril_plate", "items/item_mithril_plate", LUA_MODIFIER_MOTION_NONE, modifier_item_mithril_plate)
