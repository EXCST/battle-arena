require('items/generic_datadriven_item')


item_tome_of_knowledge_custom = class({})

function item_tome_of_knowledge_custom:GetIntrinsicModifierName()
	return "modifier_item_tome_of_knowledge_custom"
end

function item_tome_of_knowledge_custom:OnSpellStart()
	local bonus_xp = self:GetSpecialValueFor("bonus_xp")
	local caster = self:GetCaster()

	caster:EmitSound("Item.TomeOfKnowledge")
	caster:AddExperience(bonus_xp, 0, false, true)
end
--------------------------------------------------------
------------------------------------------------------------
modifier_item_tome_of_knowledge_custom = class({
	IsHidden 				= function(self) return true end,
	DeclareFunctions		= function(self) return 
		{
			MODIFIER_PROPERTY_EXP_RATE_BOOST,
		} end,
})

function modifier_item_tome_of_knowledge_custom:GetModifierPercentageExpRateBoost()
	return self:GetAbility():GetSpecialValueFor("bonus_xp_pct")
end

item_tome_of_knowledge_custom_1 = class(item_tome_of_knowledge_custom)
item_tome_of_knowledge_custom_2 = class(item_tome_of_knowledge_custom)
item_tome_of_knowledge_custom_3 = class(item_tome_of_knowledge_custom)


LinkLuaModifier("modifier_item_tome_of_knowledge_custom", "items/custom/item_tome_of_knowledge_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_tome_of_knowledge_custom)
