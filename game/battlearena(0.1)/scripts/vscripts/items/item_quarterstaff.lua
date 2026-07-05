require('items/generic_datadriven_item')

item_quarterstaff_custom = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_quarterstaff_custom"
	end
})

modifier_item_quarterstaff_custom = class({
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
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
        }
    end,
	GetModifierPreAttack_BonusDamage = function(self)
		return self.bonus_damage
	end,
	GetModifierAttackSpeedBonus_Constant = function(self)
		return self.bonus_attack_speed
	end
})

function modifier_item_quarterstaff_custom:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_quarterstaff_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end 
    self.bonus_attack_speed = self.ability:GetSpecialValueFor("bonus_speed")
    self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
end

LinkLuaModifier("modifier_item_quarterstaff_custom", "items/item_quarterstaff", LUA_MODIFIER_MOTION_NONE, modifier_item_quarterstaff_custom)