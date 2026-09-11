require("lib/augments/boons/modifier_augment_shield_base")
modifier_aug_magical_shield = modifier_aug_magical_shield or class(modifier_augment_shield_base)

function modifier_aug_magical_shield:GetTexture() return "magical_shield" end


function modifier_aug_magical_shield:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT, -- GetModifierIncomingSpellDamageConstant
	}
end


function modifier_aug_magical_shield:GetModifierIncomingSpellDamageConstant(event)
	return self:HandleShieldDamage(event)
end
