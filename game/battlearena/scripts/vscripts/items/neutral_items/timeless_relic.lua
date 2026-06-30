item_timeless_relic_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_timeless_relic_custom"
    end
})

function item_timeless_relic_custom:Precache(context)
    PrecacheResource("particle", "particles/custom/items/timeless_relic/effect.vpcf", context)
end

modifier_item_timeless_relic_custom = class({
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
            MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
            MODIFIER_EVENT_ROSHDEF_ON_PRE_MODIFIER_ADDED,
            MODIFIER_PROPERTY_ROSHDEF_DEBUFFS_DURATION_AMPLIFICATION_PERCENT
        }
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.bonusInt
    end,
    GetModifierSpellAmplify_Percentage = function(self)
        return self.bonusSpellAmplify
    end,
    GetModifierDebuffsDurationAmplificationPercent = function(self)
        return self.bonusDebuffsDurationPct
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_timeless_relic_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    self.reflectStates = {
        [MODIFIER_STATE_HEXED] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_FROZEN] = true
    }
end

function modifier_item_timeless_relic_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusInt = self.ability:GetSpecialValueFor("bonus_int")
    self.bonusSpellAmplify = self.ability:GetSpecialValueFor("bonus_spell_amp")
    self.bonusDebuffsDurationPct = self.ability:GetSpecialValueFor("debuff_amp")
end

function modifier_item_timeless_relic_custom:OnPreModifierAdded(kv)
    if(kv.unit ~= self.parent) then
        return
    end
    if(self.ability:IsCooldownReady() == false) then
        return
    end
    if(kv.modifier:IsDebuff() == false) then
        return
    end
    local isModifierToReflect = false
    local modifierState = {} 
    kv.modifier:CheckStateToTable(modifierState)
    for state, value in pairs(modifierState) do
        if(self.reflectStates[tonumber(state) or -1] ~= nil and value == true) then
            isModifierToReflect = true
            break
        end
    end
    if(isModifierToReflect == false) then
        return
    end
    local source = kv.modifier:GetCaster()
    source:AddNewModifier(source, kv.modifier:GetAbility(), kv.modifier:GetName(), {duration = kv.modifier:GetDuration()})
    kv.modifier:Destroy()
    self.ability:UseResources(true, false, true, true)
    local particle = ParticleManager:CreateParticle(
        "particles/custom/items/timeless_relic/effect.vpcf", 
        PATTACH_CUSTOMORIGIN, 
        nil
    )
    ParticleManager:SetParticleControlEnt(particle, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
    ParticleManager:SetParticleControlEnt(particle, 1, source, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
    ParticleManager:ReleaseParticleIndex(particle, 2)
    EmitSoundOn("Item.TimelessRelic.Proc", self.parent)
end

LinkLuaModifier("modifier_item_timeless_relic_custom", "items/neutral_items/timeless_relic", LUA_MODIFIER_MOTION_NONE, modifier_item_timeless_relic_custom)