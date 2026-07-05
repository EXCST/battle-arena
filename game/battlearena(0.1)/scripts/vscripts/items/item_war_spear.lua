require('items/generic_datadriven_item')

item_war_spear = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_war_spear"
    end,
    GetAOERadius = function(self)
        return self:GetSpecialValueFor("woodcutter_radius")
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("cast_range")
    end
})

function item_war_spear:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local castPosition = self:GetCursorPosition()
    GridNav:DestroyTreesAroundPoint(castPosition, self:GetSpecialValueFor("woodcutter_radius"), false, self:GetCaster())
end

item_war_spear_1 = class(item_war_spear)
item_war_spear_2 = class(item_war_spear)
item_war_spear_3 = class(item_war_spear)
item_war_spear_4 = class(item_war_spear)
item_war_spear_5 = class(item_war_spear)
item_war_spear_6 = class(item_war_spear)

modifier_item_war_spear = class({
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
	DeclareFunctions  = function() 
        return 
        {
            MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_EVENT_ON_ATTACK_LANDED
	    }
    end
})

function modifier_item_war_spear:OnCreated( params )
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

function modifier_item_war_spear:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end   
    self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
    self.bonus_agi = self.ability:GetSpecialValueFor("bonus_agi")
    self.splash_radius = self.ability:GetSpecialValueFor("splash_radius")
    self.splash_damage_pct = self.ability:GetSpecialValueFor("splash_damage_pct") / 100
    self.splash_damage_limit = self.ability:GetSpecialValueFor("splash_damage_limit")
end

function modifier_item_war_spear:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage
end

function modifier_item_war_spear:GetModifierBonusStats_Agility()
    return self.bonus_agi
end

function modifier_item_war_spear:OnAttackLanded(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    if(kv.attacker:GetAttackCapability() ~= DOTA_UNIT_CAP_RANGED_ATTACK) then
        return
    end
    local attackerTeam = self.parent:GetTeamNumber()
    if(UnitFilter(kv.target, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    local splash_damage = kv.original_damage * self.splash_damage_pct 
    if splash_damage > self.splash_damage_limit then
        splash_damage = self.splash_damage_limit
    end
    DoSplashAttack(self.parent, kv.target, self.ability, splash_damage, self.splash_radius)
end

LinkLuaModifier("modifier_item_war_spear", "items/item_war_spear", LUA_MODIFIER_MOTION_NONE, modifier_item_war_spear)