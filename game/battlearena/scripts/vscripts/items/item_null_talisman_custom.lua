require('items/generic_datadriven_item')


item_null_talisman_custom = class({})

function item_null_talisman_custom:GetIntrinsicModifierName()
	return "modifier_item_null_talisman_custom"
end

modifier_item_null_talisman_custom = class({
	IsHidden 		= function(self) return true end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}end,
})

function modifier_item_null_talisman_custom:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self:OnRefresh()
end

function modifier_item_null_talisman_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_str = self.ability:GetSpecialValueFor("bonus_str")
    self.bonus_agi = self.ability:GetSpecialValueFor("bonus_agi")
    self.bonus_int = self.ability:GetSpecialValueFor("bonus_int")
    self.bonus_mp_regen = self.ability:GetSpecialValueFor("bonus_mp_regen")
end

function modifier_item_null_talisman_custom:GetModifierBonusStats_Strength()
	return self.bonus_str
end

function modifier_item_null_talisman_custom:GetModifierBonusStats_Agility()
	return self.bonus_agi
end

function modifier_item_null_talisman_custom:GetModifierBonusStats_Intellect()
	return self.bonus_int
end

function modifier_item_null_talisman_custom:GetModifierConstantManaRegen()
	return self.bonus_mp_regen
end

LinkLuaModifier("modifier_item_null_talisman_custom", "items/item_null_talisman_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_null_talisman_custom)
