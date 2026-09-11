require('items/generic_datadriven_item')

item_damage_aura = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_damage_aura"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("aura_radius")
    end
})

item_wine_jovel_1 = class(item_damage_aura)
item_wine_jovel_2 = class(item_damage_aura)
item_wine_jovel_3 = class(item_damage_aura)

item_fulish_barrel_1 = class(item_damage_aura)
item_fulish_barrel_2 = class(item_damage_aura)
item_fulish_barrel_3 = class(item_damage_aura)

item_little_vagabo_1 = class(item_damage_aura)
item_little_vagabo_2 = class(item_damage_aura)
item_little_vagabo_3 = class(item_damage_aura)

modifier_item_damage_aura = class({
    IsHidden = function() 
        return true 
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    IsAura = function() 
        return true 
    end,
    GetAuraRadius = function(self) 
        return self.aura_radius
    end,
    GetAuraSearchTeam = function(self) 
        return self.targetTeam
    end,
    GetAuraSearchType = function(self) 
        return self.targetType
    end,
    GetAuraSearchFlags = function(self)
        return self.targetFlags
    end,
    GetModifierAura = function() 
        return "modifier_item_damage_aura_buff" 
    end,
	DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
        }
    end
})

function modifier_item_damage_aura:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.targetTeam = self.ability:GetAbilityTargetTeam()
    self.targetType = self.ability:GetAbilityTargetType()
    self.targetFlags = self.ability:GetAbilityTargetFlags()
end

function modifier_item_damage_aura:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
    self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
    self.aura_radius = self.ability:GetSpecialValueFor("aura_radius")
    self.aura_damage_pct = self.ability:GetSpecialValueFor("aura_damage_pct")
end

function modifier_item_damage_aura:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_damage_aura:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_damage_aura:GetModifierBonusStats_Intellect()
    return self.bonus_allstats
end

function modifier_item_damage_aura:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage
end


modifier_item_damage_aura_buff = class({
    IsHidden = function() 
        return false 
    end,
    IsPurgable = function()
        return false
    end,
    IsDebuff = function()
        return false    
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions  = function() 
        return 
        {
            MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
        }
    end
})

function modifier_item_damage_aura_buff:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self:OnRefresh()
end

function modifier_item_damage_aura_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.aura_damage_pct = self.ability:GetSpecialValueFor("aura_damage_pct")
end

function modifier_item_damage_aura_buff:GetModifierBaseDamageOutgoing_Percentage()
    return self.aura_damage_pct
end

LinkLuaModifier("modifier_item_damage_aura", "items/item_damage_aura", LUA_MODIFIER_MOTION_NONE, modifier_item_damage_aura)
LinkLuaModifier("modifier_item_damage_aura_buff", "items/item_damage_aura", LUA_MODIFIER_MOTION_NONE, modifier_item_damage_aura_buff)



