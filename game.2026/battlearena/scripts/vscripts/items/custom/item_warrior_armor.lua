require('items/generic_datadriven_item')


item_warrior_armor = class({})

function item_warrior_armor:GetIntrinsicModifierName()
	return "modifier_item_warrior_armor"
end
--------------------------------------------------------
------------------------------------------------------------
modifier_item_warrior_armor = class({
	IsHidden 				= function(self) return true end,
	DeclareFunctions		= function(self) return 
		{
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH_PERCENTAGE,
		
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        } end,
})

function modifier_item_warrior_armor:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.bonusHealth = self.ability:GetSpecialValueFor("bonus_health")
	self.bonusArmor = self.ability:GetSpecialValueFor("bonus_armor")
	self.bonusHealthPct = self.ability:GetSpecialValueFor("bonus_health_pct")
end

function modifier_item_warrior_armor:GetModifierBonusHealth()
	return self.bonusHealth
end

function modifier_item_warrior_armor:GetModifierPhysicalArmorBonus()
	return self.bonusArmor
end

function modifier_item_warrior_armor:GetModifierBonusHealthPercentage()
	return self.bonusHealthPct
end

item_warrior_armor_1 = class(item_warrior_armor)
item_warrior_armor_2 = class(item_warrior_armor)


LinkLuaModifier("modifier_item_warrior_armor", "items/custom/item_warrior_armor", LUA_MODIFIER_MOTION_NONE, modifier_item_warrior_armor)
