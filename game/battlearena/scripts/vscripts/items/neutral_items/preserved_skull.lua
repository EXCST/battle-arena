item_preserved_skull_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_preserved_skull_custom"
    end
})

function item_preserved_skull_custom:Precache(context)
    PrecacheResource("particle", "particles/custom/items/preserved_skull/preserved_skull.vpcf", context)
end

modifier_item_preserved_skull_custom = class({
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
            MODIFIER_PROPERTY_ROSHDEF_STATS_INTELLECT_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_CASTTIME_PERCENTAGE,
            MODIFIER_PROPERTY_MANACOST_PERCENTAGE,
            MODIFIER_EVENT_ROSHDEF_ON_ABILITY_COOLDOWN_BEGIN
        }
    end,
    GetModifierBonusStats_Strength_Percentage = function(self)
        return self.bonusStrPct
    end,
    GetModifierBonusStats_Agility_Percentage = function(self)
        return self.bonusAgiPct
    end,
    GetModifierBonusStats_Intellect_Percentage = function(self)
        return self.bonusIntPct
    end,
    GetModifierPercentageCasttime = function(self)
        return self.bonusCastTimeReductionPct
    end,
    GetModifierPercentageManacost = function(self)
        return self.bonusManacostReductionPct
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_preserved_skull_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self:StartIntervalThink(0.2)
end

function modifier_item_preserved_skull_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.procChance = self.ability:GetSpecialValueFor("proc_chance")
    self.bonusPrimaryPct = self.ability:GetSpecialValueFor("bonus_primary_attribute_pct")
    self.bonusCastTimeReductionPct = self.ability:GetSpecialValueFor("bonus_cast_time_reduction_pct")
    self.bonusManacostReductionPct = self.ability:GetSpecialValueFor("bonus_manacost_reduction_pct")
end

function modifier_item_preserved_skull_custom:OnIntervalThink()
    if(not self.parent.GetPrimaryAttribute) then
        return
    end
    local primary = self.parent:GetPrimaryAttribute()
    self.bonusStrPct = 0
    self.bonusAgiPct = 0
    self.bonusIntPct = 0
    if(primary == DOTA_ATTRIBUTE_STRENGTH) then
        self.bonusStrPct = self.bonusPrimaryPct
        self.bonusAgiPct = 0
        self.bonusIntPct = 0
    end
    if(primary == DOTA_ATTRIBUTE_AGILITY) then
        self.bonusStrPct = 0
        self.bonusAgiPct = self.bonusPrimaryPct
        self.bonusIntPct = 0
    end
    if(primary == DOTA_ATTRIBUTE_INTELLECT) then
        self.bonusStrPct = 0
        self.bonusAgiPct = 0
        self.bonusIntPct = self.bonusPrimaryPct
    end
    self.parent:CalculateStatBonus(true)
end

function modifier_item_preserved_skull_custom:OnAbilityCooldownBegin(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    if(RollPercentage(self.procChance) == false) then
        return
    end
    local particle = ParticleManager:CreateParticle(
        "particles/custom/items/preserved_skull/preserved_skull.vpcf", 
        PATTACH_CUSTOMORIGIN,
        nil
    )
    ParticleManager:SetParticleControlEnt(particle, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
    ParticleManager:ReleaseParticleIndex(particle, 2)
    kv.ability:EndCooldown()
    kv.ability:IncrementAbilityCharges()
    EmitSoundOn("Item.PreservedSkull.Activate", self.parent)
end

LinkLuaModifier("modifier_item_preserved_skull_custom", "items/neutral_items/preserved_skull", LUA_MODIFIER_MOTION_NONE, modifier_item_preserved_skull_custom)