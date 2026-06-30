require('items/generic_datadriven_item')

item_difusial_blade_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_difusial_blade_custom"
    end
})

item_difusial_blade_custom_1 = class(item_difusial_blade_custom)
item_difusial_blade_custom_2 = class(item_difusial_blade_custom)
item_difusial_blade_custom_3 = class(item_difusial_blade_custom)

item_spiral_blade_1 = class(item_difusial_blade_custom)
item_spiral_blade_2 = class(item_difusial_blade_custom)
item_spiral_blade_3 = class(item_difusial_blade_custom)

modifier_item_difusial_blade_custom = class({
	IsHidden  = function() 
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
	DeclareFunctions  = function() 
        return 
        {
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_ROSHDEF_PROCATTACK_BONUS_DAMAGE
	    }
    end
})

function modifier_item_difusial_blade_custom:OnCreated( params )
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

function modifier_item_difusial_blade_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonus_agi = self.ability:GetSpecialValueFor("bonus_agi")
    self.damage_vs_summon = self.ability:GetSpecialValueFor("damage_vs_summon")
    self.feedback_mana_burn = self.ability:GetSpecialValueFor("feedback_mana_burn")
    self.feedback_mana_burn_illusion_melee = self.ability:GetSpecialValueFor("feedback_mana_burn_illusion_melee")
    self.feedback_mana_burn_illusion_ranged = self.ability:GetSpecialValueFor("feedback_mana_burn_illusion_ranged")
    self.damage_per_burn = self.ability:GetSpecialValueFor("damage_per_burn")
end

function modifier_item_difusial_blade_custom:GetModifierBonusStats_Agility()
    return self.bonus_agi
end

function modifier_item_difusial_blade_custom:GetModifierProcAttack_BonusDamage(kv)
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

LinkLuaModifier("modifier_item_difusial_blade_custom", "items/item_difusial_blade_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_difusial_blade_custom)