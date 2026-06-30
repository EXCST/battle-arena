item_arcane_ring_custom = class({
    GetCastRange = function(self)
        return self:GetSpecialValueFor("radius")
    end,
    GetIntrinsicModifierName = function()
        return "modifier_item_arcane_ring_custom"
    end
})

function item_arcane_ring_custom:Precache(context)
    PrecacheResource("particle", "particles/items_fx/arcane_boots.vpcf", context)
    PrecacheResource("particle", "particles/items_fx/arcane_boots_recipient.vpcf", context)
end

function item_arcane_ring_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    local allies = FindUnitsInRadius(
        caster:GetTeamNumber(), 
        caster:GetAbsOrigin(), 
        nil, 
        self:GetCastRange(), 
        self:GetAbilityTargetTeam(), 
        self:GetAbilityTargetType(), 
        self:GetAbilityTargetFlags(), 
        FIND_ANY_ORDER, 
        false
    )
    local bonusMana = self:GetSpecialValueFor("mana_restore")
    for _, ally in pairs(allies) do
        ally:GiveMana(bonusMana)
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, ally, bonusMana, nil)
        local particle = ParticleManager:CreateParticle(
            "particles/items_fx/arcane_boots_recipient.vpcf", 
            PATTACH_ABSORIGIN_FOLLOW,
            ally
        )
        ParticleManager:ReleaseParticleIndex(particle, 2)
    end
    local particle = ParticleManager:CreateParticle(
        "particles/items_fx/arcane_boots.vpcf", 
        PATTACH_ABSORIGIN, 
        caster
    )
    ParticleManager:ReleaseParticleIndex(particle, 2)
    EmitSoundOn("Item.ArcaneRing.Cast", caster)
end

modifier_item_arcane_ring_custom = class({
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
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
        }
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.bonusInt
    end,
    GetModifierPhysicalArmorBonus = function(self)
        return self.bonusArmor
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_arcane_ring_custom:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_arcane_ring_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusInt = self.ability:GetSpecialValueFor("bonus_intelligence")
    self.bonusArmor = self.ability:GetSpecialValueFor("bonus_armor")
end

LinkLuaModifier("modifier_item_arcane_ring_custom", "items/neutral_items/arcane_ring", LUA_MODIFIER_MOTION_NONE, modifier_item_arcane_ring_custom)