require('items/generic_datadriven_item')

item_lifesteal_custom = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_lifesteal_custom_handler"
    end
})

modifier_item_lifesteal_custom_handler = class({
	IsHidden = function() 
		return true 
	end,
	IsPurgeable = function() 
		return false 
	end,
	IsPurgeException = function()
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

function modifier_item_lifesteal_custom_handler:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self:OnRefresh()
    if(not IsServer()) then
        return
    end
    self.targetTeam = self.ability:GetAbilityTargetTeam()
	self.targetType = self.ability:GetAbilityTargetType()
	self.targetFlags = self.ability:GetAbilityTargetFlags()
end

function modifier_item_lifesteal_custom_handler:OnRefresh()
	self.ability = self:GetAbility() or self.ability
	if(not self.ability) then
		return
	end
	self.bonusLifesteal = self.ability:GetSpecialValueFor("lifesteal")
end

function modifier_item_lifesteal_custom_handler:OnAttackLanded(kv)
    if(kv.attacker ~= self.parent) then
        return
    end
    if(UnitFilter(kv.target, self.targetTeam, self.targetType, self.targetFlags, self.parent:GetTeamNumber()) ~= UF_SUCCESS) then
        return
    end
    self.parent:PerformLifesteal(kv.target, self.bonusLifesteal)
end

LinkLuaModifier("modifier_item_lifesteal_custom_handler", "items/item_lifesteal", LUA_MODIFIER_MOTION_NONE, modifier_item_lifesteal_custom_handler)
