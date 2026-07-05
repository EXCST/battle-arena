require('items/generic_datadriven_item')

item_achilles_helm = class({
	GetIntrinsicModifierName = function() return "modifier_item_achilles_helm" end
})

modifier_item_achilles_helm = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH_PERCENTAGE,
		MODIFIER_PROPERTY_ROSHDEF_INCOMING_DAMAGE_RESISTANCE_PERCENTAGE
	
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        } end,
	GetModifierBonusHealth = function(self) return self.bonusHealth end,
	GetModifierPhysicalArmorBonus = function(self) return self.bonusArmor end,
	GetModifierBonusStats_Strength = function(self) return self.bonusStrength end,
	GetModifierIncomingDamageResistance_Percentage = function(self) return self.bonusDamageReductionPct end,
	GetModifierBonusHealthPercentage = function(self) return self.bonusHealthPct end,
})

function modifier_item_achilles_helm:OnCreated()
	self.ability = self:GetAbility()
	self:OnRefresh()
end

function modifier_item_achilles_helm:OnRefresh()
	if (not IsServer()) then return end
	self.ability = self:GetAbility() or self.ability
	if not self.ability then return end

	self.bonusHealth = self.ability:GetSpecialValueFor("bonus_health")
	self.bonusArmor = self.ability:GetSpecialValueFor("bonus_armor")
	self.bonusStrength = self.ability:GetSpecialValueFor("bonus_str")
	self.bonusDamageReductionPct = self.ability:GetSpecialValueFor("damage_reduction_pct")
	self.bonusHealthPct = self.ability:GetSpecialValueFor("bonus_health_pct")
end

LinkLuaModifier("modifier_item_achilles_helm", "items/item_knight_armor", LUA_MODIFIER_MOTION_NONE, modifier_item_achilles_helm)