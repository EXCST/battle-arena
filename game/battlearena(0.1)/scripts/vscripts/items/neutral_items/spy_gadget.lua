item_spy_gadget_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_spy_gadget_custom"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("aura_range")
    end
})

modifier_item_spy_gadget_custom = class({
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
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        }
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
        return "modifier_item_spy_gadget_custom_buff"
    end,
    GetAuraDuration = function()
        return 0
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_spy_gadget_custom:OnCreated()
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

function modifier_item_spy_gadget_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAllStats = self.ability:GetSpecialValueFor("bonus_allstats")
    self.radius = self.ability:GetCastRange()
end

modifier_item_spy_gadget_custom_buff = class({
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
            MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
            MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING
        }
    end,
    GetModifierAttackRangeBonus = function(self)
        return self.bonusAttackRange
    end,
    GetModifierCastRangeBonusStacking = function(self)
        return self.bonusCastRange
    end
})

function modifier_item_spy_gadget_custom_buff:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self:StartIntervalThink(0.2)
    self:SetHasCustomTransmitterData(true)
end

function modifier_item_spy_gadget_custom_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAttackRangeRanged = self.ability:GetSpecialValueFor("attack_range")
    self.bonusCastRange = self.ability:GetSpecialValueFor("cast_range")
end

function modifier_item_spy_gadget_custom_buff:OnIntervalThink()
    self._previousAttackCapability = DOTA_UNIT_CAP_NO_ATTACK
    local attackCapability = self.parent:GetAttackCapability()
    if(self._previousAttackCapability == attackCapability) then
        return
    end
    if(self.parent:GetAttackCapability() == DOTA_UNIT_CAP_RANGED_ATTACK) then
        self.bonusAttackRange = self.bonusAttackRangeRanged
    else
        self.bonusAttackRange = 0
    end
    self:SendBuffRefreshToClients()
    self._previousAttackCapability = attackCapability
end

function modifier_item_spy_gadget_custom_buff:AddCustomTransmitterData()
    return
    {
        bonusAttackRange = self.bonusAttackRange
    }
end

function modifier_item_spy_gadget_custom_buff:HandleCustomTransmitterData(data)
    self.bonusAttackRange = data.bonusAttackRange
end

LinkLuaModifier("modifier_item_spy_gadget_custom", "items/neutral_items/spy_gadget", LUA_MODIFIER_MOTION_NONE, modifier_item_spy_gadget_custom)
LinkLuaModifier("modifier_item_spy_gadget_custom_buff", "items/neutral_items/spy_gadget", LUA_MODIFIER_MOTION_NONE, modifier_item_spy_gadget_custom_buff)