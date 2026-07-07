lone_druid_deep_wound = class({
	GetIntrinsicModifierName = function()
		return "modifier_lone_druid_deep_wound_handler"
	end
})

modifier_lone_druid_deep_wound_handler = class({
    IsHidden = function()
        return true
    end,
    IsPurgable = function() 
        return false 
    end,
    IsPurgeException = function() 
        return false 
    end,
    IsDebuff = function()
        return false
    end,
    RemoveOnDeath = function()
        return false
    end,
	DeclareFunctions = function() 
        return {
			MODIFIER_EVENT_ON_ATTACK_LANDED
        }
    end
})

function modifier_lone_druid_deep_wound_handler:OnCreated()
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

function modifier_lone_druid_deep_wound_handler:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end 
    self.procChance = self.ability:GetSpecialValueFor("proc_chance")
	self.duration = self.ability:GetSpecialValueFor("duration")
end

function modifier_lone_druid_deep_wound_handler:OnAttackLanded(kv)
    if(self.parent ~= kv.attacker) then
        return
    end
    if(self.parent:PassivesDisabled()) then
        return
    end
    if(UnitFilter(kv.target, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
	if(RollPseudoRandom(self.procChance, self) == false) then
		return
	end
	kv.target:AddNewModifier(self.parent, self.ability, "modifier_lone_druid_deep_wound_debuff", {duration = self.duration})
end

modifier_lone_druid_deep_wound_debuff = class({
    IsHidden = function()
        return false
    end,
    IsPurgable = function() 
        return false 
    end,
    IsPurgeException = function() 
        return false 
    end,
    IsDebuff = function()
        return true
    end,
    RemoveOnDeath = function()
        return false
    end,
	DeclareFunctions = function() 
        return {
			MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
			MODIFIER_PROPERTY_TOOLTIP
        }
    end,
	GetModifierIncomingDamage_Percentage = function(self)
		return self.bonusIncomingDamagePct
	end
})

function modifier_lone_druid_deep_wound_debuff:OnCreated()
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
    self:OnRefresh()
end

function modifier_lone_druid_deep_wound_debuff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end 
    self.bonusIncomingDamagePct = self.ability:GetSpecialValueFor("bonus_damage_taken")
end

function modifier_lone_druid_deep_wound_debuff:OnTooltip()
    return self:GetModifierIncomingDamage_Percentage()
end

LinkLuaModifier("modifier_lone_druid_deep_wound_handler", "abilities/heroes/hero_lone_druid/deep_wound", LUA_MODIFIER_MOTION_NONE, modifier_lone_druid_deep_wound_handler)
LinkLuaModifier("modifier_lone_druid_deep_wound_debuff", "abilities/heroes/hero_lone_druid/deep_wound", LUA_MODIFIER_MOTION_NONE, modifier_lone_druid_deep_wound_debuff)