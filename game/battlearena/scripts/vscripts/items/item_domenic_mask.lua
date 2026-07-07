require('items/generic_datadriven_item')

item_domenic_mask = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_domenic_mask"
    end
})

function item_domenic_mask:Precache(context)
    PrecacheResource("particle", "particles/items2_fx/mask_of_madness.vpcf", context)
end

function item_domenic_mask:OnSpellStart()
    local duration = self:GetSpecialValueFor("duration")
    local caster = self:GetCaster()
    
    caster:AddNewModifier(caster, self, "modifier_item_domenic_mask_buff", {duration = duration})
    caster:EmitSound("MaskOfMadness.Activate")
end

item_domenic_mask_1 = class(item_domenic_mask)
item_domenic_mask_2 = class(item_domenic_mask)
item_domenic_mask_3 = class(item_domenic_mask)

item_sadistic_mask_1 = class(item_domenic_mask)
item_sadistic_mask_2 = class(item_domenic_mask)
item_sadistic_mask_3 = class(item_domenic_mask)

item_inner_mad_1 = class(item_domenic_mask)
item_inner_mad_2 = class(item_domenic_mask)
item_inner_mad_3 = class(item_domenic_mask)

modifier_item_domenic_mask = class({
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
            MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
            MODIFIER_PROPERTY_ROSHDEF_LIFESTEAL,
            MODIFIER_EVENT_ON_ATTACK_LANDED
        }
    end,
    GetModifierLifestealPercantage = function(self)
        return self.lifesteal
    end
})

function modifier_item_domenic_mask:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_domenic_mask:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
    self.bonus_attack_speed = self.ability:GetSpecialValueFor("bonus_attack_speed")
    self.crit_chance = self.ability:GetSpecialValueFor("crit_chance")
    self.crit_multiplier = self.ability:GetSpecialValueFor("crit_multiplier")
    self.lifesteal = self.ability:GetSpecialValueFor("lifesteal")
    self.lifesteal_flat = self.ability:GetSpecialValueFor("lifesteal_flat")
end

function modifier_item_domenic_mask:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage
end

function modifier_item_domenic_mask:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_attack_speed
end

function modifier_item_domenic_mask:OnAttackLanded(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    self.parent:PerformLifesteal(kv.target, self.lifesteal_flat)
end

modifier_item_domenic_mask_buff = class({
    IsHidden = function() 
        return false 
    end,
	GetAttributes = function() 
        return MODIFIER_ATTRIBUTE_MULTIPLE 
    end,
	DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
        }
    end,
    GetEffectName = function()
        return "particles/items2_fx/mask_of_madness.vpcf"
    end
})

function modifier_item_domenic_mask_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_domenic_mask_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.buff_attack_speed = self.ability:GetSpecialValueFor("buff_attack_speed")
    self.buff_move_speed_pct = self.ability:GetSpecialValueFor("buff_move_speed_pct")
    self.incoming_damage_pct = self.ability:GetSpecialValueFor("incoming_damage_pct")
end

function modifier_item_domenic_mask_buff:GetModifierAttackSpeedBonus_Constant()
    return self.buff_attack_speed
end

function modifier_item_domenic_mask_buff:GetModifierMoveSpeedBonus_Percentage()
    return self.buff_move_speed_pct
end

function modifier_item_domenic_mask_buff:GetModifierIncomingDamage_Percentage()
    return self.incoming_damage_pct
end

LinkLuaModifier("modifier_item_domenic_mask", "items/item_domenic_mask", LUA_MODIFIER_MOTION_NONE, modifier_item_domenic_mask)
LinkLuaModifier("modifier_item_domenic_mask_buff", "items/item_domenic_mask", LUA_MODIFIER_MOTION_NONE, modifier_item_domenic_mask_buff)
