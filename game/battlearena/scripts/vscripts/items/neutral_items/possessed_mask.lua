item_possessed_mask_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_possessed_mask_custom"
    end
})

modifier_item_possessed_mask_custom = class({
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
            MODIFIER_EVENT_ON_ATTACK_LANDED,
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        }
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_possessed_mask_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.targetTeam = self.ability:GetAbilityTargetTeam()
	self.targetType = self.ability:GetAbilityTargetType()
	self.targetFlags = self.ability:GetAbilityTargetFlags()
    self:StartIntervalThink(0.2)
end

function modifier_item_possessed_mask_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusPrimaryAttribute = self.ability:GetSpecialValueFor("primary_attribute")
    self.bonusLifesteal = self.ability:GetSpecialValueFor("lifesteal")
end

function modifier_item_possessed_mask_custom:OnIntervalThink()
    if(not self.parent.GetPrimaryAttribute) then
        return
    end
    self:SetStackCount(self.parent:GetPrimaryAttribute())
end

function modifier_item_possessed_mask_custom:OnAttackLanded(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    if(UnitFilter(kv.target, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    self.parent:PerformLifesteal(kv.target, self.bonusLifesteal)
end

function modifier_item_possessed_mask_custom:GetModifierBonusStats_Strength()
    if(self.parent:IsRealHero() == false) then
        return
    end
    if(self:GetStackCount() == DOTA_ATTRIBUTE_STRENGTH) then
        return self.bonusPrimaryAttribute
    end
    return 0
end

function modifier_item_possessed_mask_custom:GetModifierBonusStats_Agility()
    if(self.parent:IsRealHero() == false) then
        return
    end
    if(self:GetStackCount() == DOTA_ATTRIBUTE_AGILITY) then
        return self.bonusPrimaryAttribute
    end
    return 0
end

function modifier_item_possessed_mask_custom:GetModifierBonusStats_Intellect()
    if(self.parent:IsRealHero() == false) then
        return
    end
    if(self:GetStackCount() == DOTA_ATTRIBUTE_INTELLECT) then
        return self.bonusPrimaryAttribute
    end
    return 0
end

LinkLuaModifier("modifier_item_possessed_mask_custom", "items/neutral_items/possessed_mask", LUA_MODIFIER_MOTION_NONE, modifier_item_possessed_mask_custom)