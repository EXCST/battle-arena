require('items/generic_datadriven_item')


item_warrior_shield = class({})

function item_warrior_shield:GetIntrinsicModifierName()
	return "modifier_item_warrior_shield"
end
--------------------------------------------------------
------------------------------------------------------------
modifier_item_warrior_shield = class({
	IsHidden 				= function(self) return true end,
	DeclareFunctions		= function(self) return 
		{
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH
		
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        } end,
})

function modifier_item_warrior_shield:GetModifierBonusHealth()
		return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_warrior_shield:GetModifierPhysical_ConstantBlock()
	return self:GetAbility():GetSpecialValueFor("bonus_block")
end

function modifier_item_warrior_shield:GetModifierPhysical_ConstantBlockUnavoidablePreArmor()
	local block_chance = self:GetAbility():GetSpecialValueFor("block_chance") 
	if RollPercentage(block_chance) then
		return 999999
	end
end

item_warrior_shield_1 = class(item_warrior_shield)
item_warrior_shield_2 = class(item_warrior_shield)


LinkLuaModifier("modifier_item_warrior_shield", "items/custom/item_warrior_shield", LUA_MODIFIER_MOTION_NONE, modifier_item_warrior_shield)
