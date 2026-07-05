require('items/generic_datadriven_item')

item_paladin_plate = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_paladin_plate"
    end
})

function item_paladin_plate:Precache(context)
    PrecacheResource("particle", "particles/custom/items/paladin_plate/active/active.vpcf", context)
end

function item_paladin_plate:OnSpellStart()
    local caster = self:GetCaster()
    local heal_amount = self:GetSpecialValueFor("heal_amount")
    local healing = caster:Heal(heal_amount, self, DOTA_HEAL_TYPE_HEALING)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, healing, nil)
    local particle = ParticleManager:CreateParticle("particles/custom/items/paladin_plate/active/active.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle, 1, Vector(65, 65, 65))
    ParticleManager:ReleaseParticleIndex(particle, 2)
    EmitSoundOn("PaladinPlate.Activate", caster)
end

item_paladin_plate_1 = class(item_paladin_plate)
item_paladin_plate_2 = class(item_paladin_plate)
item_paladin_plate_3 = class(item_paladin_plate)

modifier_item_paladin_plate = class({
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
	DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end
})

function modifier_item_paladin_plate:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_paladin_plate:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
end

function modifier_item_paladin_plate:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_paladin_plate:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_paladin_plate:GetModifierBonusStats_Intellect()
    return self.bonus_allstats
end

function modifier_item_paladin_plate:GetModifierBonusHealth()
	return self.bonus_health
end

LinkLuaModifier("modifier_item_paladin_plate", "items/item_paladin_plate", LUA_MODIFIER_MOTION_NONE, modifier_item_paladin_plate)
