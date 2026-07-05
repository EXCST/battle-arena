require('items/generic_datadriven_item')


item_blue_swift = class({})

function item_blue_swift:GetIntrinsicModifierName()
	return "modifier_item_blue_swift"
end


item_blue_swift_1 = class(item_blue_swift)
item_blue_swift_2 = class(item_blue_swift)
item_blue_swift_3 = class(item_blue_swift)

item_void_glove_1 = class(item_blue_swift)
item_void_glove_2 = class(item_blue_swift)
item_void_glove_3 = class(item_blue_swift)

item_speedster_glove_1 = class(item_blue_swift)
item_speedster_glove_2 = class(item_blue_swift)
item_speedster_glove_3 = class(item_blue_swift)

--------------------------------------------------------
------------------------------------------------------------
modifier_item_blue_swift = class({
	IsHidden 				= function(self) return true end,
	DeclareFunctions		= function(self) return 
	{
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	} end,
})

function modifier_item_blue_swift:OnCreated()
	self.ability = self:GetAbility()
	self:OnRefresh()
	if(not IsServer()) then
		return
	end
end

function modifier_item_blue_swift:OnRefresh()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.bonus_attack_speed = self.ability:GetSpecialValueFor("bonus_attack_speed")
	
	self.bonus_ms_pct = self.ability:GetSpecialValueFor("bonus_ms_pct")
end

function modifier_item_blue_swift:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_item_blue_swift:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_ms_pct
end



LinkLuaModifier("modifier_item_blue_swift", "items/item_blue_swift", LUA_MODIFIER_MOTION_NONE, modifier_item_blue_swift)
