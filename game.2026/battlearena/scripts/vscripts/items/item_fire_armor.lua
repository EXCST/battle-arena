require('items/generic_datadriven_item')

item_fire_armor = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_fire_armor_aura"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("aura_radius")
    end
})

item_fire_armor_upgrade = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_fire_armor_upgrade_aura"
    end,
    GetCastRange = function(self)
        return self:GetSpecialValueFor("aura_radius")
    end
})

function item_fire_armor:Precache(context)
    PrecacheResource("particle", "particles/items2_fx/radiance_owner.vpcf", context)
    PrecacheResource("particle", "particles/items2_fx/radiance.vpcf", context)
end

function item_fire_armor_upgrade:Precache(context)
    PrecacheResource("particle", "particles/items2_fx/radiance_owner.vpcf", context)
    PrecacheResource("particle", "particles/items2_fx/radiance.vpcf", context)
end

item_fire_armor_1 = class(item_fire_armor)
item_fire_armor_2 = class(item_fire_armor)
item_fire_armor_3 = class(item_fire_armor)

item_fire_armor_4 = class(item_fire_armor_upgrade)
item_fire_armor_5 = class(item_fire_armor_upgrade)
item_fire_armor_6 = class(item_fire_armor_upgrade)

modifier_item_fire_armor_aura = class({
	IsHidden = function()
        return true
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    IsAura = function()
        return true
    end,
    GetAuraRadius = function(self)
        return self.aura_radius
    end,
    GetAuraSearchTeam = function(self)
        return self.targetTeam
    end,
    GetAuraSearchType = function(self)
        return self.targetType
    end,
    GetAuraSearchFlags = function(self)
        return self.targetFlags
    end,
    GetModifierAura = function()
        return "modifier_item_fire_armor_aura_debuff"
    end,
	GetAttributes = function()
        return MODIFIER_ATTRIBUTE_MULTIPLE
    end,
	DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
    GetModifierBonusHealth = function(self) return self.bonus_health end,
    GetModifierConstantHealthRegen = function(self) return self.bonus_hp_regen end,
    GetModifierPhysicalArmorBonus = function(self) return self.bonus_armor end,
    GetEffectName = function() return "particles/items2_fx/radiance_owner.vpcf" end
})

function modifier_item_fire_armor_aura:OnCreated()
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

function modifier_item_fire_armor_aura:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.bonus_hp_regen = self.ability:GetSpecialValueFor("bonus_hp_regen")
    self.bonus_armor = self.ability:GetSpecialValueFor("bonus_armor")

    self.aura_radius = self.ability:GetSpecialValueFor("aura_radius")
end

modifier_item_fire_armor_aura_debuff = class({
    IsHidden = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end
})

function modifier_item_fire_armor_aura_debuff:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    if(not IsServer()) then
        return
    end
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self:OnRefresh()
	local pfx = ParticleManager:CreateParticle("particles/items2_fx/radiance.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControlEnt(pfx, 1, self.caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
	self:AddParticle(pfx, false, false, 1, false, false)
    self:StartIntervalThink(1)
end

function modifier_item_fire_armor_aura_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end

   self.damageTable = self.damageTable or {
        attacker = self.caster,
        victim = self.parent,
        ability = self.ability,
        damage = 0,
        damage_type = self.ability:GetAbilityDamageType()
    }
    self.damageTable.damage = self.ability:GetSpecialValueFor("aura_damage")
end

function modifier_item_fire_armor_aura_debuff:OnIntervalThink()
    ApplyDamage(self.damageTable)
end


modifier_item_fire_armor_upgrade_aura = class({
    IsHidden = function()
        return true
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    IsAura = function()
        return true
    end,
    GetAuraRadius = function(self)
        return self.aura_radius
    end,
    GetAuraSearchTeam = function(self)
        return self.targetTeam
    end,
    GetAuraSearchType = function(self)
        return self.targetType
    end,
    GetAuraSearchFlags = function(self)
        return self.targetFlags
    end,
    GetModifierAura = function()
        return "modifier_item_fire_armor_upgrade_aura_debuff"
    end,
    GetAttributes = function()
        return MODIFIER_ATTRIBUTE_MULTIPLE
    end,
    DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end
})

function modifier_item_fire_armor_upgrade_aura:OnCreated()
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

function modifier_item_fire_armor_upgrade_aura:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.bonus_hp_regen = self.ability:GetSpecialValueFor("bonus_hp_regen")
    self.bonus_armor = self.ability:GetSpecialValueFor("bonus_armor")

    self.aura_radius = self.ability:GetSpecialValueFor("aura_radius")
end

function modifier_item_fire_armor_upgrade_aura:GetModifierBonusHealth()
    return self.bonus_health
end

function modifier_item_fire_armor_upgrade_aura:GetModifierConstantHealthRegen()
    return self.bonus_hp_regen
end

function modifier_item_fire_armor_upgrade_aura:GetModifierPhysicalArmorBonus()
    return self.bonus_armor
end

function modifier_item_fire_armor_upgrade_aura:GetEffectName()
    return "particles/items2_fx/radiance_owner.vpcf"
end

modifier_item_fire_armor_upgrade_aura_debuff = class({
    IsHidden = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end
})

function modifier_item_fire_armor_upgrade_aura_debuff:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    if(not IsServer()) then
        return
    end
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self:OnRefresh()
    local pfx = ParticleManager:CreateParticle("particles/items2_fx/radiance.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
    ParticleManager:SetParticleControlEnt(pfx, 1, self.caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
    self:AddParticle(pfx, false, false, 1, false, false)
    self:StartIntervalThink(1)
end

function modifier_item_fire_armor_upgrade_aura_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end

    self.damageTable = self.damageTable or {
        attacker = self.caster,
        victim = self.parent,
        ability = self.ability,
        damage = 0,
        damage_type = self.ability:GetAbilityDamageType()
    }
    self.damageTable.damage = self.ability:GetSpecialValueFor("aura_damage") + self.caster:GetMaxHealth() * self.ability:GetSpecialValueFor("aura_damage_hp_pct") / 100
end

function modifier_item_fire_armor_upgrade_aura_debuff:OnIntervalThink()
    ApplyDamage(self.damageTable)
end

LinkLuaModifier("modifier_item_fire_armor_aura", "items/item_fire_armor", LUA_MODIFIER_MOTION_NONE, modifier_item_fire_armor_aura)
LinkLuaModifier("modifier_item_fire_armor_aura_debuff", "items/item_fire_armor", LUA_MODIFIER_MOTION_NONE, modifier_item_fire_armor_aura_debuff)
LinkLuaModifier("modifier_item_fire_armor_upgrade_aura", "items/item_fire_armor", LUA_MODIFIER_MOTION_NONE, modifier_item_fire_armor_upgrade_aura)
LinkLuaModifier("modifier_item_fire_armor_upgrade_aura_debuff", "items/item_fire_armor", LUA_MODIFIER_MOTION_NONE, modifier_item_fire_armor_upgrade_aura_debuff)
