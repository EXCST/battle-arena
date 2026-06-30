require('items/generic_datadriven_item')

item_butterfly_custom = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_butterfly_custom"
	end
})

item_butterfly_custom_1 = class(item_butterfly_custom)
item_butterfly_custom_2 = class(item_butterfly_custom)
item_butterfly_custom_3 = class(item_butterfly_custom)

item_silent_glaive_1 = class(item_butterfly_custom)
item_silent_glaive_2 = class(item_butterfly_custom)
item_silent_glaive_3 = class(item_butterfly_custom)

item_aeol_driver_1 = class(item_butterfly_custom)
item_aeol_driver_2 = class(item_butterfly_custom)
item_aeol_driver_3 = class(item_butterfly_custom)
modifier_item_butterfly_custom = class({
    IsHidden = function()
        return true
    end,
	IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
	GetAttributes = function()
        return MODIFIER_ATTRIBUTE_MULTIPLE
    end,
	DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_ROSHDEF_EVASION_CONSTANT,
--            MODIFIER_PROPERTY_EVASION_CONSTANT ,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
        }
    end,
	GetModifierBonusStats_Agility = function(self)
		return self.bonus_agi
	end,
	GetModifierEvasion_Constant = function(self)
		return self.evasion_pct
	end,
	GetModifierAttackSpeedBonus_Constant = function(self)
		return self.bonus_attack_speed
	end
})

function modifier_item_butterfly_custom:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_butterfly_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonus_agi = self.ability:GetSpecialValueFor("bonus_agi")
    self.evasion_pct = self.ability:GetSpecialValueFor("evasion_pct")
    self.bonus_attack_speed = self.ability:GetSpecialValueFor("bonus_attack_speed")
end

LinkLuaModifier("modifier_item_butterfly_custom", "items/item_butterfly_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_butterfly_custom)