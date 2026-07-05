item_cloack_of_the_bear_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_cloack_of_the_bear_custom"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("aura_radius")
    end
})

modifier_item_cloack_of_the_bear_custom = class({
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
            MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS
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
        return "modifier_item_cloack_of_the_bear_custom_buff"
    end,
    GetAuraDuration = function()
        return 0
    end,
    GetModifierMagicalResistanceBonus = function(self)
        return self.bonusSpellResistance
    end,
    GetModifierBonusStats_Strength = function(self)
        return self.bonusStr
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_cloack_of_the_bear_custom:OnCreated()
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

function modifier_item_cloack_of_the_bear_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusSpellResistance = self.ability:GetSpecialValueFor("self_magical_res_pct")
    self.bonusStr = self.ability:GetSpecialValueFor("bonus_strength")
    self.radius = self.ability:GetSpecialValueFor("aura_radius")
end

modifier_item_cloack_of_the_bear_custom_buff = class({
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
            MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
        }
    end,
    GetModifierMagicalResistanceBonus = function(self)
        return self.bonusSpellResistance
    end
})

function modifier_item_cloack_of_the_bear_custom_buff:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_cloack_of_the_bear_custom_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusSpellResistance = self.ability:GetSpecialValueFor("aura_magical_res_pct")
end

LinkLuaModifier("modifier_item_cloack_of_the_bear_custom", "items/neutral_items/cloack_of_the_bear", LUA_MODIFIER_MOTION_NONE, modifier_item_cloack_of_the_bear_custom)
LinkLuaModifier("modifier_item_cloack_of_the_bear_custom_buff", "items/neutral_items/cloack_of_the_bear", LUA_MODIFIER_MOTION_NONE, modifier_item_cloack_of_the_bear_custom_buff)