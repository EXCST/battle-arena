require('items/generic_datadriven_item')

item_magic_amplifier = item_magic_amplifier or class({})

LinkLuaModifier( "modifier_item_magic_amplifier", "items/magic_amplifier/item_magic_amplifier", LUA_MODIFIER_MOTION_NONE )

function item_magic_amplifier:GetIntrinsicModifierName()
	return "modifier_item_magic_amplifier"
end

modifier_item_magic_amplifier = class({})

--------------------------------------------------------------------------------

function modifier_item_magic_amplifier:IsHidden()
	return true
end

--------------------------------------------------------------------------------

function modifier_item_magic_amplifier:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

function modifier_item_magic_amplifier:OnCreated( kv )
		self.caster = self:GetCaster()
		self.bonus_dmg = self:GetAbility():GetSpecialValueFor( "bonus_dmg" )
		self.bonus_int = self:GetAbility():GetSpecialValueFor( "bonus_int" )
		self.bonus_manaregen = self:GetAbility():GetSpecialValueFor( "mana_regen" )

end

--------------------------------------------------------------------------------

function modifier_item_magic_amplifier:DeclareFunctions()
	local funcs =
	{
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
	return funcs
end

--------------------------------------------------------------------------------

function modifier_item_magic_amplifier:GetModifierSpellAmplify_Percentage( params )
local intellect = self.caster:GetPrimaryStatValue()
local truedmg = intellect * self.bonus_dmg
	return truedmg
end

function modifier_item_magic_amplifier:GetModifierBonusStats_Intellect( params )
	return self.bonus_int
end

function modifier_item_magic_amplifier:GetModifierConstantManaRegen( params )
	return self.bonus_manaregen
end