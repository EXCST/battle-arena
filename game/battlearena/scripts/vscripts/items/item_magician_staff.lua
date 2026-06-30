require('items/generic_datadriven_item')

item_magician_staff = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_magician_staff"
    end
})

item_magician_staff_1 = class(item_magician_staff)
item_magician_staff_2 = class(item_magician_staff)
item_magician_staff_3 = class(item_magician_staff)

modifier_item_magician_staff = class({
    IsHidden  = function() 
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
        return 
        {
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
            MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
	    }
    end
})

function modifier_item_magician_staff:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_magician_staff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_int = self:GetAbility():GetSpecialValueFor("bonus_int")
    self.bonus_mp_regen = self:GetAbility():GetSpecialValueFor("bonus_mp_regen")
    self.magic_amplify_pct = self:GetAbility():GetSpecialValueFor("magic_amplify_pct")
end

function modifier_item_magician_staff:GetModifierBonusStats_Intellect()
    return self.bonus_int
end

function modifier_item_magician_staff:GetModifierConstantManaRegen()
    return self.bonus_mp_regen
end

function modifier_item_magician_staff:GetModifierSpellAmplify_Percentage()
    return self.magic_amplify_pct
end

LinkLuaModifier("modifier_item_magician_staff", "items/item_magician_staff", LUA_MODIFIER_MOTION_NONE, modifier_item_magician_staff)