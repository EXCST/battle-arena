require("lib/augments/boons/modifier_augment_shield_base")
modifier_aug_physical_shield = modifier_aug_physical_shield or class(modifier_augment_shield_base)

function modifier_aug_physical_shield:GetTexture() return "physical_shield" end


function modifier_aug_physical_shield:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT, -- GetModifierIncomingPhysicalDamageConstant
	}
end


function modifier_aug_physical_shield:GetModifierIncomingPhysicalDamageConstant(event)
	return self:HandleShieldDamage(event)
end
