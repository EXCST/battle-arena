-- ============================================================
-- BATTLE ARENA — Travaler: стан (стан + фроз, immortal-эффект)
-- ============================================================

modifier_travaler_stun = modifier_travaler_stun or class({})

local mod = modifier_travaler_stun


function mod:IsHidden() 		return false end
function mod:IsPurgable() 		return true end
function mod:DestroyOnExpire() 	return true end
function mod:IsPurgeException() return true end


function mod:CheckState() return
{
	[MODIFIER_STATE_STUNNED] = true,
	[MODIFIER_STATE_FROZEN] = true,
}
end


function mod:DeclareFunctions() return
{
	MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
}
end


function mod:GetEffectName()
	return "particles/econ/items/underlord/underlord_ti8_immortal_weapon/underlord_ti8_immortal_pitofmalice_stun.vpcf"
end


function mod:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end


function mod:GetStatusEffectName()
	return "particles/status_fx/status_effect_faceless_chronosphere.vpcf"
end


function mod:GetStatusEffectPriority()
	return 1
end


function mod:GetOverrideAnimation(params)
	return ACT_DOTA_DISABLED
end
