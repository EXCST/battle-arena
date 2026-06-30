require('items/generic_datadriven_item')

item_ancient_stone = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_ancient_stone"
	end
})

modifier_item_ancient_stone = class({
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
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
        
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
    end
})

function modifier_item_ancient_stone:OnCreated()
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

function modifier_item_ancient_stone:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end  
    self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
    self.bonus_hp_regen = self.ability:GetSpecialValueFor("bonus_hp_regen")
    self.aura_radius = self.ability:GetSpecialValueFor("aura_radius")
end

function modifier_item_ancient_stone:GetModifierBonusHealth()
	return self.bonus_health
end

function modifier_item_ancient_stone:GetModifierConstantHealthRegen()
    return self.bonus_hp_regen
end

LinkLuaModifier("modifier_item_ancient_stone", "items/item_ancient_stone", LUA_MODIFIER_MOTION_NONE, modifier_item_ancient_stone)
