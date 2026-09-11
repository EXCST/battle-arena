require('items/generic_datadriven_item')


item_werewolf_cape = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_werewolf_cape"
	end,
	GetAbilityTextureNameDuringNight = function()
		return self.BaseClass.GetAbilityTextureName(self)
	end
})

function item_werewolf_cape:GetAbilityTextureName()
	local caster = self:GetCaster()
	if(caster:GetModifierStackCount(self:GetIntrinsicModifierName(), caster) == 1) then
		return self:GetAbilityTextureNameDuringNight()
	end
	return self.BaseClass.GetAbilityTextureName(self)
end

function item_werewolf_cape:GetAbilityTextureNameDuringNight()
    return "evolut_combo/werewolf_cape_night"
end

modifier_item_werewolf_cape = class({
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

function modifier_item_werewolf_cape:GetModifierMagicalResistanceBonus()
    if self:GetStackCount() == 1 then
        return self.bonusSpellResistanceNight
    else
        return self.bonusSpellResistance
    end
end

function modifier_item_werewolf_cape:GetModifierStatusResistanceStacking()
    if self:GetStackCount() == 1 then
        return self.bonusStatusResistanceNight
    else
        return self.bonusStatusResistance
    end
end

function modifier_item_werewolf_cape:OnCreated()
	self.ability = self:GetAbility()
	self:OnRefresh()
	if(not IsServer()) then
		return
	end
	self:OnIntervalThink()
	self:StartIntervalThink(1)
end

function modifier_item_werewolf_cape:OnRefresh()
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

function modifier_item_werewolf_cape:OnIntervalThink()
	if(GameRules:IsDaytime()) then
		self:SetStackCount(0)
	else
		self:SetStackCount(1)
	end
end


LinkLuaModifier("modifier_item_werewolf_cape", "items/custom/item_werewolf_cape", LUA_MODIFIER_MOTION_NONE, modifier_item_werewolf_cape)

