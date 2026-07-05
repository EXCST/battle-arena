item_unifying_totem = class({
    GetCastRange = function(self)
        return self:GetSpecialValueFor("totem_radius")
    end,
    GetIntrinsicModifierName = function()
        return "modifier_item_unifying_totem"
    end
})

function item_unifying_totem:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    CreateModifierThinker(
        caster,
        self,
        "modifier_item_unifying_totem_aura",
        {
            duration = self:GetSpecialValueFor("totem_duration"),
        },
        caster:GetAbsOrigin(),
        caster:GetTeamNumber(),
        false
    )
    EmitSoundOn("Item.UnifyingTotem.Cast", caster)
end

modifier_item_unifying_totem = class({
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
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS
        }
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.bonusInt
    end,
    GetModifierBonusStats_Agility = function(self)
        return self.bonusAgi
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_unifying_totem:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_unifying_totem:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusInt = self.ability:GetSpecialValueFor("bonus_strength")
    self.bonusAgi = self.ability:GetSpecialValueFor("bonus_agility")
end

modifier_item_unifying_totem_aura = class({
    IsHidden = function()
        return true
    end,
    IsPurgable = function()
        return false
    end,
    IsDebuff = function()
        return false
    end,
    RemoveOnDeath = function()
        return false
    end,
    IsAuraActiveOnDeath = function()
        return false
    end,
    GetAuraRadius = function(self)
        return self.radius
    end,
    GetAuraSearchFlags = function(self)
        return self.targetFlags
    end,
    GetAuraSearchTeam = function(self)
        return self.targetTeam
    end,
    IsAura = function()
        return true
    end,
    GetAuraSearchType = function(self)
        return self.targetType
    end,
    GetModifierAura = function()
        return "modifier_item_unifying_totem_aura_buff"
    end,
    GetAuraDuration = function()
        return 0
    end
})

function modifier_item_unifying_totem_aura:OnCreated()
    if (not IsServer()) then
        return
    end
    self.ability = self:GetAbility()
    self.caster = self.ability:GetCaster()
    self.radius = self.ability:GetSpecialValueFor("totem_radius")
    self.stacksCap = self.ability:GetSpecialValueFor("totem_allies_limit")
    self.targetType = self.ability:GetAbilityTargetType()
    self.targetTeam = self.ability:GetAbilityTargetTeam()
    self.targetFlags = self.ability:GetAbilityTargetFlags()
    self.parent = self:GetParent()
    self.arenaPosition = self.parent:GetAbsOrigin()
    self.parentTeam = self.parent:GetTeamNumber()
    local pidx = ParticleManager:CreateParticle("particles/custom/items/unifying_totem/ring.vpcf", PATTACH_ABSORIGIN, self.parent)
    ParticleManager:SetParticleControl(pidx, 10, Vector(self.radius, self:GetDuration(), 0))
    self:AddParticle(pidx, false, false, 1, true, false)
    StartSoundEvent("Item.UnifyingTotem.FP", self.parent)
    self.tickInterval = 0.05
    self.currentTickInterval = 0
    self.soundDuration = 6.730499
    self:StartIntervalThink(0.05)
end

function modifier_item_unifying_totem_aura:OnIntervalThink()
    if (not IsServer()) then
        return
    end
    self.currentTickInterval = self.currentTickInterval + self.tickInterval
    if(self.currentTickInterval > self.soundDuration) then
        StartSoundEvent("Item.UnifyingTotem.FP", self.parent)
        self.currentTickInterval = 0
    end
    local allies = FindUnitsInRadius(
        self.parentTeam,
        self.arenaPosition,
        nil,
        self.radius,
        self.targetTeam,
        self.targetType,
        self.targetFlags,
        FIND_ANY_ORDER,
        false
    )
    local currentStacks = 0
    for _, ally in pairs(allies) do
        if(ally:IsControllableByAnyPlayer() == true) then
            currentStacks = currentStacks + 1
        end
    end
    for _, ally in pairs(allies) do
        local modifier = ally:FindModifierByName(self:GetModifierAura())
        if (modifier) then
            modifier:SetStackCount(math.min(currentStacks, self.stacksCap))
        end
    end
end

function modifier_item_unifying_totem_aura:GetAuraEntityReject(npc)
    return npc:GetMainControllingPlayer() < 0
end

function modifier_item_unifying_totem_aura:OnDestroy()
    if (not IsServer()) then
        return
    end
    StopSoundEvent("Item.UnifyingTotem.FP", self.parent)
    UTIL_Remove(self.parent)
end

modifier_item_unifying_totem_aura_buff = class({
    IsHidden = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    IsDebuff = function()
        return false
    end,
    RemoveOnDeath = function()
        return true
    end,
    DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
            MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
            MODIFIER_PROPERTY_ROSHDEF_LIFESTEAL,
            MODIFIER_PROPERTY_TOOLTIP
        }
    end,
    GetModifierLifestealPercantage = function(self)
        return self.lifestealPerStack * self:GetStackCount()
    end,
    GetModifierPhysicalArmorBonus = function(self)
        return self.armorPerStack * self:GetStackCount()
    end,
    GetModifierPreAttack_BonusDamage = function(self)
        return self.damagePerStack * self:GetStackCount()
    end,
    OnTooltip = function(self)
        return self:GetModifierLifestealPercantage()
    end
})

function modifier_item_unifying_totem_aura_buff:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_unifying_totem_aura_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.lifestealPerStack = self.ability:GetSpecialValueFor("bonus_lifesteal_per_ally_pct")
    self.armorPerStack = self.ability:GetSpecialValueFor("bonus_armor_per_ally")
    self.damagePerStack = self.ability:GetSpecialValueFor("bonus_damage_per_ally")
end

LinkLuaModifier("modifier_item_unifying_totem", "items/neutral_items/unifying_totem", LUA_MODIFIER_MOTION_NONE, modifier_item_unifying_totem)
LinkLuaModifier("modifier_item_unifying_totem_aura", "items/neutral_items/unifying_totem", LUA_MODIFIER_MOTION_NONE, modifier_item_unifying_totem_aura)
LinkLuaModifier("modifier_item_unifying_totem_aura_buff", "items/neutral_items/unifying_totem", LUA_MODIFIER_MOTION_NONE, modifier_item_unifying_totem_aura_buff)