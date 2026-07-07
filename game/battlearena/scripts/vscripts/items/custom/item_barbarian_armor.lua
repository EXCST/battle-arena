require('items/generic_datadriven_item')


item_barbarian_armor = class({})

function item_barbarian_armor:GetIntrinsicModifierName()
	return "modifier_item_barbarian_armor"
end
--------------------------------------------------------
------------------------------------------------------------
modifier_item_barbarian_armor = class({
	IsHidden 				= function(self) return true end,
	DeclareFunctions		= function(self) return 
		{
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH_PERCENTAGE
		
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        } end, 
})

function modifier_item_barbarian_armor:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
	self.bonus_str = self.ability:GetSpecialValueFor("bonus_str")
	self.bonus_armor = self.ability:GetSpecialValueFor("bonus_armor")
	self.bonus_health_pct = self.ability:GetSpecialValueFor("bonus_health_pct")
end

function modifier_item_barbarian_armor:GetModifierBonusStats_Strength()
	return self.bonus_str
end
function modifier_item_barbarian_armor:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_item_barbarian_armor:GetModifierBonusHealthPercentage()
	return self.bonus_health_pct
end

function modifier_item_barbarian_armor:GetModifierBonusHealth()
	return self.bonus_health
end

item_barbarian_armor_1 = class(item_barbarian_armor)
item_barbarian_armor_2 = class(item_barbarian_armor)


LinkLuaModifier("modifier_item_barbarian_armor", "items/custom/item_barbarian_armor", LUA_MODIFIER_MOTION_NONE, modifier_item_barbarian_armor)
