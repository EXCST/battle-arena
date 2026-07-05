require('items/generic_datadriven_item')

item_skadi_custom = class({
	GetIntrinsicModifierName = function() return "modifier_item_skadi_custom" end
})

modifier_item_skadi_custom = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	IsPurgeException = function() return false end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_PROJECTILE_NAME,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	} end,
	GetModifierBonusStats_Strength = function(self) return self.bonus_all_stats end,
	GetModifierBonusStats_Agility = function(self) return self.bonus_all_stats end,
	GetModifierBonusStats_Intellect = function(self) return self.bonus_all_stats end,
	GetModifierProjectileName = function() return "particles/items2_fx/skadi_projectile.vpcf" end
})

function modifier_item_skadi_custom:OnCreated()
	self.ability = self:GetAbility()
	self:OnRefresh()
end

function modifier_item_skadi_custom:OnRefresh()
	if (not IsServer()) then return end
	self.ability = self:GetAbility() or self.ability
	if not self.ability then return end

	self.bonus_all_stats = self.ability:GetSpecialValueFor("bonus_all_stats")
	self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
	self.bonus_mana = self.ability:GetSpecialValueFor("bonus_mana")
end