require('items/generic_datadriven_item')

item_ring_of_aquila_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_ring_of_aquila_custom"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("aura_radius")
    end
})

function item_ring_of_aquila_custom:GetAbilityTextureName()
    local caster = self:GetCaster()

    if caster:HasModifier("modifier_item_ring_of_aquila_custom_1") then
        return "new/ring_of_aquila_str"
    elseif caster:HasModifier("modifier_item_ring_of_aquila_custom_2") then
        return "new/ring_of_aquila_agi"
    elseif caster:HasModifier("modifier_item_ring_of_aquila_custom_3") then
        return "new/ring_of_aquila_int"
    end    

    return "new/ring_of_aquila_custom"
end

function item_ring_of_aquila_custom:OnSpellStart() 
    local caster = self:GetCaster()
    
    if caster:HasModifier("modifier_item_ring_of_aquila_custom_1") then
        caster:RemoveModifierByName("modifier_item_ring_of_aquila_custom_1")
        caster:AddNewModifier(caster, self, "modifier_item_ring_of_aquila_custom_2", {duration = -1})
    elseif caster:HasModifier("modifier_item_ring_of_aquila_custom_2") then
        caster:RemoveModifierByName("modifier_item_ring_of_aquila_custom_2")
        caster:AddNewModifier(caster, self, "modifier_item_ring_of_aquila_custom_3", {duration = -1})
    elseif caster:HasModifier("modifier_item_ring_of_aquila_custom_3") then
        caster:RemoveModifierByName("modifier_item_ring_of_aquila_custom_3")
        caster:AddNewModifier(caster, self, "modifier_item_ring_of_aquila_custom_1", {duration = -1})
    else caster:AddNewModifier(caster, self, "modifier_item_ring_of_aquila_custom_1", {duration = -1})
    end
end
modifier_item_ring_of_aquila_custom = class({
    GetAttributes   = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
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
        return "modifier_item_ring_of_aquila_custom_aura" 
    end,
	DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        }
    end
})

function modifier_item_ring_of_aquila_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.parent:AddNewModifier(self.parent, self, "modifier_item_ring_of_aquila_custom_1", {duration = -1})
    self.targetTeam = self.ability:GetAbilityTargetTeam()
	self.targetType = self.ability:GetAbilityTargetType()
	self.targetFlags = self.ability:GetAbilityTargetFlags()
end

function modifier_item_ring_of_aquila_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_primary_stat = self.ability:GetSpecialValueFor("bonus_primary_stat")
    self.bonus_secondary_stat = self.ability:GetSpecialValueFor("bonus_secondary_stat")

    self.bonus_hp_regen_str = self.ability:GetSpecialValueFor("bonus_hp_regen_str")
    self.bonus_attack_speed_agi = self.ability:GetSpecialValueFor("bonus_attack_speed_agi")
    self.bonus_mp_regen_int = self.ability:GetSpecialValueFor("bonus_mp_regen_int")
    
    self.aura_radius = self.ability:GetSpecialValueFor("aura_radius")    
    self.aura_armor = self.ability:GetSpecialValueFor("aura_armor")
    self.aura_mp_regen = self.ability:GetSpecialValueFor("aura_mp_regen")
end

function modifier_item_ring_of_aquila_custom:OnDestroy()
    self.parent:RemoveModifierByName("modifier_item_ring_of_aquila_custom_1")
    self.parent:RemoveModifierByName("modifier_item_ring_of_aquila_custom_2")
    self.parent:RemoveModifierByName("modifier_item_ring_of_aquila_custom_3")
end

function modifier_item_ring_of_aquila_custom:GetModifierBonusStats_Strength()
    if self.parent:HasModifier("modifier_item_ring_of_aquila_custom_1") then
        return self.bonus_primary_stat
    else
        return self.bonus_secondary_stat
    end
end

function modifier_item_ring_of_aquila_custom:GetModifierBonusStats_Agility()
    if self.parent:HasModifier("modifier_item_ring_of_aquila_custom_2") then
        return self.bonus_primary_stat
    else
        return self.bonus_secondary_stat
    end
end

function modifier_item_ring_of_aquila_custom:GetModifierBonusStats_Intellect()
    if self.parent:HasModifier("modifier_item_ring_of_aquila_custom_3") then
        return self.bonus_primary_stat
    else
        return self.bonus_secondary_stat
    end
end

function modifier_item_ring_of_aquila_custom:GetModifierConstantHealthRegen()
    if self.parent:HasModifier("modifier_item_ring_of_aquila_custom_1") then
        return self.bonus_hp_regen_str
    else
        return 0
    end
end

function modifier_item_ring_of_aquila_custom:GetModifierAttackSpeedBonus_Constant()
    if self.parent:HasModifier("modifier_item_ring_of_aquila_custom_2") then
        return self.bonus_attack_speed_agi
    else
        return 0
    end
end

function modifier_item_ring_of_aquila_custom:GetModifierConstantManaRegen()
    if self.parent:HasModifier("modifier_item_ring_of_aquila_custom_3") then
        return self.bonus_mp_regen_int
    else
        return 0
    end
end

modifier_item_ring_of_aquila_custom_1 = class({
    IsHidden = function() 
        return true 
    end,
    IsPurgable = function() 
        return false 
    end,
})
modifier_item_ring_of_aquila_custom_2 = class({
    IsHidden = function() 
        return true 
    end,
    IsPurgable = function() 
        return false 
    end,
})
modifier_item_ring_of_aquila_custom_3 = class({
    IsHidden = function() 
        return true 
    end,
    IsPurgable = function() 
        return false 
    end,
})

modifier_item_ring_of_aquila_custom_aura = class({
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

function modifier_item_ring_of_aquila_custom_aura:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self:OnRefresh()
end

function modifier_item_ring_of_aquila_custom_aura:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.aura_armor = self.ability:GetSpecialValueFor("aura_armor")
    self.aura_mp_regen = self.ability:GetSpecialValueFor("aura_mp_regen")
end

function modifier_item_ring_of_aquila_custom_aura:GetModifierPhysicalArmorBonus()
    return self.aura_armor
end

function modifier_item_ring_of_aquila_custom_aura:GetModifierConstantManaRegen()
    return self.aura_mp_regen
end

LinkLuaModifier("modifier_item_ring_of_aquila_custom", "items/item_ring_of_aquila_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_ring_of_aquila_custom)
LinkLuaModifier("modifier_item_ring_of_aquila_custom_1", "items/item_ring_of_aquila_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_ring_of_aquila_custom_1)
LinkLuaModifier("modifier_item_ring_of_aquila_custom_2", "items/item_ring_of_aquila_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_ring_of_aquila_custom_2)
LinkLuaModifier("modifier_item_ring_of_aquila_custom_3", "items/item_ring_of_aquila_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_ring_of_aquila_custom_3)
LinkLuaModifier("modifier_item_ring_of_aquila_custom_aura", "items/item_ring_of_aquila_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_ring_of_aquila_custom_aura)