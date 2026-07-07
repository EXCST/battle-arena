item_apex_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_apex_custom"
    end
})

modifier_item_apex_custom = class({
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
            MODIFIER_PROPERTY_ROSHDEF_STATS_STRENGTH_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_STATS_AGILITY_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_STATS_INTELLECT_BONUS_PERCENTAGE
        }
    end,
    GetModifierBonusStats_Strength = function(self)
        return self.bonusAllStats + self.bonusStr
    end,
    GetModifierBonusStats_Agility = function(self)
        return self.bonusAllStats + self.bonusAgi
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.bonusAllStats + self.bonusInt
    end,
    GetModifierBonusStats_Strength_Percentage = function(self)
        return self.bonusStrPct
    end,
    GetModifierBonusStats_Agility_Percentage = function(self)
        return self.bonusAgiPct
    end,
    GetModifierBonusStats_Intellect_Percentage = function(self)
        return self.bonusIntPct
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_apex_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self.bonusStr = 0
    self.bonusAgi = 0
    self.bonusInt = 0
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self:SetHasCustomTransmitterData(true)
    self:StartIntervalThink(0.2)
end

function modifier_item_apex_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAllStats = self.ability:GetSpecialValueFor("bonus_allstats")
    self.primaryBonusPct = self.ability:GetSpecialValueFor("primary_stat_bonus_tooltip") / 100
    self.secondaryBonusPct = self.ability:GetSpecialValueFor("secondary_stats_reduction_pct") * -1
end

function modifier_item_apex_custom:OnIntervalThink()
    if(not self.parent.GetPrimaryAttribute) then
        return
    end
    self:SetStackCount(self.parent:GetPrimaryAttribute())
    local primary = self.parent:GetPrimaryAttribute()
    self.bonusStrPct = 0
    self.bonusAgiPct = 0
    self.bonusIntPct = 0
    if(primary == DOTA_ATTRIBUTE_STRENGTH) then
        self.bonusStrPct = 0
        self.bonusAgiPct = self.secondaryBonusPct
        self.bonusIntPct = self.secondaryBonusPct
        self.bonusStr = (self.parent:GetAgility() + self.parent:GetPrimaryStatValue()) * self.primaryBonusPct
        self.bonusAgi = 0
        self.bonusInt = 0
    end
    if(primary == DOTA_ATTRIBUTE_AGILITY) then
        self.bonusStrPct = self.secondaryBonusPct
        self.bonusAgiPct = 0
        self.bonusIntPct = self.secondaryBonusPct
        self.bonusStr = 0
        self.bonusAgi = (self.parent:GetStrength() + self.parent:GetPrimaryStatValue()) * self.primaryBonusPct
        self.bonusInt = 0
    end
    if(primary == DOTA_ATTRIBUTE_INTELLECT) then
        self.bonusStrPct = self.secondaryBonusPct
        self.bonusAgiPct = self.secondaryBonusPct
        self.bonusIntPct = 0
        self.bonusStr = 0
        self.bonusAgi = 0
        self.bonusInt = (self.parent:GetStrength() + self.parent:GetAgility()) * self.primaryBonusPct
    end
    self:SendBuffRefreshToClients()
    self.parent:CalculateStatBonus(true)
end

function modifier_item_apex_custom:AddCustomTransmitterData()
    return
    {
        bonusStr = self.bonusStr,
        bonusAgi = self.bonusAgi,
        bonusInt = self.bonusInt
    }
end

function modifier_item_apex_custom:HandleCustomTransmitterData(data)
    for k,v in pairs(data) do
        self[k] = v
    end
end

LinkLuaModifier("modifier_item_apex_custom", "items/neutral_items/apex", LUA_MODIFIER_MOTION_NONE, modifier_item_apex_custom)