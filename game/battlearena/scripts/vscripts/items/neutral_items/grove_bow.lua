item_grove_bow_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_grove_bow_custom"
    end
})

function item_grove_bow_custom:Precache(context)
    PrecacheResource("particle", "particles/items2_fx/veil_of_discord_debuff.vpcf", context)
end

modifier_item_grove_bow_custom = class({
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
            MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
            MODIFIER_EVENT_ON_ATTACK_LANDED
        }
    end,
    GetModifierAttackSpeedBonus_Constant = function(self)
        return self.bonusAttackSpeed
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_grove_bow_custom:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.targetTeam = self.ability:GetAbilityTargetTeam()
	self.targetType = self.ability:GetAbilityTargetType()
	self.targetFlags = self.ability:GetAbilityTargetFlags()
    self:StartIntervalThink(0.2)
end

function modifier_item_grove_bow_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAttackSpeed = self.ability:GetSpecialValueFor("attack_speed_bonus")
    self.bonusAttackRangeRanged = self.ability:GetSpecialValueFor("attack_range_bonus")
    self.debuffDuration = self.ability:GetSpecialValueFor("debuff_duration")
end

function modifier_item_grove_bow_custom:OnIntervalThink()
    local attackCapability = self.parent:GetAttackCapability()
    if(self.parent:GetAttackCapability() == DOTA_UNIT_CAP_RANGED_ATTACK) then
        self:SetStackCount(self.bonusAttackRangeRanged)
    else
        self:SetStackCount(0)
    end
end

function modifier_item_grove_bow_custom:GetModifierAttackRangeBonus()
    return self:GetStackCount()
end

function modifier_item_grove_bow_custom:OnAttackLanded(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    if(UnitFilter(kv.target, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    kv.target:AddNewModifier(self.parent, self.ability, "modifier_item_grove_bow_custom_debuff", {duration = self.debuffDuration})
end

modifier_item_grove_bow_custom_debuff = class({
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
            MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
        }
    end,
    GetModifierMagicalResistanceBonus = function(self)
        return self.bonusSpellResistance
    end,
    GetEffectName = function()
        return "particles/items2_fx/veil_of_discord_debuff.vpcf"
    end,
    GetTexture = function(self)
        return self.buffIcon
    end
})

function modifier_item_grove_bow_custom_debuff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
    end
end

function modifier_item_grove_bow_custom_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusSpellResistance = self.ability:GetSpecialValueFor("magic_resistance_reduction") * -1
end

LinkLuaModifier("modifier_item_grove_bow_custom", "items/neutral_items/grove_bow", LUA_MODIFIER_MOTION_NONE, modifier_item_grove_bow_custom)
LinkLuaModifier("modifier_item_grove_bow_custom_debuff", "items/neutral_items/grove_bow", LUA_MODIFIER_MOTION_NONE, modifier_item_grove_bow_custom_debuff)