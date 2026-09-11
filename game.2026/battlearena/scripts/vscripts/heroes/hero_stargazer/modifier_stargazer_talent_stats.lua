-- ============================================================
-- STARGAZER — единый модификатор стат-талантов (+40 урона / +300 HP / +50 AS).
-- Паттерн modifier_arthas_talent_stats (проверено в игре 2026-08-10):
-- значения ЗАХАРДКОЖЕНЫ (AbilityKV:Get(talent, "value") = 0), проверка
-- только HasTalent. Держать синхронно с stargazer_talents.txt.
-- Флаг-таланты (инт-урон/дальность варпа/отражение/статы и скорость
-- цикла) читаются через HasTalent в gamma_ray/warp/inverse_field/
-- cosmic_countdown. Вешается из modifier_stargazer_cosmic_countdown:OnCreated
-- (интринзик ульты, есть с 1 уровня) с HasModifier-гардом.
-- ============================================================

modifier_stargazer_talent_stats = modifier_stargazer_talent_stats or class({})

function modifier_stargazer_talent_stats:IsHidden() return true end
function modifier_stargazer_talent_stats:IsPurgable() return false end
function modifier_stargazer_talent_stats:RemoveOnDeath() return false end

function modifier_stargazer_talent_stats:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_stargazer_talent_stats:HasTalent(talent_name)
	local hero = self:GetParent()
	if not hero or hero:IsNull() then return false end
	return hero:HasTalent(talent_name)
end

function modifier_stargazer_talent_stats:GetModifierPreAttack_BonusDamage()
	if self:HasTalent("stargazer_special_bonus_attack_damage") then return 40 end
	return 0
end

function modifier_stargazer_talent_stats:GetModifierHealthBonus()
	if self:HasTalent("stargazer_special_bonus_health") then return 300 end
	return 0
end

function modifier_stargazer_talent_stats:GetModifierAttackSpeedBonus_Constant()
	if self:HasTalent("stargazer_special_bonus_attack_speed") then return 50 end
	return 0
end
