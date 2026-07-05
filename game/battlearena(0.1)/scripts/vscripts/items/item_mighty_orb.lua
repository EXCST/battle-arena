require('items/generic_datadriven_item')

item_mighty_orb = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_mighty_orb"
    end
})

modifier_item_mighty_orb = class({
	IsHidden = function() 
        return true 
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
	DeclareFunctions  = function() 
        return 
        {
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
            MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_PRESPELL_CRITICALSTRIKE
	    }
    end,
    GetAttributes = function()
        return MODIFIER_ATTRIBUTE_MULTIPLE
    end
})

function modifier_item_mighty_orb:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_mighty_orb:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_int = self.ability:GetSpecialValueFor("bonus_int")
    self.bonus_mp_regen = self.ability:GetSpecialValueFor("bonus_mp_regen")
    self.magic_amplify_pct = self.ability:GetSpecialValueFor("magic_amplify_pct")
    self.magic_crit_chance = self.ability:GetSpecialValueFor("magic_crit_chance")
    self.magic_crit_multiplier = self.ability:GetSpecialValueFor("magic_crit_multiplier")
end

function modifier_item_mighty_orb:GetModifierBonusStats_Intellect()
    return self.bonus_int
end

function modifier_item_mighty_orb:GetModifierConstantManaRegen()
    return self.bonus_mp_regen
end

function modifier_item_mighty_orb:GetModifierSpellAmplify_Percentage()
    return self.magic_amplify_pct
end

function modifier_item_mighty_orb:GetSpellCritDamage()
    return self.magic_crit_multiplier / 100
end

function modifier_item_mighty_orb:GetModifierPreSpell_CriticalStrike()
    if(RollPercentage(self.magic_crit_chance) == false) then
        return
    end
    return self.magic_crit_multiplier
end

LinkLuaModifier("modifier_item_mighty_orb", "items/item_mighty_orb", LUA_MODIFIER_MOTION_NONE, modifier_item_mighty_orb)