require('items/generic_datadriven_item')


item_achilles_helm = class({})

function item_achilles_helm:GetIntrinsicModifierName()
	return "modifier_item_achilles_helm"
end

--------------------------------------------------------
------------------------------------------------------------
modifier_item_achilles_helm = class({
	IsHidden 				= function(self) return true end,
	DeclareFunctions		= function(self) return 
		{
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH_PERCENTAGE,
		
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        } end,
})

function modifier_item_achilles_helm:OnCreated()
	self.ability = self:GetAbility()
	self:OnRefresh()
	if(not IsServer()) then
		return
	end
end

function modifier_item_achilles_helm:OnRefresh()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.bonusStrength = self.ability:GetSpecialValueFor("bonus_str")
	self.bonusArmor = self.ability:GetSpecialValueFor("bonus_armor")
	self.bonusHealth = self.ability:GetSpecialValueFor("bonus_health")

	self.bonusHealthPct = self.ability:GetSpecialValueFor("bonus_health_pct")
	self.bonusDamageReductionPct = self.ability:GetSpecialValueFor("damage_reduction_pct")
end

function modifier_item_achilles_helm:GetModifierBonusStats_Strength()
	return self.bonusStrength
end

function modifier_item_achilles_helm:GetModifierPhysicalArmorBonus()
	return self.bonusArmor
end

function modifier_item_achilles_helm:GetModifierBonusHealth()
	return self.bonusHealth
end

function modifier_item_achilles_helm:GetModifierBonusHealthPercentage()
	return self.bonusHealthPct
end

function modifier_item_achilles_helm:GetModifierIncomingDamageResistance_Percentage()
	return self.bonusDamageReductionPct
end


LinkLuaModifier("modifier_item_achilles_helm", "items/item_achilles_helm", LUA_MODIFIER_MOTION_NONE, modifier_item_achilles_helm)
