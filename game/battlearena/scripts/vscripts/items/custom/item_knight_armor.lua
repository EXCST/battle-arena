require('items/generic_datadriven_item')


item_knight_armor = class({})

function item_knight_armor:GetIntrinsicModifierName()
	return "modifier_item_knight_armor"
end


item_knight_armor_1 = class(item_knight_armor)
item_knight_armor_2 = class(item_knight_armor)
item_knight_armor_3 = class(item_knight_armor)

item_champion_armor_1 = class(item_knight_armor)
item_champion_armor_2 = class(item_knight_armor)
item_champion_armor_3 = class(item_knight_armor)

item_titan_armor_1 = class(item_knight_armor)
item_titan_armor_2 = class(item_knight_armor)
item_titan_armor_3 = class(item_knight_armor)

--------------------------------------------------------
------------------------------------------------------------
modifier_item_knight_armor = class({
	IsHidden 				= function(self) return true end,
	DeclareFunctions		= function(self) return 
		{
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH_PERCENTAGE,
		
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        } end,
})

function modifier_item_knight_armor:OnCreated()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.bonusHealth = self.ability:GetSpecialValueFor("bonus_health")
	self.bonusArmor = self.ability:GetSpecialValueFor("bonus_armor")
	self.bonusHealthPct = self.ability:GetSpecialValueFor("bonus_health_pct")
end

function modifier_item_knight_armor:GetModifierBonusHealth()
	return self.bonusHealth
end

function modifier_item_knight_armor:GetModifierPhysicalArmorBonus()
	return self.bonusArmor
end

function modifier_item_knight_armor:GetModifierBonusHealthPercentage()
	return self.bonusHealthPct
end


LinkLuaModifier("modifier_item_knight_armor", "items/item_knight_armor", LUA_MODIFIER_MOTION_NONE, modifier_item_knight_armor)
