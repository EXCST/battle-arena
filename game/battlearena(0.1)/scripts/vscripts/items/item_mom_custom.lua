require('items/generic_datadriven_item')

item_mom_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_mom_custom"
    end
})

function item_mom_custom:Precache(context)
    PrecacheResource("particle", "particles/items2_fx/mask_of_madness.vpcf", context)
end

function item_mom_custom:OnSpellStart()
    local duration = self:GetSpecialValueFor("duration")
    local caster = self:GetCaster()
    
    caster:AddNewModifier(caster, self, "modifier_item_mom_custom_buff", {duration = duration})
    caster:EmitSound("MaskOfMadness.Activate")
end

item_mask_of_madness_custom_1 = class(item_mom_custom)
item_mask_of_madness_custom_2 = class(item_mom_custom)
item_mask_of_madness_custom_3 = class(item_mom_custom)

item_sadistic_mask_1 = class(item_mom_custom)
item_sadistic_mask_2 = class(item_mom_custom)
item_sadistic_mask_3 = class(item_mom_custom)

item_inner_mad_1 = class(item_mom_custom)
item_inner_mad_2 = class(item_mom_custom)
item_inner_mad_3 = class(item_mom_custom)

modifier_item_mom_custom = class({
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

function modifier_item_mom_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_mom_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
    self.bonus_attack_speed = self.ability:GetSpecialValueFor("bonus_attack_speed")
    self.lifesteal = self.ability:GetSpecialValueFor("lifesteal")
    self.lifesteal_flat = self.ability:GetSpecialValueFor("lifesteal_flat")
end

function modifier_item_mom_custom:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage
end

function modifier_item_mom_custom:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_attack_speed
end

function modifier_item_mom_custom:OnAttackLanded(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    self.parent:PerformLifesteal(kv.target, self.lifesteal_flat)
end

modifier_item_mom_custom_buff = class({
    IsHidden = function() 
        return false 
    end,
	DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
            MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        }
    end,
    GetEffectName = function()
        return "particles/items2_fx/mask_of_madness.vpcf"
    end
})

function modifier_item_mom_custom_buff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_mom_custom_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.buff_attack_speed = self.ability:GetSpecialValueFor("buff_attack_speed")
    self.buff_move_speed_pct = self.ability:GetSpecialValueFor("buff_move_speed_pct")
    self.incoming_damage_pct = self.ability:GetSpecialValueFor("incoming_damage_pct")
    self.outgoing_damage_pct = self.ability:GetSpecialValueFor("outgoing_damage_pct") or 0
end

function modifier_item_mom_custom_buff:GetModifierAttackSpeedBonus_Constant()
    return self.buff_attack_speed
end

function modifier_item_mom_custom_buff:GetModifierMoveSpeedBonus_Percentage()
    return self.buff_move_speed_pct
end

function modifier_item_mom_custom_buff:GetModifierIncomingDamage_Percentage()
    return self.incoming_damage_pct
end

function modifier_item_mom_custom_buff:GetModifierDamageOutgoing_Percentage()
    return self.outgoing_damage_pct
end

LinkLuaModifier("modifier_item_mom_custom", "items/item_mom_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_mom_custom)
LinkLuaModifier("modifier_item_mom_custom_buff", "items/item_mom_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_mom_custom_buff)
