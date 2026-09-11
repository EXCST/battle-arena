require('items/generic_datadriven_item')

item_stinger = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_stinger"
    end
})

item_stinger_1 = class(item_stinger)
item_stinger_2 = class(item_stinger)
item_stinger_3 = class(item_stinger)

item_venomous_blade_1 = class(item_stinger)
item_venomous_blade_2 = class(item_stinger)
item_venomous_blade_3 = class(item_stinger)

item_veedle_claw_1 = class(item_stinger)
item_veedle_claw_2 = class(item_stinger)
item_veedle_claw_3 = class(item_stinger)

modifier_item_stinger = class({
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
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_PROJECTILE_NAME,
            MODIFIER_EVENT_ON_ATTACK_LANDED,
        }
    end
})

function modifier_item_stinger:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_stinger:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
    self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
    self.debuff_duration = self.ability:GetSpecialValueFor("debuff_duration")
end

function modifier_item_stinger:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage
end

function modifier_item_stinger:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_stinger:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_stinger:GetModifierBonusStats_Intellect()
    return self.bonus_allstats
end

function modifier_item_stinger:GetModifierProjectileName()
    return "particles/units/heroes/hero_viper/viper_poison_attack.vpcf"
end

function modifier_item_stinger:OnAttackLanded(data)
    local target = data.target
    local attacker = data.attacker

    if attacker == self.parent and target:GetTeam() ~= self.parent:GetTeam() then
        target:AddNewModifier(self.parent, self.ability, "modifier_item_stinger_debuff", {duration = self.debuff_duration})
    end
end

modifier_item_stinger_debuff = class({
    IsHidden = function()
        return false
    end,
    IsPurgable = function()
        return true
    end,
    IsPurgeException = function()
        return false
    end,
    GetEffectName = function()
        return "particles/items2_fx/orb_of_venom.vpcf"
    end,
})

function modifier_item_stinger_debuff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self.caster = self:GetCaster()
    self:OnRefresh()

    self:StartIntervalThink(1)
end


function modifier_item_stinger_debuff:OnIntervalThink()
    local damageDone = ApplyDamage(self.hDamageTable)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, self.hDamageTable.victim, damageDone, nil)
end

function modifier_item_stinger_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.debuff_dps = self.ability:GetSpecialValueFor("debuff_dps")
    self.debuff_dps_stat = self.ability:GetSpecialValueFor("debuff_dps_stat_pct")/100*(self.caster:GetStrength(true)+self.caster:GetAgility(true)+self.caster:GetPrimaryStatValue())

    self.hDamageTable = {
        victim = self:GetParent(),
        attacker = self.ability:GetCaster(),
        ability = self.ability,
        damage = self.debuff_dps+self.debuff_dps_stat,
        damage_type = DAMAGE_TYPE_MAGICAL
    }
end


LinkLuaModifier("modifier_item_stinger", "items/item_stinger", LUA_MODIFIER_MOTION_NONE, modifier_item_stinger)
LinkLuaModifier("modifier_item_stinger_debuff", "items/item_stinger", LUA_MODIFIER_MOTION_NONE, modifier_item_stinger_debuff)
