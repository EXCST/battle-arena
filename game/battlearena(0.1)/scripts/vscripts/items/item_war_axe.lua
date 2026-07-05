require('items/generic_datadriven_item')

item_war_axe = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_war_axe"
    end,
    GetAOERadius = function(self)
        return self:GetSpecialValueFor("woodcutter_radius")
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("cast_range")
    end
})

function item_war_axe:Precache(context)
	PrecacheResource("particles/items_fx/battlefury_cleave.vpcf", string_2, context)
end

function item_war_axe:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local castPosition = self:GetCursorPosition()
    GridNav:DestroyTreesAroundPoint(castPosition, self:GetSpecialValueFor("woodcutter_radius"), false, self:GetCaster())
end

item_war_axe_1 = class(item_war_axe)
item_war_axe_2 = class(item_war_axe)
item_war_axe_3 = class(item_war_axe)
item_war_axe_4 = class(item_war_axe)
item_war_axe_5 = class(item_war_axe)
item_war_axe_6 = class(item_war_axe)

modifier_item_war_axe = class({
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
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_EVENT_ON_ATTACK_LANDED
	    }
    end
})

function modifier_item_war_axe:OnCreated( params )
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

function modifier_item_war_axe:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
    self.bonus_str = self.ability:GetSpecialValueFor("bonus_str")
    self.cleave_start_radius = self.ability:GetSpecialValueFor("cleave_start_radius")
    self.cleave_end_radius = self.ability:GetSpecialValueFor("cleave_end_radius")
    self.cleave_range = self.ability:GetSpecialValueFor("cleave_range")
    self.cleave_pct = self.ability:GetSpecialValueFor("cleave_pct")/100
    self.cleave_damage_limit = self.ability:GetSpecialValueFor("cleave_damage_limit")
end

function modifier_item_war_axe:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage
end

function modifier_item_war_axe:GetModifierBonusStats_Strength()
    return self.bonus_str
end

function modifier_item_war_axe:OnAttackLanded(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    if(UnitFilter(kv.target, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    if(kv.attacker:GetAttackCapability() ~= DOTA_UNIT_CAP_MELEE_ATTACK) then
        return
    end
    local cleave_damage = kv.original_damage * self.cleave_pct
    if cleave_damage > self.cleave_damage_limit then
        cleave_damage = self.cleave_damage_limit
    end
    DoCleaveAttack(
        self.parent, 
        kv.target, 
        self.ability, 
        cleave_damage, 
        self.cleave_start_radius,
        self.cleave_end_radius, 
        self.cleave_range, 
        "particles/items_fx/battlefury_cleave.vpcf"
    )
end

LinkLuaModifier("modifier_item_war_axe", "items/item_war_axe", LUA_MODIFIER_MOTION_NONE, modifier_item_war_axe)