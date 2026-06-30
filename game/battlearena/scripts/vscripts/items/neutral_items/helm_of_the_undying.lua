item_helm_of_the_undying_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_helm_of_the_undying_custom"
    end
})

modifier_item_helm_of_the_undying_custom = class({
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
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
            MODIFIER_EVENT_ON_DEATH
        }
    end,
    GetModifierBonusStats_Strength = function(self)
        return self.bonusStr
    end,
    GetModifierPhysicalArmorBonus = function(self)
        return self.bonusArmor
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_helm_of_the_undying_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_helm_of_the_undying_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusStr = self.ability:GetSpecialValueFor("bonus_strength")
    self.bonusArmor = self.ability:GetSpecialValueFor("bonus_armor")
    self.ressurectionTime = self.ability:GetSpecialValueFor("resurrection_time")
    self.ressurectionCastRange = self.ability:GetSpecialValueFor("resurrection_cast_range")
end

function modifier_item_helm_of_the_undying_custom:OnDeath(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    if(kv.unit:IsRealHero() == false) then
        return
    end
    CustomTombstone:CreateForPlayer(self.parent:GetPlayerOwnerID(), self.ressurectionTime, self.ressurectionCastRange)
end

LinkLuaModifier("modifier_item_helm_of_the_undying_custom", "items/neutral_items/helm_of_the_undying", LUA_MODIFIER_MOTION_NONE, modifier_item_helm_of_the_undying_custom)