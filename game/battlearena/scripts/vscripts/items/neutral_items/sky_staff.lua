item_sky_staff = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_sky_staff"
    end
})

modifier_item_sky_staff = class({
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
            MODIFIER_PROPERTY_ROSHDEF_TOTALDAMAGEOUTGOING_CONSTANT,
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        }
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_sky_staff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self:StartIntervalThink(0.2)
end

function modifier_item_sky_staff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusPrimaryAttribute = self.ability:GetSpecialValueFor("bonus_primary_attribute")
    self.bonusAbilityDamage = self.ability:GetSpecialValueFor("ability_damage")
end

function modifier_item_sky_staff:OnIntervalThink()
    if(not self.parent.GetPrimaryAttribute) then
        return
    end
    self:SetStackCount(self.parent:GetPrimaryAttribute())
end

function modifier_item_sky_staff:GetModifierTotalDamageOutgoing_Constant(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    if(self.ability:IsCooldownReady() == false) then
        return
    end
    if(kv.inflictor == nil) then
        return
    end
    self.ability:UseResources(true, false, true, true)
    return self.bonusAbilityDamage
end

function modifier_item_sky_staff:GetModifierBonusStats_Strength()
    if(self.parent:IsRealHero() == false) then
        return
    end
    if(self:GetStackCount() == DOTA_ATTRIBUTE_STRENGTH) then
        return self.bonusPrimaryAttribute
    end
    return 0
end

function modifier_item_sky_staff:GetModifierBonusStats_Agility()
    if(self.parent:IsRealHero() == false) then
        return
    end
    if(self:GetStackCount() == DOTA_ATTRIBUTE_AGILITY) then
        return self.bonusPrimaryAttribute
    end
    return 0
end

function modifier_item_sky_staff:GetModifierBonusStats_Intellect()
    if(self.parent:IsRealHero() == false) then
        return
    end
    if(self:GetStackCount() == DOTA_ATTRIBUTE_INTELLECT) then
        return self.bonusPrimaryAttribute
    end
    return 0
end

LinkLuaModifier("modifier_item_sky_staff", "items/neutral_items/sky_staff", LUA_MODIFIER_MOTION_NONE, modifier_item_sky_staff)