require("lib/augments/boons/modifier_augment_shield_base")
modifier_aug_universal_shield = modifier_aug_universal_shield or class(modifier_augment_shield_base)

function modifier_aug_universal_shield:GetTexture() return "universal_shield" end


function modifier_aug_universal_shield:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT, -- GetModifierIncomingDamageConstant
	}
end


function modifier_aug_universal_shield:GetModifierIncomingDamageConstant(event)
	return self:HandleShieldDamage(event)
end
