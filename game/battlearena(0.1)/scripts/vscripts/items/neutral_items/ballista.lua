item_ballista_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_ballista_custom"
    end
})

modifier_item_ballista_custom = class({
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
			MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
            MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
            MODIFIER_PROPERTY_ROSHDEF_PROCATTACK_BONUS_DAMAGE
        }
    end,
    GetModifierProjectileSpeedBonus = function(self)
        return self.bonusProjectileSpeed
    end,
    GetModifierPreAttack_BonusDamage = function(self)
        return self.bonusDamage
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_ballista_custom:OnCreated()
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

function modifier_item_ballista_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusProjectileSpeed = self.ability:GetSpecialValueFor("bonus_projectile_speed")
    self.bonusDamage = self.ability:GetSpecialValueFor("bonus_damage")
    self.bonusAttackRangeRanged = self.ability:GetSpecialValueFor("bonus_attack_range")
    self.distanceToStack = self.ability:GetSpecialValueFor("distance_to_stack")
    self.bonusDamagePerDistanceStack = (self.ability:GetSpecialValueFor("bonus_damage_per_stack") / 100) / self.distanceToStack
end

function modifier_item_ballista_custom:OnIntervalThink()
    local attackCapability = self.parent:GetAttackCapability()
    if(self.parent:GetAttackCapability() == DOTA_UNIT_CAP_RANGED_ATTACK) then
        self:SetStackCount(self.bonusAttackRangeRanged)
    else
        self:SetStackCount(0)
    end
end

function modifier_item_ballista_custom:GetModifierAttackRangeBonus()
    return self:GetStackCount()
end

function modifier_item_ballista_custom:GetModifierProcAttack_BonusDamage(kv)
    if(UnitFilter(kv.target, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return 0
    end
    return (CalculateDistance(kv.target, self.parent) * self.bonusDamagePerDistanceStack) * kv.original_damage
end

LinkLuaModifier("modifier_item_ballista_custom", "items/neutral_items/ballista", LUA_MODIFIER_MOTION_NONE, modifier_item_ballista_custom)