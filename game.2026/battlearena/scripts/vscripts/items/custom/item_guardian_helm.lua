require('items/generic_datadriven_item')


item_guardian_helm = class({})

function item_guardian_helm:GetIntrinsicModifierName()
	return "modifier_item_guardian_helm"
end
--------------------------------------------------------
------------------------------------------------------------
modifier_item_guardian_helm = class({
	IsHidden 				= function(self) return true end,
	DeclareFunctions		= function(self) return 
		{
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        } end,
})
function modifier_item_guardian_helm:OnCreated()
	self.parent = self:GetParent()
	if(not IsServer()) then
		return
	end
	self:StartIntervalThink(1)
end

function modifier_item_guardian_helm:OnIntervalThink()
	if(self.parent.CalculateStatBonus) then
		self.parent:CalculateStatBonus(true)
		return
	end
	self.parent:CalculateGenericBonuses()
end
 
function modifier_item_guardian_helm:GetModifierBonusHealth()
	if(self.parent.GetStrength) then
		return self:GetAbility():GetSpecialValueFor("str_health")*self.parent:GetStrength(true)
	end
	return 0
end

function modifier_item_guardian_helm:GetModifierConstantHealthRegen()
	if(self.parent.GetStrength) then
		return self:GetAbility():GetSpecialValueFor("str_regen")*self.parent:GetStrength(true)
	end
	return 0
end

function modifier_item_guardian_helm:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_guardian_helm:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_agi")
end

function modifier_item_guardian_helm:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_int")
end


item_guardian_helm_1 = class(item_guardian_helm)
item_guardian_helm_2 = class(item_guardian_helm)


LinkLuaModifier("modifier_item_guardian_helm", "items/custom/item_guardian_helm", LUA_MODIFIER_MOTION_NONE, modifier_item_guardian_helm)
