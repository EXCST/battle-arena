item_aphotic_orb = class({
    GetCastRange = function(self)
        return self:GetSpecialValueFor("radius")
    end,
    GetIntrinsicModifierName = function()
        return "modifier_item_aphotic_orb"
    end
})

function item_aphotic_orb:Precache(context)
    PrecacheResource("particle", "particles/custom/items/aphotic_orb/active.vpcf", context)
    PrecacheResource("particle", "particles/custom/items/aphotic_orb/buff.vpcf", context)
    PrecacheResource("particle", "particles/custom/items/aphotic_orb/projectile/projectile.vpcf", context)
end

function item_aphotic_orb:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    caster:AddNewModifier(caster, self, "modifier_item_aphotic_orb_active", {duration = self:GetSpecialValueFor("duration_of_convertation")})
end

function item_aphotic_orb:OnProjectileHit(target, location)
    if(not target) then
        return
    end
    local mod = target:FindModifierByName("modifier_item_aphotic_orb_buff")
    if(mod) then
        mod:SetIsActive(true)
    end
    EmitSoundOn("Item.AphoticOrb.Hit", target)
end

modifier_item_aphotic_orb = class({
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
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
            MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_HEAL_RECEIVED_PERCENTAGE
        }
    end,
    GetModifierConstantHealthRegen = function(self)
        return self.bonusHealthRegeneration
    end,
    GetModifierLifestealRegenAmplify_Percentage = function(self)
        return self.bonusHealingAmp
    end,
    GetModifierSpellLifestealRegenAmplify_Percentage = function(self)
        return self.bonusHealingAmp
    end,
    GetModifierHPRegenAmplify_Percentage = function(self)
        return self.bonusHealingAmp
    end,
    GetModifierHealReceived_Percentage = function(self)
        return self.bonusHealingAmp
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_aphotic_orb:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_aphotic_orb:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusHealthRegeneration = self.ability:GetSpecialValueFor("bonus_health_regeneration")
    self.bonusHealingAmp = self.ability:GetSpecialValueFor("bonus_health_regeneration_amp_pct")
end

modifier_item_aphotic_orb_active = class({
    IsHidden = function() 
        return false 
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
            MODIFIER_EVENT_ROSHDEF_ON_HEAL_RECEIVED,
            MODIFIER_PROPERTY_TOOLTIP
        }
    end,
    OnTooltip = function(self)
        return self:GetStackCount()
    end,
    GetEffectName = function()
        return "particles/custom/items/aphotic_orb/active.vpcf"
    end,
    GetTexture = function(self)
        return self.buffIcon
    end
})

function modifier_item_aphotic_orb_active:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
        return
    end
    StartSoundEvent("Item.AphoticOrb.Cast", self.parent)
end

function modifier_item_aphotic_orb_active:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.healingToShieldPct = self.ability:GetSpecialValueFor("healing_to_shield_pct")
    self.shieldDuration = self.ability:GetSpecialValueFor("shield_duration")
    self.projectile = self.projectile or {
		EffectName = "particles/custom/items/aphotic_orb/projectile/projectile.vpcf",
		Ability = self.ability,
		iMoveSpeed = 1000,
		Source = self.parent,
		Target = nil,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
	}
    self.projectile.iMoveSpeed = self.ability:GetSpecialValueFor("projectile_speed")
end

function modifier_item_aphotic_orb_active:OnHealReceived(kv)
    if(kv.target ~= self.parent) then
        return
    end
    self:SetStackCount(self:GetStackCount() + kv.healing)
end

function modifier_item_aphotic_orb_active:OnDestroy()
    if(not IsServer()) then
        return
    end
    if(self.parent:IsAlive() == false) then
        return
    end
    local allies = FindUnitsInRadius(
        self.parent:GetTeamNumber(), 
        self.parent:GetAbsOrigin(), 
        nil, 
        self.ability:GetCastRange(), 
        self.ability:GetAbilityTargetTeam(), 
        self.ability:GetAbilityTargetType(), 
        self.ability:GetAbilityTargetFlags(), 
        FIND_ANY_ORDER, 
        false
    )
    local stacks = self:GetStackCount()
    for _, ally in pairs(allies) do
        local mod = ally:AddNewModifier(self.parent, self.ability, "modifier_item_aphotic_orb_buff", {duration = self.shieldDuration})
        if(mod) then
            mod:SetCapacity(stacks)
        end
        self.projectile.Target = ally
        ProjectileManager:CreateTrackingProjectile(self.projectile)
    end
    EmitSoundOn("Item.AphoticOrb.Proc", self.parent)
    StopSoundEvent("Item.AphoticOrb.Cast", self.parent)
end


modifier_item_aphotic_orb_buff = class({
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
            MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
            MODIFIER_PROPERTY_TOOLTIP
        }
    end,
    OnTooltip = function(self)
        return self:GetStackCount()
    end,
    GetTexture = function(self)
        return self.buffIcon
    end
})

function modifier_item_aphotic_orb_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
    end
end

function modifier_item_aphotic_orb_buff:IsHidden()
    return self:GetStackCount() == 0
end

function modifier_item_aphotic_orb_buff:IsActive()
    if(self._isActive ~= nil) then
        return self._isActive
    end
    return false
end

function modifier_item_aphotic_orb_buff:SetIsActive(value)
    self._isActive = value
    if(value == true) then
        self:OnActivated()
    end
end

function modifier_item_aphotic_orb_buff:OnActivated()
    self:ForceRefresh()
    self:SetStackCount(self:GetCapacity())
    local radius = self.parent:GetModelRadius() * 0.9
    local particle = ParticleManager:CreateParticle(
        "particles/custom/items/aphotic_orb/buff.vpcf",
        PATTACH_CUSTOMORIGIN,
        nil
    )
    ParticleManager:SetParticleControlEnt(particle, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
    ParticleManager:SetParticleControl(particle, 8, Vector(radius, radius, radius))
    self:AddParticle(particle, false, false, 1, false, false)
end

function modifier_item_aphotic_orb_buff:SetCapacity(value)
    self._capacity = value
end

function modifier_item_aphotic_orb_buff:GetCapacity()
    return self._capacity or 0
end

function modifier_item_aphotic_orb_buff:GetModifierIncomingDamage_Percentage(kv)
    if(self:IsActive() == false) then
        return 0
    end
    local capacity = self:GetStackCount()
    local newDamage = kv.damage
    if (capacity > 0) then
        if (kv.damage >= capacity) then
            newDamage = kv.damage - capacity
            self:Destroy()
            return (1 - (newDamage / kv.damage)) * -100
        else
            self:SetStackCount(capacity - kv.damage)
            return -999999
        end
    end
end

LinkLuaModifier("modifier_item_aphotic_orb", "items/neutral_items/aphotic_orb", LUA_MODIFIER_MOTION_NONE, modifier_item_aphotic_orb)
LinkLuaModifier("modifier_item_aphotic_orb_active", "items/neutral_items/aphotic_orb", LUA_MODIFIER_MOTION_NONE, modifier_item_aphotic_orb_active)
LinkLuaModifier("modifier_item_aphotic_orb_buff", "items/neutral_items/aphotic_orb", LUA_MODIFIER_MOTION_NONE, modifier_item_aphotic_orb_buff)