item_paw_of_midas = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_paw_of_midas"
    end
})

modifier_item_paw_of_midas = class({
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
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_EVENT_ON_ATTACK_LANDED
        }
    end,
    GetModifierAttackSpeedBonus_Constant = function(self)
        return self.bonusAttackSpeed
    end,
    GetModifierBonusStats_Agility = function(self)
        return self.bonusAgility
    end,
    RemoveOnDeath = function()
        return false
    end
})

function modifier_item_paw_of_midas:OnCreated()
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

function modifier_item_paw_of_midas:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonusAttackSpeed = self.ability:GetSpecialValueFor("bonus_attack_speed")
    self.bonusAgility = self.ability:GetSpecialValueFor("bonus_agility")
    self.bonusGoldPerAttack = self.ability:GetSpecialValueFor("gold_per_attack")
end

function modifier_item_paw_of_midas:OnAttackLanded(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    if(UnitFilter(kv.target, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    self.parent:ModifyGoldFiltered(self.bonusGoldPerAttack, true, DOTA_ModifyGold_AbilityGold)
end

item_paw_of_negan = class(item_paw_of_midas)
item_paw_of_klaus = class(item_paw_of_midas)

LinkLuaModifier("modifier_item_paw_of_midas", "items/neutral_items/paw_of_event", LUA_MODIFIER_MOTION_NONE, modifier_item_paw_of_midas)