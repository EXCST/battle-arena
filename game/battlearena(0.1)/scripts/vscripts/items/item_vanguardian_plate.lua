require('items/generic_datadriven_item')

item_vanguardian_plate = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_vanguardian_plate"
    end
})

function item_vanguardian_plate:Precache(context)
    PrecacheResource("particle", "particles/custom/items/paladin_plate/active/active.vpcf", context)
end

function item_vanguardian_plate:OnSpellStart()
    local caster = self:GetCaster()
    local heal_amount = self:GetSpecialValueFor("heal_amount")

    local healingDone = caster:Heal(heal_amount, self, DOTA_HEAL_TYPE_HEALING)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, healingDone, nil)
    local particle = ParticleManager:CreateParticle("particles/custom/items/paladin_plate/active/active.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle, 1, Vector(65, 65, 65))
    ParticleManager:ReleaseParticleIndex(particle, 2)
    EmitSoundOn("PaladinPlate.Activate", caster)
end

modifier_item_vanguardian_plate = class({
	IsHidden = function() 
        return true 
    end,
    IsPurgable = function()
        return false
    end,
    IsPurgeException = function()
        return false
    end,
	GetAttributes = function() 
        return MODIFIER_ATTRIBUTE_MULTIPLE 
    end,
    DeclareFunctions  = function() 
        return 
        {
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
            MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
})

function modifier_item_vanguardian_plate:OnCreated( params )
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_vanguardian_plate:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonus_allstats = self:GetAbility():GetSpecialValueFor("bonus_allstats")
    self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
    self.bonus_hp_regen = self.ability:GetSpecialValueFor("bonus_hp_regen")

    self.block_value = self.ability:GetSpecialValueFor("block_value")
    self.block_chance = self.ability:GetSpecialValueFor("block_chance")
end

function modifier_item_vanguardian_plate:GetModifierBonusHealth()
	return self.bonus_health
end

function modifier_item_vanguardian_plate:GetModifierConstantHealthRegen()
    return self.bonus_hp_regen
end

function modifier_item_vanguardian_plate:GetModifierPhysical_ConstantBlock()
    if RollPercentage(self.block_chance) then
        return self.block_value
    end
end

function modifier_item_vanguardian_plate:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_vanguardian_plate:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_vanguardian_plate:GetModifierBonusStats_Intellect()
    return self.bonus_allstats
end

LinkLuaModifier("modifier_item_vanguardian_plate", "items/item_vanguardian_plate", LUA_MODIFIER_MOTION_NONE, modifier_item_vanguardian_plate)