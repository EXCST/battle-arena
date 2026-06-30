require('items/generic_datadriven_item')

item_sharp_javelin = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_sharp_javelin"
    end
})

item_sharp_javelin_1 = class(item_sharp_javelin)
item_sharp_javelin_2 = class(item_sharp_javelin)
item_sharp_javelin_3 = class(item_sharp_javelin)

modifier_item_sharp_javelin = class({
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
            MODIFIER_EVENT_ON_ATTACK_RECORD
        }
    end
})

function modifier_item_sharp_javelin:OnCreated()
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

function modifier_item_sharp_javelin:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
    self.bonus_attack_speed = self.ability:GetSpecialValueFor("bonus_attack_speed")
    
    self.proc_chance = self.ability:GetSpecialValueFor("proc_chance")
    self.proc_damage = self.ability:GetSpecialValueFor("proc_damage")
end

function modifier_item_sharp_javelin:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage
end

function modifier_item_sharp_javelin:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_attack_speed
end

function modifier_item_sharp_javelin:GetModifierProcAttack_BonusDamage_Magical(kv)
    if(self:IsProc() == false) then
        return
    end
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, kv.target, self.proc_damage, nil)
    return self.proc_damage
end

function modifier_item_sharp_javelin:OnAttackRecord(kv)
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

function modifier_item_sharp_javelin:SetIsProc(value)
    self._isProc = value
end

function modifier_item_sharp_javelin:IsProc()
    return self._isProc or false
end

function modifier_item_sharp_javelin:CheckState()
    return 
    {
        [MODIFIER_STATE_CANNOT_MISS] = self:IsProc()
    }
end

LinkLuaModifier("modifier_item_sharp_javelin", "items/item_sharp_javelin", LUA_MODIFIER_MOTION_NONE, modifier_item_sharp_javelin)

