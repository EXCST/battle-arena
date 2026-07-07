require('items/generic_datadriven_item')

item_captain_hat = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_captain_hat_aura"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("aura_radius")
    end
})

item_captain_hat = class({})

function item_captain_hat:GetIntrinsicModifierName()
    return "modifier_item_captain_hat_aura"
end

function item_captain_hat:GetCastRange()
    return self:GetSpecialValueFor("aura_radius")
end

item_captain_hat_1 = class(item_captain_hat)
item_captain_hat_2 = class(item_captain_hat)
item_captain_hat_3 = class(item_captain_hat)

modifier_item_captain_hat_aura = class({
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
        return "modifier_item_captain_hat_aura_buff" 
    end,
	DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end
})

function modifier_item_captain_hat_aura:OnCreated()
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

function modifier_item_captain_hat_aura:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.aura_radius = self.ability:GetSpecialValueFor("aura_radius")
end

function modifier_item_captain_hat_aura:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_captain_hat_aura:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_captain_hat_aura:GetModifierBonusStats_Intellect()
    return self.bonus_allstats
end

function modifier_item_captain_hat_aura:GetModifierBonusHealth()
	return self.bonus_health
end

modifier_item_captain_hat_aura_buff = class({
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
            MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end
})

function modifier_item_captain_hat_aura_buff:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self:OnRefresh()
end

function modifier_item_captain_hat_aura_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.aura_magic_resist_pct = self.ability:GetSpecialValueFor("aura_magic_resist_pct")
end

function modifier_item_captain_hat_aura_buff:GetModifierMagicalResistanceBonus()
    return self.aura_magic_resist_pct
end

LinkLuaModifier("modifier_item_captain_hat_aura", "items/item_captain_hat", LUA_MODIFIER_MOTION_NONE, modifier_item_captain_hat_aura)
LinkLuaModifier("modifier_item_captain_hat_aura_buff", "items/item_captain_hat", LUA_MODIFIER_MOTION_NONE, modifier_item_captain_hat_aura_buff)
