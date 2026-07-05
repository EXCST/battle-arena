require('items/generic_datadriven_item')

item_magic_crit = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_magic_crit"
    end
})

item_primal_magic = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_primal_magic"
    end
})

item_imaginarium_1 = class(item_magic_crit)
item_imaginarium_2 = class(item_magic_crit)
item_imaginarium_3 = class(item_magic_crit)

item_bloom_of_luck_1 = class(item_magic_crit)
item_bloom_of_luck_2 = class(item_magic_crit)
item_bloom_of_luck_3 = class(item_magic_crit)

item_primal_magic_1 = class(item_primal_magic)
item_primal_magic_2 = class(item_primal_magic)
item_primal_magic_3 = class(item_primal_magic)

modifier_item_magic_crit = class({
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

function modifier_item_magic_crit:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_magic_crit:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_int = self.ability:GetSpecialValueFor("bonus_int")
    self.magic_crit_chance = self.ability:GetSpecialValueFor("magic_crit_chance")
    self.magic_crit_multiplier = self.ability:GetSpecialValueFor("magic_crit_multiplier")
end

function modifier_item_magic_crit:GetModifierBonusStats_Intellect()
    return self.bonus_int
end

function modifier_item_magic_crit:GetSpellCritDamage()
    return self.magic_crit_multiplier / 100
end

function modifier_item_magic_crit:GetModifierPreSpell_CriticalStrike()
    if(RollPercentage(self.magic_crit_chance) == false) then
        return
    end
    return self.magic_crit_multiplier
end

modifier_item_primal_magic = class({
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

function modifier_item_primal_magic:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_primal_magic:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_int = self.ability:GetSpecialValueFor("bonus_int")
    self.magic_crit_chance = self.ability:GetSpecialValueFor("magic_crit_chance")
    self.magic_crit_multiplier = self.ability:GetSpecialValueFor("magic_crit_multiplier")

    self.threshold_pct = self.ability:GetSpecialValueFor("threshold_pct")
    self.threshold_chance_bonus = self.ability:GetSpecialValueFor("threshold_chance_bonus")
end

function modifier_item_primal_magic:GetModifierBonusStats_Intellect()
    return self.bonus_int
end

function modifier_item_primal_magic:GetSpellCritDamage()
    return self.magic_crit_multiplier / 100
end

function modifier_item_primal_magic:GetModifierPreSpell_CriticalStrike(data)
    if data.target:GetHealthPercent() <= self.threshold_pct then
        if(RollPercentage(self.magic_crit_chance + self.threshold_chance_bonus) == false) then
            return
        end
    elseif(RollPercentage(self.magic_crit_chance) == false) then
            return
    end
    
    return self.magic_crit_multiplier
end

LinkLuaModifier("modifier_item_magic_crit", "items/item_magic_crit", LUA_MODIFIER_MOTION_NONE, modifier_item_magic_crit)
LinkLuaModifier("modifier_item_primal_magic", "items/item_magic_crit", LUA_MODIFIER_MOTION_NONE, modifier_item_primal_magic)
