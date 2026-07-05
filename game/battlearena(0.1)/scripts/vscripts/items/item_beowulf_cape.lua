require('items/generic_datadriven_item')


item_beowulf_cape = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_beowulf_cape"
	end,
	GetAbilityTextureNameDuringNight = function()
		return self.BaseClass.GetAbilityTextureName(self)
	end
})

function item_beowulf_cape:GetAbilityTextureName()
	local caster = self:GetCaster()
	if(caster:GetModifierStackCount(self:GetIntrinsicModifierName(), caster) == 0) then
		return self:GetAbilityTextureNameDuringNight()
	end
	return self.BaseClass.GetAbilityTextureName(self)
end

function item_beowulf_cape:GetAbilityTextureNameDuringNight()
	return "evolut_combo/beowulf_cape_night"
end

modifier_item_beowulf_cape = class({
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
	DeclareFunctions = function()
		return
		{
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_ROSHDEF_BONUS_HEALTH,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING
		
            MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
        }
	end,
	GetModifierBonusStats_Strength = function(self)
		return self.bonus_str
	end,
	GetModifierBonusHealth = function(self)
		return self.bonus_health
	end,
	GetModifierConstantHealthRegen = function(self)
		return self.bonus_hp_regen
	end,
})

function modifier_item_beowulf_cape:GetModifierMagicalResistanceBonus()
	return self:GetStackCount() == 1 and self.bonusSpellResistance or self.bonusSpellResistanceNight
end

function modifier_item_beowulf_cape:GetModifierStatusResistanceStacking()
	return self:GetStackCount() == 1 and self.bonusStatusResistance or self.bonusStatusResistanceNight
end

function modifier_item_beowulf_cape:OnCreated()
	self.ability = self:GetAbility()
	self:OnRefresh()
	if(not IsServer()) then
		return
	end
	self:OnIntervalThink()
	self:StartIntervalThink(1)
end

function modifier_item_beowulf_cape:OnRefresh()
	self.ability = self:GetAbility() or self.ability
	if(not self.ability) then
		return
	end

	self.bonus_str = self.ability:GetSpecialValueFor("bonus_str")
	self.bonus_health = self.ability:GetSpecialValueFor("bonus_health")
	self.bonus_hp_regen = self.ability:GetSpecialValueFor("bonus_hp_regen")

	self.bonusSpellResistance = self.ability:GetSpecialValueFor("magic_resist_pct")
	self.bonusSpellResistanceNight = self.ability:GetSpecialValueFor("night_magic_resist_pct")

	self.bonusStatusResistance = self.ability:GetSpecialValueFor("status_resist_pct")
	self.bonusStatusResistanceNight = self.ability:GetSpecialValueFor("night_status_resist_pct")
	if(not IsServer()) then
		return
	end
end

function modifier_item_beowulf_cape:OnIntervalThink()
	if(GameRules:IsDaytime()) then
		self:SetStackCount(1)
	else
		self:SetStackCount(0)
	end
end


LinkLuaModifier("modifier_item_beowulf_cape", "items/item_beowulf_cape", LUA_MODIFIER_MOTION_NONE, modifier_item_beowulf_cape)

