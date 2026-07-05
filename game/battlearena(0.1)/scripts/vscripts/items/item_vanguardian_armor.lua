require('items/generic_datadriven_item')

item_vanguardian_armor = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_vanguardian_armor"
    end
})

item_vanguardian_armor_1 = class(item_vanguardian_armor)
item_vanguardian_armor_2 = class(item_vanguardian_armor)
item_vanguardian_armor_3 = class(item_vanguardian_armor)

modifier_item_vanguardian_armor = class({
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
            MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
            MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
            MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end,
})

function modifier_item_vanguardian_armor:OnCreated( params )
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_vanguardian_armor:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
   
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.bonus_hp_regen = self.ability:GetSpecialValueFor("bonus_hp_regen")

    self.block_value = self.ability:GetSpecialValueFor("block_value")
    self.block_chance = self.ability:GetSpecialValueFor("block_chance")
end

function modifier_item_vanguardian_armor:GetModifierBonusHealth()
	return self.bonus_health
end

function modifier_item_vanguardian_armor:GetModifierConstantHealthRegen()
    return self.bonus_hp_regen
end

function modifier_item_vanguardian_armor:GetModifierPhysical_ConstantBlock()
    if RollPercentage(self.block_chance) then
        return self.block_value
    end
end

LinkLuaModifier("modifier_item_vanguardian_armor", "items/item_vanguardian_armor", LUA_MODIFIER_MOTION_NONE, modifier_item_vanguardian_armor)