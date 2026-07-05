item_ambient_sorcery_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_ambient_sorcery_custom"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("radius")
    end
})

modifier_item_ambient_sorcery_custom = class({
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
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
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
        return "modifier_item_ambient_sorcery_custom_debuff"
    end,
    GetAuraDuration = function()
        return 0
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.bonusInt
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_ambient_sorcery_custom:OnCreated()
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

function modifier_item_ambient_sorcery_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusInt = self.ability:GetSpecialValueFor("bonus_int")
    self.radius = self.ability:GetSpecialValueFor("radius")
end

modifier_item_ambient_sorcery_custom_debuff = class({
    IsHidden = function() 
        return false 
    end,
    IsDebuff = function()
        return true
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
        }
    end,
    GetModifierMagicalResistanceBonus = function(self)
        return self.bonusSpellResistance
    end
})

function modifier_item_ambient_sorcery_custom_debuff:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_ambient_sorcery_custom_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusSpellResistance = self.ability:GetSpecialValueFor("magic_resistance_reduction") * -1
end

LinkLuaModifier("modifier_item_ambient_sorcery_custom", "items/neutral_items/ambient_sorcery", LUA_MODIFIER_MOTION_NONE, modifier_item_ambient_sorcery_custom)
LinkLuaModifier("modifier_item_ambient_sorcery_custom_debuff", "items/neutral_items/ambient_sorcery", LUA_MODIFIER_MOTION_NONE, modifier_item_ambient_sorcery_custom_debuff)