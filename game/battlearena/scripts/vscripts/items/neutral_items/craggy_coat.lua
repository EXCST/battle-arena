item_craggy_coat_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_craggy_coat_custom"
    end
})

function item_craggy_coat_custom:Precache(context)
    PrecacheResource("particle", "particles/neutral_fx/mud_golem_hurl_boulder.vpcf", context)
end

function item_craggy_coat_custom:OnProjectileHit(target, location)
    if(not target) then
        return
    end
    local caster = self:GetCaster()
    target:AddNewModifier(caster, self, "modifier_stunned", { duration = self:GetSpecialValueFor("stun_duration")})
    EmitSoundOn("Item.CraggyCoat.Projectile.Impact", target)
    local damage = 0
    if(caster.GetPrimaryAttribute) then
        damage = caster:GetPrimaryStatValue() * (self:GetSpecialValueFor("primary_stat_to_dmg") / 100)
    else
        return
    end
    ApplyDamage({
        victim = target,
        attacker = caster,
        ability = self,
        damage = damage,
        damage_type = self:GetAbilityDamageType()
    })
end

modifier_item_craggy_coat_custom = class({
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
            MODIFIER_EVENT_ON_TAKEDAMAGE,
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
        }
    end,
    GetModifierPhysicalArmorBonus = function(self)
        return self.bonusArmor
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_craggy_coat_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.targetTeam = self.ability:GetAbilityTargetTeam()
	self.targetType = self.ability:GetAbilityTargetType()
	self.targetFlags = self.ability:GetAbilityTargetFlags()
    self:StartIntervalThink(0.2)
end

function modifier_item_craggy_coat_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusArmor = self.ability:GetSpecialValueFor("bonus_armor")
    self.bonusPrimaryAttribute = self.ability:GetSpecialValueFor("bonus_primary_attribute")
    self.procChance = self.ability:GetSpecialValueFor("chance")
    if(not IsServer()) then
        return
    end
    self.projectileInfo = self.projectileInfo or {
		EffectName = "particles/neutral_fx/mud_golem_hurl_boulder.vpcf",
		Ability = self.ability,
		iMoveSpeed = 1000,
		Source = self.parent,
		Target = nil,
	}
    self.projectileInfo.iMoveSpeed = self.ability:GetSpecialValueFor("projectile_speed")
end

function modifier_item_craggy_coat_custom:OnIntervalThink()
    if(not self.parent.GetPrimaryAttribute) then
        return
    end
    self:SetStackCount(self.parent:GetPrimaryAttribute())
end

function modifier_item_craggy_coat_custom:OnTakeDamage(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    if(self.ability:IsCooldownReady() == false) then
        return
    end
    if(RollPercentage(self.procChance) == false) then
        return
    end
    if(UnitFilter(kv.attacker, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    self.projectileInfo.Target = kv.attacker
	ProjectileManager:CreateTrackingProjectile(self.projectileInfo)
    self.ability:UseResources(true, false, true, true)
    EmitSoundOn("Item.CraggyCoat.Projectile", self.parent)
end

function modifier_item_craggy_coat_custom:GetModifierBonusStats_Strength()
    if(self.parent:IsRealHero() == false) then
        return
    end
    if(self:GetStackCount() == DOTA_ATTRIBUTE_STRENGTH) then
        return self.bonusPrimaryAttribute
    end
    return 0
end

function modifier_item_craggy_coat_custom:GetModifierBonusStats_Agility()
    if(self.parent:IsRealHero() == false) then
        return
    end
    if(self:GetStackCount() == DOTA_ATTRIBUTE_AGILITY) then
        return self.bonusPrimaryAttribute
    end
    return 0
end

function modifier_item_craggy_coat_custom:GetModifierBonusStats_Intellect()
    if(self.parent:IsRealHero() == false) then
        return
    end
    if(self:GetStackCount() == DOTA_ATTRIBUTE_INTELLECT) then
        return self.bonusPrimaryAttribute
    end
    return 0
end

LinkLuaModifier("modifier_item_craggy_coat_custom", "items/neutral_items/craggy_coat", LUA_MODIFIER_MOTION_NONE, modifier_item_craggy_coat_custom)