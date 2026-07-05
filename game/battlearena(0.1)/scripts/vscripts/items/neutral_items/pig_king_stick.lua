item_pig_king_stick_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_pig_king_stick_custom"
    end,
    GetAOERadius = function(self)
        return self:GetSpecialValueFor("radius")
    end
})

function item_pig_king_stick_custom:Precache(context)
    PrecacheResource("model", "models/props_gameplay/pig.vmdl", context)
end

function item_pig_king_stick_custom:GetCooldown(iLevel)
    local caster = self:GetCaster()
    local baseCooldown = self.BaseClass.GetCooldown(self, iLevel)
    return math.max(baseCooldown * caster:GetCooldownReduction(), self:GetSpecialValueFor("minimal_cd")) / caster:GetCooldownReduction()
end

function item_pig_king_stick_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local position = self:GetCursorPosition()
    local radius = self:GetAOERadius()
    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(), 
        position, 
        nil, 
        radius, 
        self:GetAbilityTargetTeam(), 
        self:GetAbilityTargetType(), 
        self:GetAbilityTargetFlags(), 
        FIND_ANY_ORDER, 
        false
    )
    local duration = self:GetSpecialValueFor("duration")
    for _, enemy in pairs(enemies) do
        enemy:AddNewModifier(caster, self, "modifier_item_pig_king_stick_custom_debuff", {duration = duration})
    end
    EmitSoundOnLocationWithCaster(position, "Item.PigKingStick.Cast", caster)
    local particle = ParticleManager:CreateParticle(
        "particles/custom/items/pig_king_stick/pig_king_stick_last.vpcf", 
        PATTACH_CUSTOMORIGIN, 
        nil
    )
    ParticleManager:SetParticleControl(particle, 0, position)
    ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
    ParticleManager:SetParticleControl(particle, 10, Vector(radius, 0, 0))
    ParticleManager:ReleaseParticleIndex(particle, 2)
end

modifier_item_pig_king_stick_custom = class({
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
            MODIFIER_PROPERTY_ROSHDEF_STATS_STRENGTH_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_STATS_AGILITY_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ROSHDEF_STATS_INTELLECT_BONUS_PERCENTAGE
        }
    end,
    GetModifierBonusStats_Strength_Percentage = function(self)
        return self.bonusStrPct
    end,
    GetModifierBonusStats_Agility_Percentage = function(self)
        return self.bonusAgiPct
    end,
    GetModifierBonusStats_Intellect_Percentage = function(self)
        return self.bonusIntPct + self.bonusAllStatsPct
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_pig_king_stick_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self:StartIntervalThink(0.2)
end

function modifier_item_pig_king_stick_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAllStatsPct = self.ability:GetSpecialValueFor("bonus_allstats_pct")
    self.bonusStrPct = self.bonusAllStatsPct
    self.bonusAgiPct = self.bonusAllStatsPct
    self.bonusIntPct = self.ability:GetSpecialValueFor("bonus_intellect_pct")
end

modifier_item_pig_king_stick_custom_debuff = class({
    IsHidden = function() 
        return false 
    end,
    IsDebuff = function()
        return true
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_MODEL_CHANGE,
            MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
        }
    end,
    CheckState = function()
        return {
            [MODIFIER_STATE_HEXED] = true,
            [MODIFIER_STATE_DISARMED] = true,
            [MODIFIER_STATE_SILENCED] = true
        }
    end,
    GetModifierModelChange = function()
        return "models/props_gameplay/pig.vmdl"
    end,
    GetModifierIncomingDamage_Percentage = function(self)
        return self.bonusIncomingDamagePct
    end,
    IsIgnoreStatusResistance = function()
        return true
    end
})

function modifier_item_pig_king_stick_custom_debuff:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_pig_king_stick_custom_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusIncomingDamagePct = self.ability:GetSpecialValueFor("bonus_incoming_damage_pct")
end

LinkLuaModifier("modifier_item_pig_king_stick_custom", "items/neutral_items/pig_king_stick", LUA_MODIFIER_MOTION_NONE, modifier_item_pig_king_stick_custom)
LinkLuaModifier("modifier_item_pig_king_stick_custom_debuff", "items/neutral_items/pig_king_stick", LUA_MODIFIER_MOTION_NONE, modifier_item_pig_king_stick_custom_debuff)