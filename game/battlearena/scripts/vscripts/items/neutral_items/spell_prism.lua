item_spell_prism_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_spell_prism_custom"
    end
})

modifier_item_spell_prism_custom = class({
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
            MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
            MODIFIER_EVENT_ON_DEATH
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
    GetModifierConstantManaRegen = function(self)
        return self.bonusManaRegeneration
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_spell_prism_custom:OnCreated()
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

function modifier_item_spell_prism_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAllStats = self.ability:GetSpecialValueFor("bonus_all_stats")
    self.bonusManaRegeneration = self.ability:GetSpecialValueFor("mana_regen")
    self.cdrFlat = self.ability:GetSpecialValueFor("cooldown_decrease_per_kill")
end

function modifier_item_spell_prism_custom:OnDeath(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    if(UnitFilter(kv.unit, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    self:ReduceLongestAbilityCooldown()
end

function modifier_item_spell_prism_custom:ReduceLongestAbilityCooldown()
    local desiredAbility = nil
    local lastStoredCD = 0
    for i = 0, self.parent:GetAbilityCount() - 1 do
        local ability = self.parent:GetAbilityByIndex(i)
        if(ability) then
            local abilityCooldown = ability:GetCooldownTimeRemaining()
            if(abilityCooldown > 0 and abilityCooldown > lastStoredCD) then
                desiredAbility = ability
                lastStoredCD = abilityCooldown
            end
        end
    end
    if(desiredAbility == nil) then
        return
    end
    local newCooldown = lastStoredCD - self.cdrFlat
    if newCooldown < 0 then newCooldown = 0 end
    desiredAbility:EndCooldown()
    desiredAbility:StartCooldown(newCooldown)
end

LinkLuaModifier("modifier_item_spell_prism_custom", "items/neutral_items/spell_prism", LUA_MODIFIER_MOTION_NONE, modifier_item_spell_prism_custom)