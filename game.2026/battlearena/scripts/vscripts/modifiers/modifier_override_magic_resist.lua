-- ============================================================================
-- Battle Arena: отключение движкового магического сопротивления от интеллекта.
-- Движок Dota 2 даёт +0.1% MR за каждое очко интеллекта (база = 25% + 0.1% x int).
-- Это проперти масштабирует пер-инт-бонус: -100% = инт полностью перестаёт давать MR,
-- базовые 25% и флэт-бонусы (аугменты/предметы) не затрагиваются.
-- Механика: аналог AAF modifier_override_magic_resist.
-- ============================================================================

modifier_override_magic_resist = class({})

function modifier_override_magic_resist:IsHidden() return true end
function modifier_override_magic_resist:IsDebuff() return false end
function modifier_override_magic_resist:IsPurgable() return false end
function modifier_override_magic_resist:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_override_magic_resist:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASE_MRES_PER_INT_BONUS_PERCENTAGE,
	}
end

function modifier_override_magic_resist:GetModifierBaseMagicResistPerIntBonusPercentage(event)
	return -100
end
