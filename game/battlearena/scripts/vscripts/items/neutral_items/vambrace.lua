item_vambrace_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_vambrace_custom"
    end
})

function item_vambrace_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local modifier = self:GetModifier()
    modifier:SwitchAttribute()
end

function item_vambrace_custom:GetModifier()
    return self._modifier
end

function item_vambrace_custom:SetModifier(modifier)
    self._modifier = modifier
end

function item_vambrace_custom:GetAbilityTextureName()
    local caster = self:GetCaster()
    local stacks = caster:GetModifierStackCount(self:GetIntrinsicModifierName(), caster)
    if(stacks == DOTA_ATTRIBUTE_AGILITY) then
        return "vambrace_agi"
    end
    if(stacks == DOTA_ATTRIBUTE_INTELLECT) then
        return "vambrace_int"
    end
    return "vambrace"
end

modifier_item_vambrace_custom = class({
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
            MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
            MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
        }
    end,
    GetModifierBonusStats_Strength = function(self)
        return self.bonusStrength
    end,
    GetModifierBonusStats_Agility = function(self)
        return self.bonusAgility
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.bonusIntellect
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_vambrace_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.ability:SetModifier(self)
    self:SetHasCustomTransmitterData(true)
    self:StartIntervalThink(0.2)
end

function modifier_item_vambrace_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusPrimaryAttribute = self.ability:GetSpecialValueFor("bonus_primary_stat")
    self.bonusSecondaryAttribute = self.ability:GetSpecialValueFor("bonus_secondary_stat")
    self.bonusSpellAmplification = self.ability:GetSpecialValueFor("bonus_spell_amp")
    self.bonusSpellResistance = self.ability:GetSpecialValueFor("bonus_magic_resistance")
    self.bonusAttackSpeed = self.ability:GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_vambrace_custom:SetAttribute(value)
    self:SetStackCount(value)
end

function modifier_item_vambrace_custom:GetAttribute()
    return self:GetStackCount()
end

function modifier_item_vambrace_custom:SwitchAttribute()
    local attribute = self:GetAttribute()
    if(attribute == DOTA_ATTRIBUTE_STRENGTH) then
        self:SetAttribute(DOTA_ATTRIBUTE_AGILITY)
    end
    if(attribute == DOTA_ATTRIBUTE_AGILITY) then
        self:SetAttribute(DOTA_ATTRIBUTE_INTELLECT)
    end
    if(attribute == DOTA_ATTRIBUTE_INTELLECT) then
        self:SetAttribute(DOTA_ATTRIBUTE_STRENGTH)
    end
end

function modifier_item_vambrace_custom:OnIntervalThink()
    self._previousPrimary = self._previousPrimary or DOTA_ATTRIBUTE_INVALID
    local primary = self.parent:GetPrimaryAttribute()
    if(self._previousPrimary == primary) then
        return
    end
    self.bonusStrength = self.bonusSecondaryAttribute
    self.bonusAgility = self.bonusSecondaryAttribute
    self.bonusIntellect = self.bonusSecondaryAttribute
    if(primary == DOTA_ATTRIBUTE_STRENGTH) then
        self.bonusStrength = self.bonusPrimaryAttribute
    end
    if(primary == DOTA_ATTRIBUTE_AGILITY) then
        self.bonusAgility = self.bonusPrimaryAttribute
    end
    if(primary == DOTA_ATTRIBUTE_INTELLECT) then
        self.bonusIntellect = self.bonusPrimaryAttribute
    end
    self._previousPrimary = primary
    self:SendBuffRefreshToClients()
end

function modifier_item_vambrace_custom:GetModifierMagicalResistanceBonus()
    if(self:GetAttribute() == DOTA_ATTRIBUTE_STRENGTH) then
        return self.bonusSpellResistance
    end
end

function modifier_item_vambrace_custom:GetModifierAttackSpeedBonus_Constant()
    if(self:GetAttribute() == DOTA_ATTRIBUTE_AGILITY) then
        return self.bonusAttackSpeed
    end
end

function modifier_item_vambrace_custom:GetModifierSpellAmplify_Percentage()
    if(self:GetAttribute() == DOTA_ATTRIBUTE_INTELLECT) then
        return self.bonusSpellAmplification
    end
end

function modifier_item_vambrace_custom:AddCustomTransmitterData()
    return
    {
        bonusStrength = self.bonusStrength,
        bonusAgility = self.bonusAgility,
        bonusIntellect = self.bonusIntellect
    }
end

function modifier_item_vambrace_custom:HandleCustomTransmitterData(data)
    self.bonusStrength = data.bonusStrength
    self.bonusAgility = data.bonusAgility
    self.bonusIntellect = data.bonusIntellect
end

LinkLuaModifier("modifier_item_vambrace_custom", "items/neutral_items/vambrace", LUA_MODIFIER_MOTION_NONE, modifier_item_vambrace_custom)