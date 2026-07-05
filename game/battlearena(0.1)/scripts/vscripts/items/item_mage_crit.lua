require('items/generic_datadriven_item')

LinkLuaModifier("modifier_item_mage_crit", "items/item_mage_crit", LUA_MODIFIER_MOTION_NONE)

item_mage_crit = class({})

function item_mage_crit:GetIntrinsicModifierName()
	return "modifier_item_mage_crit"
end

modifier_item_mage_crit = class({})

function modifier_item_mage_crit:IsHidden()
	return true
end

function modifier_item_mage_crit:IsPurgable() return false end
function modifier_item_mage_crit:IsPurgeException() return false end

function modifier_item_mage_crit:DeclareFunctions()
	return 
	{
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
	}
end

function modifier_item_mage_crit:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_item_mage_crit:GetModifierTotalDamageOutgoing_Percentage(params)
	if params.damage_category == DOTA_DAMAGE_CATEGORY_SPELL then 
		if self:GetParent():FindAllModifiersByName("modifier_item_mage_crit")[1] ~= self then return end
		if self:GetParent().block_crit ~= nil then return end
		if RollPercentage(self:GetAbility():GetSpecialValueFor("chance")) then
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, params.target, params.original_damage + (params.original_damage / 100 * (self:GetAbility():GetSpecialValueFor("spell_damage_crit") - 100)), nil)
			return self:GetAbility():GetSpecialValueFor("spell_damage_crit") - 100
		end
	end
end

function modifier_item_mage_crit:GetModifierMPRegenAmplify_Percentage(params)
	return self:GetAbility():GetSpecialValueFor("mana_regen_amp")
end

function modifier_item_mage_crit:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("health_regen")
end

function modifier_item_mage_crit:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("armor")
end

function modifier_item_mage_crit:GetModifierBonusStats_Strength(params)
	return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_mage_crit:GetModifierBonusStats_Agility(params)
	return self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_mage_crit:GetModifierBonusStats_Intellect(params)
	return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_mage_crit:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("lifesteal_amplify")
end

function modifier_item_mage_crit:GetModifierSpellAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("spell_amplify")
end

