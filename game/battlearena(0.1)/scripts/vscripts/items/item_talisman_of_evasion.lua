require('items/generic_datadriven_item')

item_talisman_of_evasion_custom = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_talisman_of_evasion_custom"
	end
})

modifier_item_talisman_of_evasion_custom = class({
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
			MODIFIER_PROPERTY_ROSHDEF_EVASION_CONSTANT
        }
    end,
	GetModifierEvasion_Constant = function(self)
		return self.bonus_evasion
	end
})

function modifier_item_talisman_of_evasion_custom:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_talisman_of_evasion_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end 
    self.bonus_evasion = self.ability:GetSpecialValueFor("bonus_evasion")
end

LinkLuaModifier("modifier_item_talisman_of_evasion_custom", "items/item_talisman_of_evasion", LUA_MODIFIER_MOTION_NONE, modifier_item_talisman_of_evasion_custom)