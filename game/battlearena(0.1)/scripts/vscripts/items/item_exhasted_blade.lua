require('items/generic_datadriven_item')

item_exhasted_blade = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_exhasted_blade"
    end
})

item_exhasted_blade_1 = class(item_exhasted_blade)
item_exhasted_blade_2 = class(item_exhasted_blade)
item_exhasted_blade_3 = class(item_exhasted_blade)

item_terror_blade_1 = class(item_exhasted_blade)
item_terror_blade_2 = class(item_exhasted_blade)
item_terror_blade_3 = class(item_exhasted_blade)

modifier_item_exhasted_blade = class({
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

function modifier_item_exhasted_blade:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_item_exhasted_blade:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
    self.bonus_allstats = self.ability:GetSpecialValueFor("bonus_allstats")
    self.debuff_duration = self.ability:GetSpecialValueFor("debuff_duration")
end

function modifier_item_exhasted_blade:GetModifierProjectileName()
    return "particles/items_fx/desolator_projectile.vpcf"
end

function modifier_item_exhasted_blade:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage
end

function modifier_item_exhasted_blade:GetModifierBonusStats_Strength()
    return self.bonus_allstats
end

function modifier_item_exhasted_blade:GetModifierBonusStats_Agility()
    return self.bonus_allstats
end

function modifier_item_exhasted_blade:GetModifierBonusStats_Intellect()
    return self.bonus_allstats
end

function modifier_item_exhasted_blade:OnAttackLanded(data)
    local target = data.target
    local attacker = data.attacker

    if attacker == self.parent and target:GetTeam() ~= self.parent:GetTeam() then
        target:AddNewModifier(self.parent, self.ability, "modifier_item_exhasted_blade_debuff", {duration = self.debuff_duration})
    end
end

modifier_item_exhasted_blade_debuff = class({
    IsPurgable = function() return false end,
    IsPurgeException = function() return false end,
    DeclareFunctions = function() return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    } end,
    GetModifierPhysicalArmorBonus = function(self)
        return (self.debuff_armor+self.debuff_armor_stack*self:GetStackCount())*(-1)
    end
})

function modifier_item_exhasted_blade_debuff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()

    self:SetStackCount(0)
    self:StartIntervalThink(1)
end

function modifier_item_exhasted_blade_debuff:OnIntervalThink()
    if self:GetStackCount() < self.debuff_max_stack then
        self:IncrementStackCount()
    end
end

function modifier_item_exhasted_blade_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.debuff_armor = self.ability:GetSpecialValueFor("debuff_armor")
    self.debuff_armor_stack = self.ability:GetSpecialValueFor("debuff_armor_stack")
    self.debuff_max_stack = self.ability:GetSpecialValueFor("debuff_max_stack")
end


LinkLuaModifier("modifier_item_exhasted_blade", "items/item_exhasted_blade", LUA_MODIFIER_MOTION_NONE, modifier_item_exhasted_blade)
LinkLuaModifier("modifier_item_exhasted_blade_debuff", "items/item_exhasted_blade", LUA_MODIFIER_MOTION_NONE, modifier_item_exhasted_blade_debuff)
