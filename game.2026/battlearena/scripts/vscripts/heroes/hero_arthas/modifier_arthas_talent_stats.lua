-- ============================================================
-- ARTHAS — единый модификатор стат-талантов (+40 урона / +300 HP / −20% КД / +50 AS).
-- Паттерн modifier_stegius_talent_stats (проверено в игре 2026-08-10):
-- значения ЗАХАРДКОЖЕНЫ (чтение из KV special_bonus_base ненадёжно —
-- AbilityKV:Get(talent, "value") = 0), проверка только HasTalent.
-- Держать синхронно с arthas_talents.txt. Флаг-таланты ульты
-- (шанс/урон/броня/стан) читаются в modifier_arthas_vsolyanova_active.
-- Вешается из CheckEnemies (vsolyanova.lua) с HasModifier-гардом.
-- ============================================================

modifier_arthas_talent_stats = modifier_arthas_talent_stats or class({})

function modifier_arthas_talent_stats:IsHidden() return true end
function modifier_arthas_talent_stats:IsPurgable() return false end
function modifier_arthas_talent_stats:RemoveOnDeath() return false end

function modifier_arthas_talent_stats:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_arthas_talent_stats:HasTalent(talent_name)
	local hero = self:GetParent()
	if not hero or hero:IsNull() then return false end
	return hero:HasTalent(talent_name)
end

function modifier_arthas_talent_stats:GetModifierPreAttack_BonusDamage()
	if self:HasTalent("arthas_special_bonus_attack_damage") then return 40 end
	return 0
end

function modifier_arthas_talent_stats:GetModifierHealthBonus()
	if self:HasTalent("arthas_special_bonus_health") then return 300 end
	return 0
end

function modifier_arthas_talent_stats:GetModifierPercentageCooldown()
	-- ⚠️ В этой сборке знак COOLDOWN_PERCENTAGE инвертирован: ПОЛОЖИТЕЛЬНОЕ
	-- значение = снижение перезарядки (конвенция проекта, проверено 2026-08-10).
	if self:HasTalent("arthas_special_bonus_cooldown") then return 20 end
	return 0
end

function modifier_arthas_talent_stats:GetModifierAttackSpeedBonus_Constant()
	if self:HasTalent("arthas_special_bonus_attack_speed") then return 50 end
	return 0
end
