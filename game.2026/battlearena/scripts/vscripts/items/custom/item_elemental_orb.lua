require('items/generic_datadriven_item')


item_elemental_orb = class({
    GetIntrinsicModifierName = function()
        return "modifier_item_elemental_orb"
    end
})

modifier_item_elemental_orb = class({
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
		return {
            MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
		}
	end,
    GetModifierMagicalResistanceBonus = function(self)
        return self.bonusSpellResistance
    end,
    GetModifierBonusStats_Strength_Percentage = function(self)
		return self.bonusStrPct
	end,
	GetModifierBonusStats_Agility_Percentage = function(self)
		return self.bonusAgiPct
	end,
	GetModifierBonusStats_Intellect_Percentage = function(self)
		return self.bonusIntPct
	end,
    GetModifierPhysicalArmorTotal_Percentage = function(self)
        return self.bonusArmorPct
    end
})

function modifier_item_elemental_orb:OnCreated()
	self.ability = self:GetAbility()
	self:OnRefresh()
end

function modifier_item_elemental_orb:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability) then
        return
    end
    self.maxElementalRapiers = self.ability:GetSpecialValueFor("max_elementals")
    self.bonusStrPct = self.ability:GetSpecialValueFor("bonus_str_pct")
    self.bonusAgiPct = self.ability:GetSpecialValueFor("bonus_agi_pct")
    self.bonusIntPct = self.ability:GetSpecialValueFor("bonus_int_pct")
	self.bonusArmorPct = self.ability:GetSpecialValueFor("bonus_armor_pct")
	self.bonusSpellResistance = self.ability:GetSpecialValueFor("bonus_magic_res")
end

function modifier_item_elemental_orb:GetMaxRapiersAmount()
    return self.maxElementalRapiers
end


LinkLuaModifier("modifier_item_elemental_orb", "items/custom/item_elemental_orb", LUA_MODIFIER_MOTION_NONE, modifier_item_elemental_orb)
