require('items/generic_datadriven_item')

item_ring_of_basilius_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_ring_of_basilius_custom"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("aura_radius")
    end
})

modifier_item_ring_of_basilius_custom = class({
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
        return "modifier_item_ring_of_basilius_custom_aura" 
    end,
	DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        }
    end
})

function modifier_item_ring_of_basilius_custom:OnCreated()
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

function modifier_item_ring_of_basilius_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_mp_regen = self.ability:GetSpecialValueFor("bonus_mp_regen")
  
    self.aura_radius = self.ability:GetSpecialValueFor("aura_radius")    
    self.aura_armor = self.ability:GetSpecialValueFor("aura_armor")
    self.aura_mp_regen = self.ability:GetSpecialValueFor("aura_mp_regen")
end

function modifier_item_ring_of_basilius_custom:GetModifierConstantManaRegen()
    return self.bonus_mp_regen
end

modifier_item_ring_of_basilius_custom_aura = class({
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
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        }
    end
})

function modifier_item_ring_of_basilius_custom_aura:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self:OnRefresh()
end

function modifier_item_ring_of_basilius_custom_aura:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.aura_armor = self.ability:GetSpecialValueFor("aura_armor")
    self.aura_mp_regen = self.ability:GetSpecialValueFor("aura_mp_regen")
end

function modifier_item_ring_of_basilius_custom_aura:GetModifierPhysicalArmorBonus()
    return self.aura_armor
end

function modifier_item_ring_of_basilius_custom_aura:GetModifierConstantManaRegen()
    return self.aura_mp_regen
end

LinkLuaModifier("modifier_item_ring_of_basilius_custom", "items/item_ring_of_basilius_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_ring_of_basilius_custom)
LinkLuaModifier("modifier_item_ring_of_basilius_custom_aura", "items/item_ring_of_basilius_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_ring_of_basilius_custom_aura)