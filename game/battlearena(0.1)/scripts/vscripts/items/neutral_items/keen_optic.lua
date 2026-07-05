item_keen_optic_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_keen_optic_custom"
    end
})

modifier_item_keen_optic_custom = class({
    IsHidden = function() 
        return true 
    end,
    IsDebuff = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions = function() 
        return {
			MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
        }
    end,
    GetModifierCastRangeBonusStacking = function(self)
        return self.bonusCastRange
    end,
    GetModifierConstantManaRegen = function(self)
        return self.bonusManaRegen
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_keen_optic_custom:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_keen_optic_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusCastRange = self.ability:GetSpecialValueFor("cast_range_bonus")
    self.bonusManaRegen = self.ability:GetSpecialValueFor("bonus_mana_regen")
end

LinkLuaModifier("modifier_item_keen_optic_custom", "items/neutral_items/keen_optic", LUA_MODIFIER_MOTION_NONE, modifier_item_keen_optic_custom)
