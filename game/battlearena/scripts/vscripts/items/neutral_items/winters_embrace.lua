item_winters_embrace_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_winters_embrace_custom"
    end
})

modifier_item_winters_embrace_custom = class({
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
            MODIFIER_EVENT_ON_ATTACK_START,
            MODIFIER_EVENT_ON_ATTACK_RECORD,
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
        }
    end,
    GetModifierPhysicalArmorBonus = function(self)
        return self.bonusArmor
    end,
    GetModifierBonusStats_Intellect = function(self)
        return self.bonusIntellect
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_winters_embrace_custom:OnCreated()
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

function modifier_item_winters_embrace_custom:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusIntellect = self.ability:GetSpecialValueFor("bonus_intellect")
    self.bonusArmor = self.ability:GetSpecialValueFor("bonus_armor")
    self.duration = self.ability:GetSpecialValueFor("duration")
end

function modifier_item_winters_embrace_custom:OnAttackStart(kv)
    if(kv.target ~= self.parent) then
        return
    end
    if(UnitFilter(kv.attacker, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    kv.attacker:AddNewModifier(
        self.parent, 
        self.ability, 
        "modifier_item_winters_embrace_custom_debuff", 
        {
            duration = self.duration
        }
    )
end

function modifier_item_winters_embrace_custom:OnAttackRecord(kv)
end

modifier_item_winters_embrace_custom_debuff = class({
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
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
            MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT
        }
    end,
    GetModifierAttackSpeedBonus_Constant = function(self)
        return self.bonusAttackSpeed
    end,
    GetModifierMoveSpeedBonus_Constant = function(self)
        return self.bonusMovementSpeed
    end,
    GetTexture = function(self)
        return self.buffIcon
    end
})

function modifier_item_winters_embrace_custom_debuff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
    if(not IsServer()) then
        self.buffIcon = self.ability:GetAbilityTextureName()
    end
end

function modifier_item_winters_embrace_custom_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonusAttackSpeed = self.ability:GetSpecialValueFor("attack_speed_slow") * -1
    self.bonusMovementSpeed = self.ability:GetSpecialValueFor("movement_speed_slow") * -1
end

LinkLuaModifier("modifier_item_winters_embrace_custom", "items/neutral_items/winters_embrace", LUA_MODIFIER_MOTION_NONE, modifier_item_winters_embrace_custom)
LinkLuaModifier("modifier_item_winters_embrace_custom_debuff", "items/neutral_items/winters_embrace", LUA_MODIFIER_MOTION_NONE, modifier_item_winters_embrace_custom_debuff)
