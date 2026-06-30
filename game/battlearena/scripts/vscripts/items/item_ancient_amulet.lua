require('items/generic_datadriven_item')

item_ancient_amulet = class({
	GetIntrinsicModifierName = function()
		return "modifier_item_ancient_amulet"
	end
})

modifier_item_ancient_amulet = class({
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
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
        }
    end
})

function modifier_item_ancient_amulet:OnCreated()
    self.ability = self:GetAbility()
    self:OnRefresh()
end

function modifier_item_ancient_amulet:OnRefresh()
    self.ability = self:GetAbility() or self.ability
    if(not self.ability or self.ability:IsNull() == true) then
        return
    end
    self.bonus_mp_regen = self.ability:GetSpecialValueFor("bonus_mp_regen")
    self.bonus_str = self.ability:GetSpecialValueFor("bonus_str")
end

function modifier_item_ancient_amulet:GetModifierConstantManaRegen()
    return self.bonus_mp_regen
end

function modifier_item_ancient_amulet:GetModifierBonusStats_Strength()
    return self.bonus_str
end

LinkLuaModifier("modifier_item_ancient_amulet", "items/item_ancient_amulet", LUA_MODIFIER_MOTION_NONE, modifier_item_ancient_amulet)