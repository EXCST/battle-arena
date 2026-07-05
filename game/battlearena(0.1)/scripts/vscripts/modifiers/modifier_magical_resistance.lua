modifier_magical_resistance = class({})

function modifier_magical_resistance:IsHidden() return false end
function modifier_magical_resistance:IsDebuff() return false end
function modifier_magical_resistance:IsPurgable() return false end
function modifier_magical_resistance:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_magical_resistance:DeclareFunctions()
	return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

function modifier_magical_resistance:GetModifierMagicalResistanceBonus()
	return 25
end
