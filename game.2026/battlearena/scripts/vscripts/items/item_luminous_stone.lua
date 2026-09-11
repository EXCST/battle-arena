require('items/generic_datadriven_item')

item_luminous_stone = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_luminous_stone"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("search_radius")
    end
})

function item_luminous_stone:Precache(context)
    PrecacheResource("particle", "particles/custom/items/ghostly_orb/projectile.vpcf", context)
end

function item_luminous_stone:OnProjectileHit(hTarget, vLocation)
    if(not hTarget) then
        return
    end
    ApplyDamage({
        victim = hTarget,
        attacker = self:GetCaster(),
        damage = self:GetSpecialValueFor("projectile_damage"),
        damage_type = self:GetAbilityDamageType(),
        ability = self
    })
    EmitSoundOn("LuminousStone.Damage", hTarget)
end

item_luminous_stone_upgrade = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_luminous_stone"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("search_radius")
    end
})


function item_luminous_stone_upgrade:OnProjectileHit(hTarget, vLocation)
    if(not hTarget) then
        return
    end
    local projectile_damage = self:GetSpecialValueFor("projectile_damage")
    if self:GetCaster():IsRealHero() then 
        projectile_damage = self:GetSpecialValueFor("projectile_damage") + self:GetCaster():GetStrength(true)*self:GetSpecialValueFor("projectile_damage_str_pct")/100
    end
    ApplyDamage({
        victim = hTarget,
        attacker = self:GetCaster(),
        damage = projectile_damage,
        damage_type = self:GetAbilityDamageType(),
        ability = self
    })
    EmitSoundOn("LuminousStone.Damage", hTarget)
end

item_luminous_stone_1 = class(item_luminous_stone)
item_luminous_stone_2 = class(item_luminous_stone)
item_luminous_stone_3 = class(item_luminous_stone)

item_luminous_stone_4 = class(item_luminous_stone_upgrade)
item_luminous_stone_5 = class(item_luminous_stone_upgrade)
item_luminous_stone_6 = class(item_luminous_stone_upgrade)

modifier_item_luminous_stone = class({
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
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end
})

function modifier_item_luminous_stone:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.targetTeam = self.ability:GetAbilityTargetTeam()
    self.targetType = self.ability:GetAbilityTargetType()
    self.targetFlags = self.ability:GetAbilityTargetFlags()
    self:StartIntervalThink(0.1)
end

function modifier_item_luminous_stone:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.search_radius = self.ability:GetSpecialValueFor("search_radius")
    self.projectile_damage = self.ability:GetSpecialValueFor("projectile_damage")
    self.projectile_speed = self.ability:GetSpecialValueFor("projectile_speed")
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.bonus_hp_regen = self.ability:GetSpecialValueFor("bonus_hp_regen")
    self.bonus_all = self.ability:GetSpecialValueFor("bonus_all")
end

function modifier_item_luminous_stone:OnIntervalThink()
    if (self.ability:IsCooldownReady() == false) then
        return 
    end
    local position = self.parent:GetAbsOrigin()
    local enemies = FindUnitsInRadius(
        self.parent:GetTeamNumber(), 
        position, 
        nil, 
        self.search_radius, 
        self.targetTeam, 
        self.targetType, 
        self.targetFlags, 
        FIND_ANY_ORDER, 
        false
    )
    for _, enemy in pairs(enemies) do
        ProjectileManager:CreateTrackingProjectile({
            Target = enemy,
            Source = self.parent,
            Ability = self.ability, 
            EffectName = "particles/custom/items/ghostly_orb/projectile.vpcf",
            iMoveSpeed = self.projectile_speed,
            vSourceLoc = position,
            bDodgeable = true,
        })
        self.ability:UseResources(true, false, true, true)
        EmitSoundOn("LuminousStone.Proc", self.parent)
        break
    end
end

function modifier_item_luminous_stone:GetModifierBonusHealth()
	return self.bonus_health
end

function modifier_item_luminous_stone:GetModifierConstantHealthRegen()
    return self.bonus_hp_regen
end

function modifier_item_luminous_stone:GetModifierBonusStats_Strength()
    return self.bonus_all
end

function modifier_item_luminous_stone:GetModifierBonusStats_Agility()
    return self.bonus_all
end

function modifier_item_luminous_stone:GetModifierBonusStats_Intellect()
    return self.bonus_all
end

LinkLuaModifier("modifier_item_luminous_stone", "items/item_luminous_stone", LUA_MODIFIER_MOTION_NONE, modifier_item_luminous_stone)