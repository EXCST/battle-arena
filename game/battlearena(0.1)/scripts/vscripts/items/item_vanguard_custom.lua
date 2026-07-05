require('items/generic_datadriven_item')

item_vanguard_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_vanguard_custom"
    end
})

item_knight_bulwark = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_knight_bulwark"
    end
})

item_vanguard_custom_1 = class(item_vanguard_custom)
item_vanguard_custom_2 = class(item_vanguard_custom)
item_vanguard_custom_3 = class(item_vanguard_custom)

item_viking_shield_1 = class(item_vanguard_custom)
item_viking_shield_2 = class(item_vanguard_custom)
item_viking_shield_3 = class(item_vanguard_custom)

item_knight_bulwark_1 = class(item_knight_bulwark)
item_knight_bulwark_2 = class(item_knight_bulwark)
item_knight_bulwark_3 = class(item_knight_bulwark)

modifier_item_vanguard_custom = class({
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

function modifier_item_vanguard_custom:OnCreated( params )
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_vanguard_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
   
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.bonus_hp_regen = self.ability:GetSpecialValueFor("bonus_hp_regen")

    self.block_value = self.ability:GetSpecialValueFor("block_value")
    self.block_chance = self.ability:GetSpecialValueFor("block_chance")
end

function modifier_item_vanguard_custom:GetModifierBonusHealth()
	return self.bonus_health
end

function modifier_item_vanguard_custom:GetModifierConstantHealthRegen()
    return self.bonus_hp_regen
end

function modifier_item_vanguard_custom:GetModifierPhysical_ConstantBlock()
    if RollPercentage(self.block_chance) then
        return self.block_value
    end
end


modifier_item_knight_bulwark = class({
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

function modifier_item_knight_bulwark:OnCreated( params )
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_knight_bulwark:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
   
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.bonus_hp_regen = self.ability:GetSpecialValueFor("bonus_hp_regen")

    self.block_value = self.ability:GetSpecialValueFor("block_value")
    self.block_chance = self.ability:GetSpecialValueFor("block_chance")

    self.superblock_chance = self.ability:GetSpecialValueFor("superblock_chance")
    self.superblock_value = self.ability:GetSpecialValueFor("superblock_value")
end

function modifier_item_knight_bulwark:GetModifierBonusHealth()
    return self.bonus_health
end

function modifier_item_knight_bulwark:GetModifierConstantHealthRegen()
    return self.bonus_hp_regen
end

function modifier_item_knight_bulwark:GetModifierPhysical_ConstantBlock()
    if RollPercentage(self.superblock_chance) then
        return self.superblock_value
    elseif RollPercentage(self.block_chance) then
        return self.block_value
    end
end
LinkLuaModifier("modifier_item_vanguard_custom", "items/item_vanguard_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_vanguard_custom)
LinkLuaModifier("modifier_item_knight_bulwark", "items/item_vanguard_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_knight_bulwark)
