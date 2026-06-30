require('items/generic_datadriven_item')

item_captain_flag = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_captain_flag_aura"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("aura_radius")
    end
})

item_captain_flag_1 = class(item_captain_flag)
item_captain_flag_2 = class(item_captain_flag)
item_captain_flag_3 = class(item_captain_flag)

modifier_item_captain_flag_aura = class({
    IsHidden = function() 
        return true 
    end,
    IsAura = function() 
        return true 
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
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
        return "modifier_item_captain_flag_aura_buff" 
    end,
	DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
        }
    end
})

function modifier_item_captain_flag_aura:OnCreated()
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

function modifier_item_captain_flag_aura:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
    self.bonus_armor = self.ability:GetSpecialValueFor("bonus_armor")
    self.aura_radius = self.ability:GetSpecialValueFor("aura_radius")
    self.aura_armor = self.ability:GetSpecialValueFor("aura_armor")
    self.aura_radius = self.ability:GetSpecialValueFor("aura_radius")
end

function modifier_item_captain_flag_aura:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_captain_flag_aura:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_captain_flag_aura:GetModifierBonusStats_Intellect()
    return self.bonus_allstats
end

function modifier_item_captain_flag_aura:GetModifierPhysicalArmorBonus()
    return self.bonus_armor
end

modifier_item_captain_flag_aura_buff = class({
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
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
        }
    end
})

function modifier_item_captain_flag_aura_buff:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self:OnRefresh()
end

function modifier_item_captain_flag_aura_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.aura_armor = self.ability:GetSpecialValueFor("aura_armor")
end

function modifier_item_captain_flag_aura_buff:GetModifierPhysicalArmorBonus()
    return self.aura_armor
end

LinkLuaModifier("modifier_item_captain_flag_aura", "items/item_captain_flag", LUA_MODIFIER_MOTION_NONE, modifier_item_captain_flag_aura)
LinkLuaModifier("modifier_item_captain_flag_aura_buff", "items/item_captain_flag", LUA_MODIFIER_MOTION_NONE, modifier_item_captain_flag_aura_buff)