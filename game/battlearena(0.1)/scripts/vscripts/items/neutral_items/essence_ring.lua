item_essence_ring_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_essence_ring_custom"
    end
})

function item_essence_ring_custom:Precache(context)
    PrecacheResource("particle", "particles/items5_fx/essence_ring.vpcf", context)
end

function item_essence_ring_custom:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
    caster:AddNewModifier(caster, self, "modifier_item_essence_ring_custom_buff", {duration = self:GetSpecialValueFor("health_gain_duration")})
    caster:SetHealth(caster:GetHealth() + self:GetSpecialValueFor("health_gain"))
    EmitSoundOn("Item.EssenceRing.Cast", caster)
end

modifier_item_essence_ring_custom = class({
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
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.bonusInt
    end,
    GetModifierConstantManaRegen = function(self)
        return self.bonusManaRegeneration
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_essence_ring_custom:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_essence_ring_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusInt = self.ability:GetSpecialValueFor("bonus_int")
    self.bonusManaRegeneration = self.ability:GetSpecialValueFor("mp_regen")
end

modifier_item_essence_ring_custom_buff = class({
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
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_TOOLTIP
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
    RemoveOnDeath = function()
        return false
    end,
    GetTexture = function(self)
        return self.buffIcon
    end
})

function modifier_item_essence_ring_custom_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
        return
    end
    local particle = ParticleManager:CreateParticle("particles/items5_fx/essence_ring.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
    ParticleManager:SetParticleControlEnt(particle, 1, self.parent, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
    self:AddParticle(particle, false, false, 1, false, true)
end

function modifier_item_essence_ring_custom_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusHealth = self.ability:GetSpecialValueFor("health_gain")
end

function modifier_item_essence_ring_custom_buff:GetModifierBonusHealth()
	return self.bonusHealth
end

function modifier_item_essence_ring_custom_buff:OnTooltip()
    return self.bonusHealth
end

LinkLuaModifier("modifier_item_essence_ring_custom", "items/neutral_items/essence_ring", LUA_MODIFIER_MOTION_NONE, modifier_item_essence_ring_custom)
LinkLuaModifier("modifier_item_essence_ring_custom_buff", "items/neutral_items/essence_ring", LUA_MODIFIER_MOTION_NONE, modifier_item_essence_ring_custom_buff)