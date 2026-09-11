-- ============================================================
-- BATTLE ARENA — Soul Guardian helpers
-- Скейлинг урона по модели Angel Arena Frontier: фактор времени
--   f = max(floor(DotaTime/60), 1) — растёт на 1 каждую минуту,
--   виртуальный урон атаки босса AD = 2500 + 250*f,
--   способности — проценты от AD (bash 30%, волна 450% и т.д.).
-- ============================================================

SoulGuardianHelpers = SoulGuardianHelpers or {}

require('lib/ability_kv')

local AD_BASE = 2500
local AD_GAIN = 250
local FACTOR_INTERVAL = 60


--- Фактор времени: ступенька каждые 60 секунд (мин 1).
function SoulGuardianHelpers:GetBossFactor()
	return math.max(math.floor(GameRules:GetDOTATime(false, false) / FACTOR_INTERVAL), 1)
end


--- Виртуальный урон атаки босса (растёт с временем игры).
function SoulGuardianHelpers:GetAttackDamage()
	return AD_BASE + AD_GAIN * self:GetBossFactor()
end


--- Урон по AAF-модели: (flat_base + flat_gain*f) + pct% от макс. HP цели.
--- PURE, NO_SPELL_AMPLIFICATION (паттерн TravalerHelpers:DealDamageCustom).
function SoulGuardianHelpers:DealDamageCustom(ability, caster, target, flat_base, flat_gain, pct_max_hp)
	if not IsValidEntity(target) or not target:IsAlive() then return 0 end

	local damage = (flat_base + flat_gain * self:GetBossFactor()) + target:GetMaxHealth() * pct_max_hp / 100

	ApplyDamage({
		victim = target,
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_PURE,
		damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
		ability = ability,
	})

	return damage
end


--- Урон по AAF-модели: % от виртуального урона атаки босса.
function SoulGuardianHelpers:DealDamagePctOfAD(ability, caster, target, pct_of_ad)
	if not IsValidEntity(target) or not target:IsAlive() then return 0 end

	local damage = self:GetAttackDamage() * pct_of_ad / 100

	ApplyDamage({
		victim = target,
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_PURE,
		damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
		ability = ability,
	})

	return damage
end


--- Враги команды кастера в радиусе.
function SoulGuardianHelpers:FindEnemies(team, position, radius)
	return FindUnitsInRadius(
		team,
		position,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		FIND_CLOSEST,
		false
	)
end


--- Обёртка таймер-колбэка: ошибка не убивает таймер молча.
function SoulGuardianHelpers:SafeTimer(fn)
	return function(...)
		local results = { pcall(fn, ...) }

		if not results[1] then
			print("[SoulGuardian] timer error: " .. tostring(results[2]))
			return nil
		end

		table.remove(results, 1)
		return unpack(results)
	end
end
