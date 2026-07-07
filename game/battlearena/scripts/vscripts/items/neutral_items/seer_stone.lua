item_seer_stone_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_seer_stone_custom"
    end,
    GetAOERadius = function(self)
        return self:GetSpecialValueFor("radius")
    end
})

function item_seer_stone_custom:Precache(context)
    PrecacheResource("particle", "particles/items4_fx/seer_stone.vpcf", context)
end

function item_seer_stone_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local location = self:GetCursorPosition()
    local duration = self:GetSpecialValueFor("duration")
    local radius = self:GetAOERadius()
    local particle = ParticleManager:CreateParticle(
        "particles/items4_fx/seer_stone.vpcf", 
        PATTACH_CUSTOMORIGIN,
        nil
    )
    ParticleManager:SetParticleControl(particle, 0, location)
    ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
    ParticleManager:ReleaseParticleIndex(particle, duration)
    AddFOWViewer(caster:GetTeamNumber(), location, radius, duration, false)
    EmitSoundOnLocationWithCaster(location, "Item.SeerStone.Cast", caster)
end

modifier_item_seer_stone_custom = class({
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
            MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
            MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
            MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
            MODIFIER_PROPERTY_BONUS_DAY_VISION
        }
    end,
    GetModifierSpellAmplify_Percentage = function(self)
        return self.bonusSpellAmplifyPct
    end,
    GetModifierCastRangeBonusStacking = function(self)
        return self.bonusCastRange
    end,
    GetBonusDayVision = function(self)
        return self.bonusVision
    end,
    GetBonusNightVision = function(self)
        return self.bonusVision
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_seer_stone_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_seer_stone_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusSpellAmplifyPct = self.ability:GetSpecialValueFor("bonus_spell_amp")
    self.bonusCastRange = self.ability:GetSpecialValueFor("cast_range_bonus")
    self.bonusVision = self.ability:GetSpecialValueFor("vision_bonus")
end

LinkLuaModifier("modifier_item_seer_stone_custom", "items/neutral_items/seer_stone", LUA_MODIFIER_MOTION_NONE, modifier_item_seer_stone_custom)