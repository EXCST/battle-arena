require('items/generic_datadriven_item')


item_fellow_sign = class({})

function item_fellow_sign:GetIntrinsicModifierName()
	return "modifier_item_fellow_sign"
end

modifier_item_fellow_sign = class({
	IsHidden 		= function(self) return true end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}end,
})

function modifier_item_fellow_sign:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_allstats")
end

function modifier_item_fellow_sign:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_allstats")
end

function modifier_item_fellow_sign:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_allstats")
end


LinkLuaModifier("modifier_item_fellow_sign", "items/item_fellow_sign", LUA_MODIFIER_MOTION_NONE, modifier_item_fellow_sign)
