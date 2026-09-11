-- ============================================================
-- BATTLE ARENA — Travaler: жертва «поднята» (Хватка Пустоты)
-- ROOTED + видимый маркер над головой.
-- ============================================================

modifier_travaler_grabbed = modifier_travaler_grabbed or class({})

local mod = modifier_travaler_grabbed


function mod:IsHidden() 		return false end
function mod:IsPurgable() 		return false end
function mod:DestroyOnExpire() 	return true end
function mod:IsDebuff() 		return true end


function mod:CheckState() return
{
	[MODIFIER_STATE_ROOTED] = true,
}
end


function mod:GetEffectName()
	return "particles/econ/items/ogre_magi/ogre_magi_arcana/ogre_magi_arcana_stunned_orbit.vpcf"
end


function mod:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
