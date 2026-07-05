item_stygian_desolator_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_stygian_desolator_custom"
    end
})

modifier_item_stygian_desolator_custom = class({
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
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
            MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
            MODIFIER_EVENT_ON_ATTACK_LANDED
        }
    end,
    GetModifierAttackSpeedBonus_Constant = function(self)
        return self.bonusAttackSpeed
    end,
    GetModifierPreAttack_BonusDamage = function(self)
        return self.bonusDamage
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_stygian_desolator_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.targetTeam = self.ability:GetAbilityTargetTeam()
	self.targetType = self.ability:GetAbilityTargetType()
	self.targetFlags = self.ability:GetAbilityTargetFlags()
end

function modifier_item_stygian_desolator_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAttackSpeed = self.ability:GetSpecialValueFor("bonus_attack_speed")
    self.bonusDamage = self.ability:GetSpecialValueFor("bonus_damage")
    self.debuffDuration = self.ability:GetSpecialValueFor("corruption_duration")
    self.maxStacks = self.ability:GetSpecialValueFor("max_stacks")
end

function modifier_item_stygian_desolator_custom:OnAttackLanded(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    if(UnitFilter(kv.target, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    local mod = kv.target:AddNewModifier(self.parent, self.ability, "modifier_item_stygian_desolator_custom_debuff", {duration = self.debuffDuration})
    if(mod) then
        mod:SetStackCount(math.min(mod:GetStackCount() + 1, self.maxStacks))
    end
end

modifier_item_stygian_desolator_custom_debuff = class({
    IsHidden = function() 
        return false 
    end,
    IsDebuff = function()
        return true
    end,
    IsPurgable = function()
        return true
    end,
    DeclareFunctions = function() 
        return {
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
        }
    end,
    GetTexture = function(self)
        return self.buffIcon
    end
})

function modifier_item_stygian_desolator_custom_debuff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
    end
end

function modifier_item_stygian_desolator_custom_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.armorPerStack = self.ability:GetSpecialValueFor("corruption_armor_per_stack") * -1
    self.maxStacks = self.ability:GetSpecialValueFor("max_stacks")
end

function modifier_item_stygian_desolator_custom_debuff:GetModifierPhysicalArmorBonus()
    return self.armorPerStack * self:GetStackCount()
end

LinkLuaModifier("modifier_item_stygian_desolator_custom", "items/neutral_items/stygian_desolator", LUA_MODIFIER_MOTION_NONE, modifier_item_stygian_desolator_custom)
LinkLuaModifier("modifier_item_stygian_desolator_custom_debuff", "items/neutral_items/stygian_desolator", LUA_MODIFIER_MOTION_NONE, modifier_item_stygian_desolator_custom_debuff)