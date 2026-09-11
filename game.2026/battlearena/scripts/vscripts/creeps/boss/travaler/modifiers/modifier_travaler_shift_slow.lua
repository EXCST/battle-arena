-- ============================================================
-- BATTLE ARENA — Travaler: замедление после телепорта (Сдвиг Миров)
-- ============================================================

modifier_travaler_shift_slow = modifier_travaler_shift_slow or class({})

local mod = modifier_travaler_shift_slow


function mod:IsHidden() 		return true end
function mod:IsPurgable() 		return false end
function mod:DestroyOnExpire() 	return true end
function mod:IsDebuff() 		return true end


function mod:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVEMENT_SPEED_REDUCTION_PERCENTAGE,
	}
end


function mod:GetModifierMovementSpeedReductionPercentage()
	return 30
end
