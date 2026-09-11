require('items/generic_datadriven_item')

item_sharpness_void = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_sharpness_void"
    end
})

modifier_item_sharpness_void = class({
    IsHidden = function() 
        return true 
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
	GetAttributes = function() 
        return MODIFIER_ATTRIBUTE_MULTIPLE 
    end,
	DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
            MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,
            MODIFIER_EVENT_ON_ATTACK_RECORD,
            MODIFIER_PROPERTY_ROSHDEF_PROCATTACK_BONUS_DAMAGE,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS
        }
    end
})

function modifier_item_sharpness_void:OnCreated()
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

function modifier_item_sharpness_void:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
    self.bonus_attack_speed = self.ability:GetSpecialValueFor("bonus_attack_speed")
    self.proc_chance = self.ability:GetSpecialValueFor("proc_chance")
    self.proc_damage = self.ability:GetSpecialValueFor("proc_damage")
    self.bonus_agi = self.ability:GetSpecialValueFor("bonus_agi")
    self.damage_vs_summon = self.ability:GetSpecialValueFor("damage_vs_summon")
    self.feedback_mana_burn = self.ability:GetSpecialValueFor("feedback_mana_burn")
    self.feedback_mana_burn_illusion_melee = self.ability:GetSpecialValueFor("feedback_mana_burn_illusion_melee")
    self.feedback_mana_burn_illusion_ranged = self.ability:GetSpecialValueFor("feedback_mana_burn_illusion_ranged")
    self.damage_per_burn = self.ability:GetSpecialValueFor("damage_per_burn")
    
end

function modifier_item_sharpness_void:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage
end

function modifier_item_sharpness_void:GetModifierBonusStats_Agility()
    return self.bonus_agi
end

function modifier_item_sharpness_void:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_attack_speed
end

function modifier_item_sharpness_void:GetModifierProcAttack_BonusDamage_Magical(kv)
    if(self:IsProc() == false) then
        return
    end
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, kv.target, self.proc_damage, nil)
    return self.proc_damage
end

function modifier_item_sharpness_void:GetModifierProcAttack_BonusDamage(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    if(UnitFilter(kv.target, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    local manaBurned = self.feedback_mana_burn
    if(kv.attacker:IsIllusion()) then
        if(kv.attacker:GetAttackCapability() == DOTA_UNIT_CAP_MELEE_ATTACK) then
            manaBurned = self.feedback_mana_burn_illusion_melee
        else
            manaBurned = self.feedback_mana_burn_illusion_ranged
        end
    end
    local manaLost = kv.target:GetMana()
    kv.target:ReduceMana(manaBurned)
    local manaLost = math.max(manaLost - kv.target:GetMana(), 0)
    manaBurned = manaLost
    local bonusDamageToSummons = 0
    if(kv.target:IsSummoned()) then
        bonusDamageToSummons = self.damage_vs_summon
    end
    return (manaBurned * self.damage_per_burn) + bonusDamageToSummons
end

function modifier_item_sharpness_void:OnAttackRecord(kv)
    if(self.parent ~= kv.attacker) then
        return
    end
    self:SetIsProc(false)
    if(UnitFilter(kv.target, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    if(RollPercentage(self.proc_chance) == false) then
        return
    end
    self:SetIsProc(true)
end

function modifier_item_sharpness_void:SetIsProc(value)
    self._isProc = value
end

function modifier_item_sharpness_void:IsProc()
    return self._isProc or false
end

function modifier_item_sharpness_void:CheckState()
    return 
    {
        [MODIFIER_STATE_CANNOT_MISS] = self:IsProc()
    }
end

LinkLuaModifier("modifier_item_sharpness_void", "items/item_sharpness_void", LUA_MODIFIER_MOTION_NONE, modifier_item_sharpness_void)

