require('items/generic_datadriven_item')


item_guardian_armor = class({})

function item_guardian_armor:GetIntrinsicModifierName()
	return "modifier_item_guardian_armor"
end
--------------------------------------------------------
------------------------------------------------------------
modifier_item_guardian_armor = class({
	IsHidden 				= function(self) return true end,
	DeclareFunctions		= function(self) return 
		{
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
		} end,
})

function modifier_item_guardian_armor:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self:OnRefresh()
end

function modifier_item_guardian_armor:OnRefresh()
	if(not self.ability) then
		return
	end
	self.bonusStr = self.ability:GetSpecialValueFor("bonus_str")
	self.bonusArmor = self.ability:GetSpecialValueFor("bonus_armor")
	self.damageReductionPct = self.ability:GetSpecialValueFor("bonus_resist")
end

function modifier_item_guardian_armor:GetModifierBonusStats_Strength()
	return self.bonusStr
end

function modifier_item_guardian_armor:GetModifierPhysicalArmorBonus()
	return self.bonusArmor
end

function modifier_item_guardian_armor:GetModifierIncomingDamageResistance_Percentage()
	if(self.parent:HasModifier("modifier_item_barbarian_helm")) then
		return 0
	end
	return self.damageReductionPct
end

item_guardian_armor_1 = class(item_guardian_armor)
item_guardian_armor_2 = class(item_guardian_armor)


LinkLuaModifier("modifier_item_guardian_armor", "items/custom/item_guardian_armor", LUA_MODIFIER_MOTION_NONE, modifier_item_guardian_armor)
