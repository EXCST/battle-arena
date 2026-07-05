item_the_leveller_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_the_leveller_custom"
    end
})

modifier_item_the_leveller_custom = class({
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
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
            MODIFIER_PROPERTY_ROSHDEF_PROCATTACK_BONUS_DAMAGE
        }
    end,
    GetModifierAttackSpeedBonus_Constant = function(self)
        return self.bonusAttackSpeed
    end,
    GetModifierPhysicalArmorBonus = function(self)
        return self.bonusArmor
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_the_leveller_custom:OnCreated()
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

function modifier_item_the_leveller_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAttackSpeed = self.ability:GetSpecialValueFor("bonus_attack_speed")
    self.bonusArmor = self.ability:GetSpecialValueFor("bonus_armor")
    self.bonusBuildingsDamagePct = self.ability:GetSpecialValueFor("demolish") / 100
end

function modifier_item_the_leveller_custom:GetModifierProcAttack_BonusDamage(kv)
    if(UnitFilter(kv.target, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return 0
    end
    return kv.original_damage * self.bonusBuildingsDamagePct
end

LinkLuaModifier("modifier_item_the_leveller_custom", "items/neutral_items/the_leveller", LUA_MODIFIER_MOTION_NONE, modifier_item_the_leveller_custom)