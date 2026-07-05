require('items/generic_datadriven_item')

item_crit_sword = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_crit_sword"
    end
})

item_spinal_sword = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_spinal_sword"
    end
})

item_crystalis_custom_1 = class(item_crit_sword)
item_crystalis_custom_2 = class(item_crit_sword)
item_crystalis_custom_3 = class(item_crit_sword)

item_daedalus_custom_1 = class(item_crit_sword)
item_daedalus_custom_2 = class(item_crit_sword)
item_daedalus_custom_3 = class(item_crit_sword)

item_spinal_sword_1 = class(item_spinal_sword)
item_spinal_sword_2 = class(item_spinal_sword)
item_spinal_sword_3 = class(item_spinal_sword)

modifier_item_crit_sword = class({
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
            MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE
        }
    end
})

function modifier_item_crit_sword:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_crit_sword:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
    self.crit_chance = self.ability:GetSpecialValueFor("crit_chance")
    self.crit_multiplier = self.ability:GetSpecialValueFor("crit_multiplier")
end

function modifier_item_crit_sword:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage
end

function modifier_item_crit_sword:GetModifierPreAttack_CriticalStrike()
    if(RollPercentage(self.crit_chance) == false) then
        return
    end
    return self.crit_multiplier
end

function modifier_item_crit_sword:GetCritDamage()
	return self.crit_multiplier / 100
end


modifier_item_spinal_sword = class({
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
            MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE
        }
    end
})

function modifier_item_spinal_sword:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_spinal_sword:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
    self.crit_chance = self.ability:GetSpecialValueFor("crit_chance")
    self.crit_multiplier = self.ability:GetSpecialValueFor("crit_multiplier")

    self.threshold_pct = self.ability:GetSpecialValueFor("threshold_pct")
    self.threshold_chance_bonus = self.ability:GetSpecialValueFor("threshold_chance_bonus")
end

function modifier_item_spinal_sword:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage
end

function modifier_item_spinal_sword:GetModifierPreAttack_CriticalStrike(data)
    if data.target:GetHealthPercent() <= self.threshold_pct then
        if(RollPercentage(self.crit_chance + self.threshold_chance_bonus) == false) then
            return
        end
    elseif(RollPercentage(self.crit_chance) == false) then
            return
    end
    
    return self.crit_multiplier
end

function modifier_item_spinal_sword:GetCritDamage()
    return self.crit_multiplier / 100
end


LinkLuaModifier("modifier_item_crit_sword", "items/item_crit_sword", LUA_MODIFIER_MOTION_NONE, modifier_item_crit_sword)
LinkLuaModifier("modifier_item_spinal_sword", "items/item_crit_sword", LUA_MODIFIER_MOTION_NONE, modifier_item_spinal_sword)