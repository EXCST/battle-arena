require('items/generic_datadriven_item')

item_desolator_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_desolator_custom"
    end
})

item_desolator_custom_1 = class(item_desolator_custom)
item_desolator_custom_2 = class(item_desolator_custom)
item_desolator_custom_3 = class(item_desolator_custom)

modifier_item_desolator_custom = class({
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
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
            MODIFIER_PROPERTY_PROJECTILE_NAME,
            MODIFIER_EVENT_ON_ATTACK_LANDED,
        }
    end
})

function modifier_item_desolator_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_desolator_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
    self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
    self.debuff_duration = self.ability:GetSpecialValueFor("debuff_duration")
end

function modifier_item_desolator_custom:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage
end

function modifier_item_desolator_custom:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_desolator_custom:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_desolator_custom:GetModifierBonusStats_Intellect()
    return self.bonus_allstats
end

function modifier_item_desolator_custom:GetModifierProjectileName()
    return "particles/items_fx/desolator_projectile.vpcf"
end

function modifier_item_desolator_custom:OnAttackLanded(data)
    local target = data.target
    local attacker = data.attacker

    if attacker == self.parent and target:GetTeam() ~= self.parent:GetTeam() then
        target:AddNewModifier(self.parent, self.ability, "modifier_item_desolator_custom_debuff", {duration = self.debuff_duration})
    end
end

modifier_item_desolator_custom_debuff = class({
    IsHidden = function()
        return false
    end,
    IsPurgable = function()
        return true
    end,
    IsPurgeException = function()
        return false
    end,
    DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        }
    end,
    GetModifierPhysicalArmorBonus = function(self)
        return self.debuff_armor*(-1)
    end
})

function modifier_item_desolator_custom_debuff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_desolator_custom_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.debuff_armor = self.ability:GetSpecialValueFor("debuff_armor")
end


LinkLuaModifier("modifier_item_desolator_custom", "items/item_desolator_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_desolator_custom)
LinkLuaModifier("modifier_item_desolator_custom_debuff", "items/item_desolator_custom", LUA_MODIFIER_MOTION_NONE, modifier_item_desolator_custom_debuff)
