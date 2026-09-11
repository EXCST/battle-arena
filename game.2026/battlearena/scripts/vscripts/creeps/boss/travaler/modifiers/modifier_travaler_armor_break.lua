-- ============================================================
-- BATTLE ARENA — Travaler: Сломанная броня
-- −100% физической брони на время (после удара Схлопывания).
-- ============================================================

modifier_travaler_armor_break = modifier_travaler_armor_break or class({})

local mod = modifier_travaler_armor_break


function mod:IsHidden() 		return true end
function mod:IsPurgable() 		return false end
function mod:DestroyOnExpire() 	return true end
function mod:IsDebuff() 		return true end


function mod:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS_PERCENTAGE,
	}
end


function mod:GetModifierPhysicalArmorBonusPercentage()
	return -100
end
