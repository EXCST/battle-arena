require('items/generic_datadriven_item')


item_hood = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_hood_aura"
	end,
	GetCastRange = function(self)
		return self:GetSpecialValueFor("aura_radius")
	end
})

modifier_item_hood_aura = class({
	IsHidden = function() 
		return true 
	end,
	IsPurgable = function()
		return false
	end,
	IsPurgeException = function()
		return false
	end,
	RemoveOnDeath = function()
		return false
	end,
	IsAura = function()
		return true
	end,
	IsAuraActiveOnDeath = function()
        return false
    end,
    GetAuraRadius = function(self)
        return self.radius
    end,
    GetAuraSearchFlags = function(self)
        return self.targetFlags
    end,
    GetAuraSearchTeam = function(self)
        return self.targetTeam
    end,
    GetAuraSearchType = function(self)
        return self.targetType
    end,
    GetModifierAura = function()
        return "modifier_item_hood_aura_buff"
    end,
    GetAuraDuration = function()
        return 0
    end,
	DeclareFunctions = function() 
		return 
		{
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
		} 
	end,
	GetModifierMagicalResistanceBonus = function(self)
		return self.bonusSpellResistance
	end,
	GetModifierBonusStats_Strength = function(self)
		return self.bonusStr
	end,
	GetModifierBonusStats_Agility = function(self)
		return self.bonusAgility
	end,
	GetModifierBonusStats_Intellect = function(self)
		return self.bonusInt
	end,
})

function modifier_item_hood_aura:OnCreated()
	self.ability = self:GetAbility()
	self.radius = 0
	self:OnRefresh()
end

function modifier_item_hood_aura:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability) then
        return
    end
	self.bonusSpellResistance = self.ability:GetSpecialValueFor("bonus_magic_res")
	self.bonusStr = self.ability:GetSpecialValueFor("bonus_allstat")
	self.bonusAgility = self.bonusStr
	self.bonusInt = self.bonusStr
	self.radius = self.ability:GetSpecialValueFor("aura_radius")
	if(not IsServer()) then
		return
	end
	self.targetTeam = self.ability:GetAbilityTargetTeam()
	self.targetType = self.ability:GetAbilityTargetType()
	self.targetFlags = self.ability:GetAbilityTargetFlags()
end

function modifier_item_hood_aura:GetAuraEntityReject(npc)
	return self.radius < 1
end

modifier_item_hood_aura_buff = class({
	IsHidden = function() 
		return false 
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
		return 
		{
            MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		} 
	end,
	GetModifierMagicalResistanceBonus = function(self)
		return self.bonusSpellResistance
	end
})

function modifier_item_hood_aura_buff:OnCreated()
	self.ability = self:GetAbility()
	self:OnRefresh()
end

function modifier_item_hood_aura_buff:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability) then
        return
    end
	self.bonusSpellResistance = self.ability:GetSpecialValueFor("aura_magic_res_pct")
end

item_cloak_custom = class(item_hood)
item_hood_1 = class(item_hood)
item_hood_2 = class(item_hood)
item_mini_hood_1 = class(item_hood)
item_mini_hood_2 = class(item_hood)


LinkLuaModifier("modifier_item_hood_aura", "items/custom/item_hood", LUA_MODIFIER_MOTION_NONE, modifier_item_hood_aura)
LinkLuaModifier("modifier_item_hood_aura_buff", "items/custom/item_hood", LUA_MODIFIER_MOTION_NONE, modifier_item_hood_aura_buff)
