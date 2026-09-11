require('items/generic_datadriven_item')


item_barbarian_helm = class({})

function item_barbarian_helm:GetIntrinsicModifierName()
	return "modifier_item_barbarian_helm"
end
--------------------------------------------------------
------------------------------------------------------------
modifier_item_barbarian_helm = class({
	IsHidden 				= function(self) return true end,
	DeclareFunctions		= function(self) return 
		{
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
		
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        } end,
})

function modifier_item_barbarian_helm:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self:OnRefresh()
	if(not IsServer()) then
		return
	end
	self:StartIntervalThink(0.1)
end

function modifier_item_barbarian_helm:OnRefresh()
	self.ability = self:GetAbility() or self.ability
	if(not self.ability or self.ability:IsNull()) then
		return
	end
	self.strHealth = self.ability:GetSpecialValueFor("str_health")
	self.strRegen = self.ability:GetSpecialValueFor("str_regen")
	self.bonusStr = self.ability:GetSpecialValueFor("bonus_str")
	self.bonusAgi = self.ability:GetSpecialValueFor("bonus_agi")
	self.bonusInt = self.ability:GetSpecialValueFor("bonus_int")
	self.bonusArmor = self.ability:GetSpecialValueFor("bonus_armor")
	self.damageReductionPct = self.ability:GetSpecialValueFor("bonus_resist")
end

function modifier_item_barbarian_helm:OnIntervalThink()
	if(self.parent.CalculateStatBonus) then
		self.parent:CalculateStatBonus(true)
		return
	end
	self.parent:CalculateGenericBonuses()
end
 
function modifier_item_barbarian_helm:GetModifierBonusHealth()
	if(self.parent.GetStrength) then
		return (self.strHealth or 0)*self.parent:GetStrength(true)
	end
	return 0
end

function modifier_item_barbarian_helm:GetModifierConstantHealthRegen()
	if(self.parent.GetStrength) then
		return (self.strRegen or 0)*self.parent:GetStrength(true)
	end
	return 0
end

function modifier_item_barbarian_helm:GetModifierBonusStats_Strength()
	return self.bonusStr
end

function modifier_item_barbarian_helm:GetModifierBonusStats_Agility()
	return self.bonusAgi
end

function modifier_item_barbarian_helm:GetModifierBonusStats_Intellect()
	return self.bonusInt
end

function modifier_item_barbarian_helm:GetModifierPhysicalArmorBonus()
	return self.bonusArmor
end

function modifier_item_barbarian_helm:GetModifierIncomingDamageResistance_Percentage()
	return self.damageReductionPct
end

item_barbarian_helm_1 = class(item_barbarian_helm)
item_barbarian_helm_2 = class(item_barbarian_helm)


LinkLuaModifier("modifier_item_barbarian_helm", "items/custom/item_barbarian_helm", LUA_MODIFIER_MOTION_NONE, modifier_item_barbarian_helm)
