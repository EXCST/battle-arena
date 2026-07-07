item_ring_of_aquila_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_ring_of_aquila_custom"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("aura_radius")
    end
})

modifier_item_ring_of_aquila_custom = class({
    IsHidden = function() 
        return true 
    end,
    IsDebuff = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        }
    end,
    IsAuraActiveOnDeath = function()
        return false
    end,
    GetAuraRadius = function(self)
        return self.radius
    end,
    GetAuraSearchFlags = function(self)
        return self.targetFlags
    end,
    GetAuraSearchTeam = function(self)
        return self.targetTeam
    end,
    IsAura = function()
        return true
    end,
    GetAuraSearchType = function(self)
        return self.targetType
    end,
    GetModifierAura = function()
        return "modifier_item_ring_of_aquila_custom_buff"
    end,
    GetAuraDuration = function()
        return 0
    end,
    GetModifierPreAttack_BonusDamage = function(self)
        return self.bonusAttackDamage
    end,
    GetModifierBonusStats_Strength = function(self)
        return self.bonusAllStats
    end,
    GetModifierBonusStats_Agility = function(self)
        return self.bonusAllStats
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.bonusAllStats
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_ring_of_aquila_custom:OnCreated()
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

function modifier_item_ring_of_aquila_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAttackDamage = self.ability:GetSpecialValueFor("bonus_damage")
    self.bonusAllStats = self.ability:GetSpecialValueFor("bonus_allstats")
    self.radius = self.ability:GetSpecialValueFor("aura_radius")
end

modifier_item_ring_of_aquila_custom_buff = class({
    IsHidden = function() 
        return false 
    end,
    IsDebuff = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
        }
    end,
    GetModifierConstantManaRegen = function(self)
        return self.bonusManaRegeneration
    end,
    GetModifierPhysicalArmorBonus = function(self)
        return self.bonusArmor
    end
})

function modifier_item_ring_of_aquila_custom_buff:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_ring_of_aquila_custom_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusManaRegeneration = self.ability:GetSpecialValueFor("aura_mana_regen")
    self.bonusArmor = self.ability:GetSpecialValueFor("aura_bonus_armor")
end

LinkLuaModifier("modifier_item_ring_of_aquila_custom", "items/neutral_items/ring_of_aquila", LUA_MODIFIER_MOTION_NONE, modifier_item_ring_of_aquila_custom)
LinkLuaModifier("modifier_item_ring_of_aquila_custom_buff", "items/neutral_items/ring_of_aquila", LUA_MODIFIER_MOTION_NONE, modifier_item_ring_of_aquila_custom_buff)