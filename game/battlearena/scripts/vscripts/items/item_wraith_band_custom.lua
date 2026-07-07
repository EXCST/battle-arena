require('items/generic_datadriven_item')


item_wraith_band_custom = class({})

function item_wraith_band_custom:GetIntrinsicModifierName()
	return "modifier_item_wraith_band_custom"
end

modifier_item_wraith_band_custom = class({
	IsHidden 		= function(self) return true end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}end,
})

function modifier_item_wraith_band_custom:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self:OnRefresh()
end

function modifier_item_wraith_band_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_str = self.ability:GetSpecialValueFor("bonus_str")
    self.bonus_agi = self.ability:GetSpecialValueFor("bonus_agi")
    self.bonus_int = self.ability:GetSpecialValueFor("bonus_int")
    self.bonus_attack_speed = self.ability:GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_wraith_band_custom:GetModifierBonusStats_Strength()
	return self.bonus_str
end

function modifier_item_wraith_band_custom:GetModifierBonusStats_Agility()
	return self.bonus_agi
end

function modifier_item_wraith_band_custom:GetModifierBonusStats_Intellect()
	return self.bonus_int
end

function modifier_item_wraith_band_custom:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

LinkLuaModifier("modifier_item_wraith_band_custom", "items/item_wraith_band_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_wraith_band_custom)
