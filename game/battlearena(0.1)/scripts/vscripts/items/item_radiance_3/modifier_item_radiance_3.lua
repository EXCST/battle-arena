modifier_item_radiance_3 = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_item_radiance_3:IsHidden()
	return true
end

function modifier_item_radiance_3:IsPurgable()
	return false
end

function modifier_item_radiance_3:IsAura()
	return true
end

function modifier_item_radiance_3:GetModifierAura()
	return "modifier_item_radiance_effect_lua"
end

function modifier_item_radiance_3:GetAuraRadius()
	-- cancel if break
	if self:GetParent():PassivesDisabled() then return 0 end
	return self.aura_radius
end

function modifier_item_radiance_3:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_radiance_3:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_item_radiance_3:OnCreated( kv )
	-- references
	self.bonus_damage = self:GetAbility():GetSpecialValueFor( "bonus_damage" )
	self.evasion = self:GetAbility():GetSpecialValueFor( "evasion" )
	self.aura_radius = self:GetAbility():GetSpecialValueFor( "aura_radius" )
end

function modifier_item_radiance_3:OnRefresh( kv )
	-- references
	self.bonus_damage = self:GetAbility():GetSpecialValueFor( "bonus_damage" )
	self.evasion = self:GetAbility():GetSpecialValueFor( "evasion" )
	self.aura_radius = self:GetAbility():GetSpecialValueFor( "aura_radius" )
end

function modifier_item_radiance_3:OnDestroy( kv )

end

function modifier_item_radiance_3:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

-- Modifier Effects
function modifier_item_radiance_3:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_EVASION_CONSTANT,
	}

	return funcs
end

function modifier_item_radiance_3:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_radiance_3:GetModifierEvasion_Constant()
  return self.evasion or self:GetAbility():GetSpecialValueFor("evasion")
end