item_mysterious_hat_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_mysterious_hat_custom"
    end
})

modifier_item_mysterious_hat_custom = class({
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
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_EVENT_ON_ABILITY_EXECUTED,
            MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
    GetModifierSpellAmplify_Percentage = function(self)
        return self.bonusSpellAmp
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_mysterious_hat_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_mysterious_hat_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusHealth = self.ability:GetSpecialValueFor("bonus_health")
    self.bonusSpellAmp = self.ability:GetSpecialValueFor("spell_amp")
    self.bonusManaPerCast = self.ability:GetSpecialValueFor("mana_restore_per_cast")
end

function modifier_item_mysterious_hat_custom:GetModifierBonusHealth()
	return self.bonusHealth
end

function modifier_item_mysterious_hat_custom:OnAbilityExecuted(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    if(self.ability:IsCooldownReady() == false) then
        return
    end
    self.parent:GiveMana(self.bonusManaPerCast)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, self.parent, self.bonusManaPerCast, nil)
    self.ability:UseResources(true, false, true, true)
end

LinkLuaModifier("modifier_item_mysterious_hat_custom", "items/neutral_items/mysterious_hat", LUA_MODIFIER_MOTION_NONE, modifier_item_mysterious_hat_custom)