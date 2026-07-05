item_demonicon_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_demonicon_custom"
    end
})

function item_demonicon_custom:Precache(context)
    PrecacheResource("particle", "particles/items_fx/necronomicon_spawn_warrior.vpcf", context)
    PrecacheResource("particle", "particles/items_fx/necronomicon_spawn.vpcf", context)
    PrecacheUnitByNameSync("npc_dota_tanker_summon", context)
    PrecacheUnitByNameSync("npc_dota_auraman_summon", context)
end

function item_demonicon_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local position = caster:GetAbsOrigin()
    local casterPlayerID = caster:GetPlayerOwnerID()
    local duration = self:GetSpecialValueFor("summon_duration")
    for _, summon in pairs(PlayerResource:GetDemoniconSummons(casterPlayerID)) do
        self:KillDemon(summon)
    end
    PlayerResource:AddDemoniconSummon(
        casterPlayerID,
        self:SpawnDemon("npc_dota_tanker_summon", position, caster, "particles/items_fx/necronomicon_spawn_warrior.vpcf", duration, casterPlayerID)
    )  
    PlayerResource:AddDemoniconSummon(
        casterPlayerID,
        self:SpawnDemon("npc_dota_auraman_summon", position, caster, "particles/items_fx/necronomicon_spawn.vpcf", duration, casterPlayerID)
    )  
end

function item_demonicon_custom:SpawnDemon(name, position, caster, particle, duration, casterPlayerID)
    local summon = CreateSummon(
        caster, 
        name, 
        position, 
        duration, 
        nil, 
        nil, 
        nil, 
        nil
    )
    local particle = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN, summon)
	ParticleManager:ReleaseParticleIndex(particle, 2)
    summon:AddNewModifier(caster, self, "modifier_item_demonicon_custom_summon", {duration = -1})
    EmitSoundOn("Item.Necronomicon.Cast", summon)
    return summon
end

function item_demonicon_custom:KillDemon(demon)
    demon:Kill(nil,nil)
end

modifier_item_demonicon_custom = class({
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
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
        }
    end,
    GetModifierBonusStats_Strength = function(self)
        return self.bonusStr
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.bonusInt
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_demonicon_custom:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_demonicon_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusStr = self.ability:GetSpecialValueFor("bonus_strength")
    self.bonusInt = self.ability:GetSpecialValueFor("bonus_intellect")
end

modifier_item_demonicon_custom_summon = class({
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
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH_PERCENTAGE,
			MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
            MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
            MODIFIER_EVENT_ON_DEATH
        }
    end,
    GetModifierBonusHealthPercentage = function(self)
        return self.bonusHealthPct
    end,
    GetModifierBaseDamageOutgoing_Percentage = function(self)
        return self.bonusDamage
    end,
    GetModifierSpellAmplify_Percentage = function(self)
        return self.bonusDamage
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_demonicon_custom_summon:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_demonicon_custom_summon:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusHealthPct = self.ability:GetSpecialValueFor("summon_bonus_health_pct")
    self.bonusDamage = self.ability:GetSpecialValueFor("summon_bonus_damage_pct")
end

function modifier_item_demonicon_custom_summon:OnDeath(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    EmitSoundOn("Item.Necronomicon.Death", self.parent)
end

LinkLuaModifier("modifier_item_demonicon_custom", "items/neutral_items/demonicon_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_demonicon_custom)
LinkLuaModifier("modifier_item_demonicon_custom_summon", "items/neutral_items/demonicon_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_demonicon_custom_summon)