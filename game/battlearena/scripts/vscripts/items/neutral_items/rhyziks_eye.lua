item_rhyziks_eye_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_rhyziks_eye_custom"
    end
})

modifier_item_rhyziks_eye_custom = class({
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
            MODIFIER_PROPERTY_ROSHDEF_STATS_STRENGTH_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_STATS_AGILITY_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_STATS_INTELLECT_BONUS_PERCENTAGE,
            MODIFIER_EVENT_ON_TAKEDAMAGE
        }
    end,
    GetModifierBonusStats_Strength_Percentage = function(self)
        return self.bonusAllStatsPct
    end,
    GetModifierBonusStats_Agility_Percentage = function(self)
        return self.bonusAllStatsPct
    end,
    GetModifierBonusStats_Intellect_Percentage = function(self)
        return self.bonusAllStatsPct
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_rhyziks_eye_custom:OnCreated()
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

function modifier_item_rhyziks_eye_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAllStatsPct = self.ability:GetSpecialValueFor("bonus_allstats_pct")
    self.bonusPureLifestealPct = self.ability:GetSpecialValueFor("pure_lifesteal_pct") / 100
end

function modifier_item_rhyziks_eye_custom:OnTakeDamage(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    if(UnitFilter(kv.target, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    if(kv.inflictor == nil) then
        if(kv.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK) then
            self.parent:PerformLifesteal(kv.target, kv.original_damage_with_amplifications * self.bonusPureLifestealPct)
        end
        return
    end
    self.parent:PerformSpellLifesteal(kv.target, kv.inflictor, kv.original_damage_with_amplifications * self.bonusPureLifestealPct)
end

LinkLuaModifier("modifier_item_rhyziks_eye_custom", "items/neutral_items/rhyziks_eye", LUA_MODIFIER_MOTION_NONE, modifier_item_rhyziks_eye_custom)