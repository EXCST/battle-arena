item_dragon_scale_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_dragon_scale_custom"
    end
})

function item_dragon_scale_custom:Precache(context)
    PrecacheResource("particle", "particles/units/heroes/hero_jakiro/jakiro_liquid_fire_debuff.vpcf", context)
end

modifier_item_dragon_scale_custom = class({
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
			MODIFIER_EVENT_ON_ATTACK_LANDED,
            MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
        }
    end,
    GetModifierConstantHealthRegen = function(self)
        return self.bonusHealthRegeneration
    end,
    GetModifierPhysicalArmorBonus = function(self)
        return self.bonusArmor
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_dragon_scale_custom:OnCreated()
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

function modifier_item_dragon_scale_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusArmor = self.ability:GetSpecialValueFor("bonus_armor")
    self.bonusHealthRegeneration = self.ability:GetSpecialValueFor("bonus_hp_regen")
    self.debuffDuration = self.ability:GetSpecialValueFor("duration")
end

function modifier_item_dragon_scale_custom:GetModifierAttackRangeBonus()
    return self:GetStackCount()
end

function modifier_item_dragon_scale_custom:OnAttackLanded(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    if(UnitFilter(kv.target, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    kv.target:AddNewModifier(self.parent, self.ability, "modifier_item_dragon_scale_custom_debuff", {duration = self.debuffDuration})
end

modifier_item_dragon_scale_custom_debuff = class({
    IsHidden = function() 
        return false 
    end,
    IsDebuff = function()
        return true
    end,
    IsPurgable = function()
        return true
    end,
    GetEffectName = function()
        return "particles/units/heroes/hero_jakiro/jakiro_liquid_fire_debuff.vpcf"
    end,
    GetTexture = function(self)
        return self.buffIcon
    end
})

function modifier_item_dragon_scale_custom_debuff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
    end
end

function modifier_item_dragon_scale_custom_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    if(not IsServer()) then
        return
    end
    self.damageTable = self.damageTable or {
		victim = self.parent,
		attacker = nil,
		damage = 0,
		damage_type = self.ability:GetAbilityDamageType(),
		ability = self.ability
	}
    local tickInterval = self.ability:GetSpecialValueFor("tick_interval")
    self.damageTable.attacker = self.ability:GetCaster()
    self.damageTable.damage = self.ability:GetSpecialValueFor("damage_per_sec") * tickInterval
    self:StartIntervalThink(tickInterval)
end

function modifier_item_dragon_scale_custom_debuff:OnIntervalThink()
    local damageDone = ApplyDamage(self.damageTable)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, self.damageTable.victim, damageDone, nil)
end

LinkLuaModifier("modifier_item_dragon_scale_custom", "items/neutral_items/dragon_scale", LUA_MODIFIER_MOTION_NONE, modifier_item_dragon_scale_custom)
LinkLuaModifier("modifier_item_dragon_scale_custom_debuff", "items/neutral_items/dragon_scale", LUA_MODIFIER_MOTION_NONE, modifier_item_dragon_scale_custom_debuff)