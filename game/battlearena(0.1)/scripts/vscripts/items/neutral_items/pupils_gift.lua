item_pupils_gift_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_pupils_gift_custom"
    end
})

modifier_item_pupils_gift_custom = class({
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
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
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

function modifier_item_pupils_gift_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self:SetHasCustomTransmitterData(true)
    self:StartIntervalThink(0.2)
end

function modifier_item_pupils_gift_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusSecondaryAttribute = self.ability:GetSpecialValueFor("secondary_stats")
end

function modifier_item_pupils_gift_custom:OnIntervalThink()
    self._previousPrimary = self._previousPrimary or DOTA_ATTRIBUTE_INVALID
    local primary = self.parent:GetPrimaryAttribute()
    if(self._previousPrimary == primary) then
        return
    end
    self.bonusStrength = self.bonusSecondaryAttribute
    self.bonusAgility = self.bonusSecondaryAttribute
    self.bonusIntellect = self.bonusSecondaryAttribute
    if(primary == DOTA_ATTRIBUTE_STRENGTH) then
        self.bonusStrength = 0
    end
    if(primary == DOTA_ATTRIBUTE_AGILITY) then
        self.bonusAgility = 0
    end
    if(primary == DOTA_ATTRIBUTE_INTELLECT) then
        self.bonusIntellect = 0
    end
    self._previousPrimary = primary
    self:SendBuffRefreshToClients()
end

function modifier_item_pupils_gift_custom:AddCustomTransmitterData()
    return
    {
        bonusStrength = self.bonusStrength,
        bonusAgility = self.bonusAgility,
        bonusIntellect = self.bonusIntellect
    }
end

function modifier_item_pupils_gift_custom:HandleCustomTransmitterData(data)
    self.bonusStrength = data.bonusStrength
    self.bonusAgility = data.bonusAgility
    self.bonusIntellect = data.bonusIntellect
end

LinkLuaModifier("modifier_item_pupils_gift_custom", "items/neutral_items/pupils_gift", LUA_MODIFIER_MOTION_NONE, modifier_item_pupils_gift_custom)