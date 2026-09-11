-- ============================================================
-- BATTLE ARENA — Travaler: окно неуязвимости при смене фазы
-- ============================================================

modifier_travaler_phase_invuln = modifier_travaler_phase_invuln or class({})

local mod = modifier_travaler_phase_invuln


function mod:IsHidden() 		return false end
function mod:IsPurgable() 		return false end
function mod:DestroyOnExpire() 	return true end
function mod:IsPurgeException() return true end


function mod:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INVULNERABLE,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}
end


function mod:GetModifierInvulnerable() 		return true end
function mod:GetAbsoluteNoDamagePhysical() 	return true end
function mod:GetAbsoluteNoDamageMagical() 	return true end
function mod:GetAbsoluteNoDamagePure() 		return true end


function mod:GetEffectName()
	return "particles/items2_fx/radiance_owner.vpcf"
end


function mod:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
