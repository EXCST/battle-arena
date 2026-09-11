-- ============================================================================
-- Battle Arena: Augments — flat health bonus for hero-class summons (bear)
-- ============================================================================

modifier_augment_summon_health = modifier_augment_summon_health or class({})


function modifier_augment_summon_health:IsHidden() return true end
function modifier_augment_summon_health:IsPurgable() return false end
function modifier_augment_summon_health:RemoveOnDeath() return false end
function modifier_augment_summon_health:DestroyOnExpire() return false end


function modifier_augment_summon_health:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE
end


function modifier_augment_summon_health:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS, -- GetModifierExtraHealthBonus
	}
end


function modifier_augment_summon_health:GetModifierExtraHealthBonus()
	return self:GetStackCount()
end
