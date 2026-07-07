item_church_pendant = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_church_pendant"
    end
})

function item_church_pendant:Precache(context)
    PrecacheResource("particle", "particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", context)
    PrecacheResource("particle", "particles/custom/items/church_pendant/church_pendant.vpcf", context)
end

function item_church_pendant:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    target:AddNewModifier(caster, self, "modifier_item_church_pendant_buff", {duration = self:GetSpecialValueFor("shield_duration")})
    target:Purge(false, true, false, true, true)
    local particle = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", 
        PATTACH_ABSORIGIN_FOLLOW, 
        target
    )
    ParticleManager:SetParticleControl(particle, 1, Vector(120, 120, 120))
    ParticleManager:ReleaseParticleIndex(particle, 2)
    EmitSoundOn("Item.ChurchPendant.Cast", target)
end

modifier_item_church_pendant = class({
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
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_HEAL_CAUSED_PERCENTAGE
        }
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
    GetModifierHealCaused_Percentage = function(self)
        return self.bonusHealingAmp
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_church_pendant:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self:StartIntervalThink(0.2)
end

function modifier_item_church_pendant:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusPrimaryAttribute = self.ability:GetSpecialValueFor("bonus_primary_attribute")
    self.bonusHealingAmp = self.ability:GetSpecialValueFor("bonus_heal_amp_pct")
end

function modifier_item_church_pendant:OnIntervalThink()
    if(not self.parent.GetPrimaryAttribute) then
        return
    end
    self:SetStackCount(self.parent:GetPrimaryAttribute())
end

function modifier_item_church_pendant:GetModifierBonusStats_Strength()
    if(self.parent:IsRealHero() == false) then
        return
    end
    if(self:GetStackCount() == DOTA_ATTRIBUTE_STRENGTH) then
        return self.bonusPrimaryAttribute
    end
    return 0
end

function modifier_item_church_pendant:GetModifierBonusStats_Agility()
    if(self.parent:IsRealHero() == false) then
        return
    end
    if(self:GetStackCount() == DOTA_ATTRIBUTE_AGILITY) then
        return self.bonusPrimaryAttribute
    end
    return 0
end

function modifier_item_church_pendant:GetModifierBonusStats_Intellect()
    if(self.parent:IsRealHero() == false) then
        return
    end
    if(self:GetStackCount() == DOTA_ATTRIBUTE_INTELLECT) then
        return self.bonusPrimaryAttribute
    end
    return 0
end

modifier_item_church_pendant_buff = class({
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
            MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
            MODIFIER_PROPERTY_TOOLTIP
        }
    end,
    OnTooltip = function(self)
        return self:GetStackCount()
    end,
    GetEffectName = function()
        return "particles/custom/items/church_pendant/church_pendant.vpcf"
    end,
    GetTexture = function(self)
        return self.buffIcon
    end,
})

function modifier_item_church_pendant_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
    end
end

function modifier_item_church_pendant_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local healing = 0
    if(caster.GetPrimaryStatValue) then
        healing = caster:GetPrimaryStatValue() * (self.ability:GetSpecialValueFor("primary_attribute_to_heal_pct") / 100)
    end
    local missingHealth = self.parent:GetMaxHealth() - self.parent:GetHealth()
    self.parent:Heal(healing, self.ability)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self.parent, healing, nil)
    local overheal = healing - missingHealth
    if(overheal > 0) then
        self:SetStackCount(overheal)
    end
end

function modifier_item_church_pendant_buff:GetModifierIncomingDamage_Percentage(kv)
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

LinkLuaModifier("modifier_item_church_pendant", "items/neutral_items/church_pendant", LUA_MODIFIER_MOTION_NONE, modifier_item_church_pendant)
LinkLuaModifier("modifier_item_church_pendant_buff", "items/neutral_items/church_pendant", LUA_MODIFIER_MOTION_NONE, modifier_item_church_pendant_buff)