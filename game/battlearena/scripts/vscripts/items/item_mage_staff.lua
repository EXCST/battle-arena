require('items/generic_datadriven_item')

item_mage_staff = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_mage_staff"
	end
})

modifier_item_mage_staff = class({
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
			MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
        }
    end
})

function modifier_item_mage_staff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_mage_staff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_mana = self.ability:GetSpecialValueFor("bonus_mana")
	self.bonus_mp_regen = self.ability:GetSpecialValueFor("bonus_mp_regen")
end

function modifier_item_mage_staff:GetModifierExtraManaBonus()
    return self.bonus_mana
end

function modifier_item_mage_staff:GetModifierConstantManaRegen()
    return self.bonus_mp_regen
end

LinkLuaModifier("modifier_item_mage_staff", "items/item_mage_staff", LUA_MODIFIER_MOTION_NONE, modifier_item_mage_staff)