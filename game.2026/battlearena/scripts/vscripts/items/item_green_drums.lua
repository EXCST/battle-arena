require('items/generic_datadriven_item')

item_green_drums = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_green_drums_aura"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("aura_radius")
    end
})

item_green_drums_1 = class(item_green_drums)
item_green_drums_2 = class(item_green_drums)
item_green_drums_3 = class(item_green_drums)

modifier_item_green_drums_aura = class({
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
        return "modifier_item_green_drums_aura_buff" 
    end,
	DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
        }
    end
})

function modifier_item_green_drums_aura:OnCreated()
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

function modifier_item_green_drums_aura:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
    self.aura_radius = self.ability:GetSpecialValueFor("aura_radius")
end

function modifier_item_green_drums_aura:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_green_drums_aura:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_green_drums_aura:GetModifierBonusStats_Intellect()
    return self.bonus_allstats
end

modifier_item_green_drums_aura_buff = class({
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
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
        }
    end
})

function modifier_item_green_drums_aura_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self:OnRefresh()
end

function modifier_item_green_drums_aura_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.aura_attack_speed = self.ability:GetSpecialValueFor("aura_attack_speed")
end

function modifier_item_green_drums_aura_buff:GetModifierAttackSpeedBonus_Constant()
    return self.aura_attack_speed
end

LinkLuaModifier("modifier_item_green_drums_aura", "items/item_green_drums", LUA_MODIFIER_MOTION_NONE, modifier_item_green_drums_aura)
LinkLuaModifier("modifier_item_green_drums_aura_buff", "items/item_green_drums", LUA_MODIFIER_MOTION_NONE, modifier_item_green_drums_aura_buff)