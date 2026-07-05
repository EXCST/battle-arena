item_broom_handle_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_broom_handle_custom"
    end
})

modifier_item_broom_handle_custom = class({
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
            MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
            MODIFIER_PROPERTY_ATTACK_RANGE_BONUS
        }
    end,
    GetModifierPreAttack_BonusDamage = function(self)
        return self.bonusAttackDamage
    end,
    GetModifierPhysicalArmorBonus = function(self)
        return self.bonusArmor
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_broom_handle_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self:StartIntervalThink(0.2)
end

function modifier_item_broom_handle_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAttackRangeMelee = self.ability:GetSpecialValueFor("melee_attack_range")
    self.bonusAttackDamage = self.ability:GetSpecialValueFor("bonus_damage")
    self.bonusArmor = self.ability:GetSpecialValueFor("bonus_armor")
end

function modifier_item_broom_handle_custom:OnIntervalThink()
    local attackCapability = self.parent:GetAttackCapability()
    if(self.parent:GetAttackCapability() == DOTA_UNIT_CAP_MELEE_ATTACK) then
        self:SetStackCount(self.bonusAttackRangeMelee)
    else
        self:SetStackCount(0)
    end
end

function modifier_item_broom_handle_custom:GetModifierAttackRangeBonus()
    return self:GetStackCount()
end

LinkLuaModifier("modifier_item_broom_handle_custom", "items/neutral_items/broom_handle", LUA_MODIFIER_MOTION_NONE, modifier_item_broom_handle_custom)