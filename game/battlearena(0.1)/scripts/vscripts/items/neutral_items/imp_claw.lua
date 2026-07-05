item_imp_claw_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_imp_claw_custom"
    end
})

modifier_item_imp_claw_custom = class({
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
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
            MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE
        }
    end,
    GetModifierPreAttack_BonusDamage = function(self)
        return self.bonusAttackDamage
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_imp_claw_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_imp_claw_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAttackDamage = self.ability:GetSpecialValueFor("bonus_damage")
    self.critMultiplier = self.ability:GetSpecialValueFor("crit_multiplier")
end

function modifier_item_imp_claw_custom:GetModifierPreAttack_CriticalStrike()
    if(self.ability:IsCooldownReady() == false) then
        return
    end
    self.ability:UseResources(true, false, true, true)
    return self.critMultiplier
end
    
function modifier_item_imp_claw_custom:GetCritDamage()
    return self.critMultiplier / 100
end

LinkLuaModifier("modifier_item_imp_claw_custom", "items/neutral_items/imp_claw", LUA_MODIFIER_MOTION_NONE, modifier_item_imp_claw_custom)