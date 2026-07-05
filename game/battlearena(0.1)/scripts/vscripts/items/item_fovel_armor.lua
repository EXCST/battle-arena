require('items/generic_datadriven_item')

item_fovel_armor = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_fovel_armor"
    end
})

function item_fovel_armor:Precache(context)
    PrecacheResource("particle", "particles/custom/items/fovel_armor/active/active.vpcf", context)
end

function item_fovel_armor:OnSpellStart()
    local caster = self:GetCaster()
    local heal_amount = self:GetSpecialValueFor("heal_amount")
    local heal_amount_pct = self:GetSpecialValueFor("heal_amount_pct")/100*caster:GetMaxHealth()
    local healing = caster:Heal(heal_amount+heal_amount_pct, self, DOTA_HEAL_TYPE_HEALING)
    
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, healing, nil)
    local particle = ParticleManager:CreateParticle("particles/custom/items/fovel_armor/active/active.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle, 1, Vector(65, 65, 65))
    ParticleManager:ReleaseParticleIndex(particle, 2)
    EmitSoundOn("PaladinPlate.Activate", caster)
end

item_fovel_armor_1 = class(item_fovel_armor)
item_fovel_armor_2 = class(item_fovel_armor)
item_fovel_armor_3 = class(item_fovel_armor)

item_patanage_armor_1 = class(item_fovel_armor)
item_patanage_armor_2 = class(item_fovel_armor)
item_patanage_armor_3 = class(item_fovel_armor)

item_defender_plate_1 = class(item_fovel_armor)
item_defender_plate_2 = class(item_fovel_armor)
item_defender_plate_3 = class(item_fovel_armor)

modifier_item_fovel_armor = class({
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

function modifier_item_fovel_armor:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_fovel_armor:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
end

function modifier_item_fovel_armor:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_fovel_armor:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_fovel_armor:GetModifierBonusStats_Intellect()
    return self.bonus_allstats
end

function modifier_item_fovel_armor:GetModifierBonusHealth()
	return self.bonus_health
end

LinkLuaModifier("modifier_item_fovel_armor", "items/item_fovel_armor", LUA_MODIFIER_MOTION_NONE, modifier_item_fovel_armor)
