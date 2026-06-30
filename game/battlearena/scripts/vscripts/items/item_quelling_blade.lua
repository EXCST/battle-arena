require('items/generic_datadriven_item')

item_quelling_blade_custom = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_quelling_blade_custom"
	end,
    GetAOERadius = function(self)
        return self:GetSpecialValueFor("woodcutter_radius")
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("cast_range")
    end
})

function item_quelling_blade_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local castPosition = self:GetCursorPosition()
    GridNav:DestroyTreesAroundPoint(castPosition, self:GetSpecialValueFor("woodcutter_radius"), false, self:GetCaster())
end

modifier_item_quelling_blade_custom = class({
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
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
        }
    end,
    GetModifierPreAttack_BonusDamage = function(self)
        return self.bonus_damage
    end
})

function modifier_item_quelling_blade_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_quelling_blade_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end 
    self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
end

LinkLuaModifier("modifier_item_quelling_blade_custom", "items/item_quelling_blade", LUA_MODIFIER_MOTION_NONE, modifier_item_quelling_blade_custom)