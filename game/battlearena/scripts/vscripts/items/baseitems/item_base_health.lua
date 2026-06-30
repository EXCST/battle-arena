require('items/generic_datadriven_item')


item_base_health = class({})

function item_base_health:GetIntrinsicModifierName()
	return "modifier_item_base_health"
end

item_base_health_1 = class(item_base_health)
item_base_health_2 = class(item_base_health)
item_base_health_3 = class(item_base_health)
item_base_health_4 = class(item_base_health)
item_base_health_5 = class(item_base_health)

modifier_item_base_health = class({
	IsHidden 		= function(self) return true end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
	
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }end,
})

function modifier_item_base_health:OnCreated()
	self.parent = self:GetParent()
end

function modifier_item_base_health:GetModifierBonusHealth()
	return self:GetAbility():GetSpecialValueFor("bonus_health")
end

LinkLuaModifier("modifier_item_base_health", "items/baseitems/item_base_health", LUA_MODIFIER_MOTION_NONE, modifier_item_base_health)
