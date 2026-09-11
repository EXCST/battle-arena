modifier_huntress_aim_shot = modifier_huntress_aim_shot or class({})
--------------------------------------------------------------------------------
function modifier_huntress_aim_shot:IsDebuff()
    return false
end

----------------------------------------------------------------------------------
function modifier_huntress_aim_shot:IsPurgable()
    return false
end

----------------------------------------------------------------------------------
function modifier_huntress_aim_shot:IsHidden()
    return false
end

--------------------------------------------------------------------------------
function modifier_huntress_aim_shot:GetEffectName()
    return "particles/huntress/huntress_aim_shot/huntress_aim_shot.vpcf"
end

--------------------------------------------------------------------------------
function modifier_huntress_aim_shot:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

--------------------------------------------------------------------------------
function modifier_huntress_aim_shot:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
    }
    return funcs
end

--------------------------------------------------------------------------------
function modifier_huntress_aim_shot:GetModifierBaseAttackTimeConstant()
    if self:GetParent():HasModifier("modifier_huntress_hunting_spirit") then
        return
    else
        local bat = self:GetAbility():GetSpecialValueFor("set_bat_value")
        local bat_talent = self:GetParent():FindAbilityByName("huntress_aim_shot_bonus_bat_tallent")
        local crit_talent = self:GetParent():FindAbilityByName("huntress_aim_shot_bonus_crit_tallent")
        local talent_val = 0
        if bat_talent and bat_talent:GetLevel() > 0 and bat_talent.GetAbilityKeyValues then
            local kv = bat_talent:GetAbilityKeyValues()
            if kv and kv["AbilitySpecial"] and kv["AbilitySpecial"]["value"] then
                talent_val = tonumber(kv["AbilitySpecial"]["value"]["value"]) or 0
            end
        end
        print("[AIM_SHOT_BAT] base_bat = " .. tostring(bat) .. " talent_val = " .. tostring(talent_val) .. " final = " .. tostring(bat + talent_val) .. " | bat_lvl=" .. tostring(bat_talent and bat_talent:GetLevel() or 0) .. " crit_lvl=" .. tostring(crit_talent and crit_talent:GetLevel() or 0))
        bat = bat + talent_val
        return bat
    end
end

--------------------------------------------------------------------------------
function modifier_huntress_aim_shot:GetModifierAttackRangeBonus()
    self.bonus_attack_range = self:GetAbility():GetSpecialValueFor("bonus_attack_range")
    return self.bonus_attack_range
end

--------------------------------------------------------------------------------
function modifier_huntress_aim_shot:GetModifierPreAttack_CriticalStrike(params)
    if not IsServer() then return end
    if params.target ~= nil and params.attacker == self:GetParent() then
        local crit = self:GetAbility():GetSpecialValueFor("crit_damage_pct")
        local crit_talent = self:GetParent():FindAbilityByName("huntress_aim_shot_bonus_crit_tallent")
        local talent_val = 0
        if crit_talent and crit_talent:GetLevel() > 0 and crit_talent.GetAbilityKeyValues then
            local kv = crit_talent:GetAbilityKeyValues()
            if kv and kv["AbilitySpecial"] and kv["AbilitySpecial"]["value"] then
                talent_val = tonumber(kv["AbilitySpecial"]["value"]["value"]) or 0
            end
        end
        print("[AIM_SHOT_CRIT] base_crit = " .. tostring(crit) .. " talent_val = " .. tostring(talent_val) .. " final = " .. tostring(crit + talent_val))
        crit = crit + talent_val
        return crit
    end
end

--------------------------------------------------------------------------------
