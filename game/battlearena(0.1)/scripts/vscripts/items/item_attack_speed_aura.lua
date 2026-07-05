require('items/generic_datadriven_item')

item_attack_speed_aura = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_attack_speed_aura"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("aura_radius")
    end
})

item_drums_of_endurance_custom_1 = class(item_attack_speed_aura)
item_drums_of_endurance_custom_2 = class(item_attack_speed_aura)
item_drums_of_endurance_custom_3 = class(item_attack_speed_aura)

item_disguise_hat_1 = class(item_attack_speed_aura)
item_disguise_hat_2 = class(item_attack_speed_aura)
item_disguise_hat_3 = class(item_attack_speed_aura)

item_foraged_cap_1 = class(item_attack_speed_aura)
item_foraged_cap_2 = class(item_attack_speed_aura)
item_foraged_cap_3 = class(item_attack_speed_aura)

modifier_item_attack_speed_aura = class({
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
        return "modifier_item_attack_speed_aura_buff" 
    end,
	DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        }
    end
})

function modifier_item_attack_speed_aura:OnCreated()
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

function modifier_item_attack_speed_aura:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
    self.bonus_attack_speed = self.ability:GetSpecialValueFor("bonus_attack_speed")
    self.aura_radius = self.ability:GetSpecialValueFor("aura_radius")
end

function modifier_item_attack_speed_aura:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_attack_speed_aura:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_attack_speed_aura:GetModifierBonusStats_Intellect()
    return self.bonus_allstats
end

function modifier_item_attack_speed_aura:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_attack_speed
end

modifier_item_attack_speed_aura_buff = class({
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

function modifier_item_attack_speed_aura_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self:OnRefresh()
end

function modifier_item_attack_speed_aura_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.aura_attack_speed = self.ability:GetSpecialValueFor("aura_attack_speed")
end

function modifier_item_attack_speed_aura_buff:GetModifierAttackSpeedBonus_Constant()
    return self.aura_attack_speed
end

LinkLuaModifier("modifier_item_attack_speed_aura", "items/item_attack_speed_aura", LUA_MODIFIER_MOTION_NONE, modifier_item_attack_speed_aura)
LinkLuaModifier("modifier_item_attack_speed_aura_buff", "items/item_attack_speed_aura", LUA_MODIFIER_MOTION_NONE, modifier_item_attack_speed_aura_buff)