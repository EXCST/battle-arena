require('items/generic_datadriven_item')

item_magician_orb = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_magician_orb"
    end
})

item_magician_orb_1 = class(item_magician_orb)
item_magician_orb_2 = class(item_magician_orb)
item_magician_orb_3 = class(item_magician_orb)

modifier_item_magician_orb = class({
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
        return 
        {
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_ROSHDEF_PRESPELL_CRITICALSTRIKE
	    }
    end
})

function modifier_item_magician_orb:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_magician_orb:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_int = self.ability:GetSpecialValueFor("bonus_int")
    self.magic_crit_chance = self.ability:GetSpecialValueFor("magic_crit_chance")
    self.magic_crit_multiplier = self.ability:GetSpecialValueFor("magic_crit_multiplier")
end

function modifier_item_magician_orb:GetModifierBonusStats_Intellect()
    return self.bonus_int
end

function modifier_item_magician_orb:GetSpellCritDamage()
    return self.magic_crit_multiplier / 100
end

function modifier_item_magician_orb:GetModifierPreSpell_CriticalStrike()
    if(RollPercentage(self.magic_crit_chance) == false) then
        return
    end
    return self.magic_crit_multiplier
end

LinkLuaModifier("modifier_item_magician_orb", "items/item_magician_orb", LUA_MODIFIER_MOTION_NONE, modifier_item_magician_orb)