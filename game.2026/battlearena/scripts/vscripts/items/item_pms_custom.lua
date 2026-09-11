require('items/generic_datadriven_item')


item_pms_custom = class({})

function item_pms_custom:OnSpellStart()
    local caster = self:GetCaster()
    local buff_duration = self:GetSpecialValueFor("buff_duration")

    caster:AddNewModifier(caster, self, "modifier_item_pms_custom_buff", {duration = buff_duration})
    caster:EmitSound("Item.CrimsonGuard.Cast")
end

function item_pms_custom:GetIntrinsicModifierName()
	return "modifier_item_pms_custom"
end

modifier_item_pms_custom = class({
	IsHidden 		= function(self) return true end,
    GetAttributes   = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
    DeclareFunctions  = function(self) return {
        MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
    
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }end,
})

function modifier_item_pms_custom:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self:OnRefresh()
end

function modifier_item_pms_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
    self.block_value = self.ability:GetSpecialValueFor("block_value")
    self.block_chance = self.ability:GetSpecialValueFor("block_chance")
    self.buff_block_chance = self.ability:GetSpecialValueFor("buff_block_chance")
end

function modifier_item_pms_custom:GetModifierBonusHealth()
    return self.bonus_health
end

function modifier_item_pms_custom:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_pms_custom:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_pms_custom:GetModifierBonusStats_Intellect()
    return self.bonus_allstats
end

function modifier_item_pms_custom:GetModifierPhysical_ConstantBlock()
	local block_chance = self.block_chance
    if self:GetCaster():HasModifier("modifier_item_pms_custom_buff") then
        block_chance = self.buff_block_chance
    end

    if RollPercentage(block_chance) then
		return self.block_value
	else
		return 
	end
end


modifier_item_pms_custom_buff = class({
    IsHidden        = function(self) return false end,
})

function modifier_item_pms_custom_buff:GetEffectName()
    return "particles/econ/items/rubick/rubick_force_ambient/rubick_telekinesis_force_debuff_b.vpcf"
end

--------------------------------------------------------------
--agi pms
--------------------------------------------------------------
item_pms_agi_custom = class({})

function item_pms_agi_custom:OnSpellStart()
    local caster = self:GetCaster()
    local buff_duration = self:GetSpecialValueFor("buff_duration")

    caster:AddNewModifier(caster, self, "modifier_item_pms_agi_custom_buff", {duration = buff_duration})
    caster:EmitSound("Item.CrimsonGuard.Cast")
end

function item_pms_agi_custom:GetIntrinsicModifierName()
    return "modifier_item_pms_agi_custom"
end

modifier_item_pms_agi_custom = class({
    IsHidden        = function(self) return true end,
    GetAttributes   = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
    DeclareFunctions  = function(self) return {
        MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
    
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }end,
})

function modifier_item_pms_agi_custom:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self:OnRefresh()
end

function modifier_item_pms_agi_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.bonus_agi = self.ability:GetSpecialValueFor("bonus_agi")
    self.block_value = self.ability:GetSpecialValueFor("block_value")
    self.block_chance = self.ability:GetSpecialValueFor("block_chance")
    self.buff_block_chance = self.ability:GetSpecialValueFor("buff_block_chance")
end

function modifier_item_pms_agi_custom:GetModifierBonusHealth()
    return self.bonus_health
end

function modifier_item_pms_agi_custom:GetModifierBonusStats_Agility()
    return self.bonus_agi
end

function modifier_item_pms_agi_custom:GetModifierPhysical_ConstantBlock()
    local block_chance = self.block_chance
    if self:GetCaster():HasModifier("modifier_item_pms_agi_custom_buff") then
        block_chance = self.buff_block_chance
    end

    if RollPercentage(block_chance) then
        return self.block_value
    else
        return 
    end
end


modifier_item_pms_agi_custom_buff = class({
    IsHidden        = function(self) return false end,
})

function modifier_item_pms_agi_custom_buff:GetEffectName()
    return "particles/econ/items/rubick/rubick_force_ambient/rubick_telekinesis_force_debuff_b.vpcf"
end

--------------------------------------------------------------
--str pms
--------------------------------------------------------------
item_pms_str_custom = class({})

function item_pms_str_custom:OnSpellStart()
    local caster = self:GetCaster()
    local buff_duration = self:GetSpecialValueFor("buff_duration")

    caster:AddNewModifier(caster, self, "modifier_item_pms_str_custom_buff", {duration = buff_duration})
    caster:EmitSound("Item.CrimsonGuard.Cast")
end

function item_pms_str_custom:GetIntrinsicModifierName()
    return "modifier_item_pms_str_custom"
end

modifier_item_pms_str_custom = class({
    IsHidden        = function(self) return true end,
    GetAttributes   = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
    DeclareFunctions  = function(self) return {
        MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
    
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }end,
})

function modifier_item_pms_str_custom:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self:OnRefresh()
end

function modifier_item_pms_str_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.bonus_str = self.ability:GetSpecialValueFor("bonus_str")
    self.block_value = self.ability:GetSpecialValueFor("block_value")
    self.block_chance = self.ability:GetSpecialValueFor("block_chance")
    self.buff_block_chance = self.ability:GetSpecialValueFor("buff_block_chance")
end

function modifier_item_pms_str_custom:GetModifierBonusHealth()
    return self.bonus_health
end

function modifier_item_pms_str_custom:GetModifierBonusStats_Strength()
    return self.bonus_str
end

function modifier_item_pms_str_custom:GetModifierPhysical_ConstantBlock()
    local block_chance = self.block_chance
    if self:GetCaster():HasModifier("modifier_item_pms_str_custom_buff") then
        block_chance = self.buff_block_chance
    end

    if RollPercentage(block_chance) then
        return self.block_value
    else
        return 
    end
end


modifier_item_pms_str_custom_buff = class({
    IsHidden        = function(self) return false end,
})

function modifier_item_pms_str_custom_buff:GetEffectName()
    return "particles/econ/items/rubick/rubick_force_ambient/rubick_telekinesis_force_debuff_b.vpcf"
end

--------------------------------------------------------------
--int pms
--------------------------------------------------------------
item_pms_int_custom = class({})

function item_pms_int_custom:OnSpellStart()
    local caster = self:GetCaster()
    local buff_duration = self:GetSpecialValueFor("buff_duration")

    caster:AddNewModifier(caster, self, "modifier_item_pms_int_custom_buff", {duration = buff_duration})
    caster:EmitSound("Item.CrimsonGuard.Cast")
end

function item_pms_int_custom:GetIntrinsicModifierName()
    return "modifier_item_pms_int_custom"
end

modifier_item_pms_int_custom = class({
    IsHidden        = function(self) return true end,
    GetAttributes   = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
    DeclareFunctions  = function(self) return {
        MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
    
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }end,
})

function modifier_item_pms_int_custom:OnCreated()
    self.ability = self:GetAbility()
    if(not self.ability) then
        self:Destroy()
        return
    end
    self:OnRefresh()
end

function modifier_item_pms_int_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.bonus_int = self.ability:GetSpecialValueFor("bonus_int")
    self.block_value = self.ability:GetSpecialValueFor("block_value")
    self.block_chance = self.ability:GetSpecialValueFor("block_chance")
    self.buff_block_chance = self.ability:GetSpecialValueFor("buff_block_chance")
end

function modifier_item_pms_int_custom:GetModifierBonusHealth()
    return self.bonus_health
end

function modifier_item_pms_int_custom:GetModifierBonusStats_Intellect()
    return self.bonus_int
end

function modifier_item_pms_int_custom:GetModifierPhysical_ConstantBlock()
    local block_chance = self.block_chance
    if self:GetCaster():HasModifier("modifier_item_pms_int_custom_buff") then
        block_chance = self.buff_block_chance
    end

    if RollPercentage(block_chance) then
        return self.block_value
    else
        return 
    end
end


modifier_item_pms_int_custom_buff = class({
    IsHidden        = function(self) return false end,
})

function modifier_item_pms_int_custom_buff:GetEffectName()
    return "particles/econ/items/rubick/rubick_force_ambient/rubick_telekinesis_force_debuff_b.vpcf"
end

LinkLuaModifier("modifier_item_pms_custom", "items/item_pms_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_pms_custom)
LinkLuaModifier("modifier_item_pms_custom_buff", "items/item_pms_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_pms_custom_buff)
LinkLuaModifier("modifier_item_pms_agi_custom", "items/item_pms_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_pms_agi_custom)
LinkLuaModifier("modifier_item_pms_agi_custom_buff", "items/item_pms_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_pms_agi_custom_buff)
LinkLuaModifier("modifier_item_pms_str_custom", "items/item_pms_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_pms_str_custom)
LinkLuaModifier("modifier_item_pms_str_custom_buff", "items/item_pms_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_pms_str_custom_buff)
LinkLuaModifier("modifier_item_pms_int_custom", "items/item_pms_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_pms_int_custom)
LinkLuaModifier("modifier_item_pms_int_custom_buff", "items/item_pms_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_pms_int_custom_buff)