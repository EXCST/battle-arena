-- ============================================================
-- STARGAZER — Inverse Field (отражение урона от автоатак)
-- ПЕРЕПИСАНО 2026-08-12 (план Б): модификаторная реализация.
--
-- ПОЧЕМУ: старая реализация висела на GameMode:SetDamageFilter —
-- Lua-колбэк DamageFilter в этой сборке НЕ вызывается движком
-- (0 принтов-диагностики за 5+ минут боя при зарегистрированном
-- фильтре и боевом герое, см. сессию 2026-08-12). Доказанно живой
-- механизм — MODIFIER_EVENT_ON_ATTACK_LANDED (pet_wolf_vampire
-- 2026-08-11, item_spiked_shield — тот же паттерн отражения).
--
-- Механика: интринзик-модификатор (создаётся движком ПРИ ПРОКАЧКЕ
-- скилла до 1+ уровня — паттерн stegius desolating_touch; уровень 0
-- = пассивка молчит) ловит автоатаки по герою и ApplyDamage по
-- атакующему. Рекурсии нет: отражённый урон не является атакой и
-- несёт флаг DOTA_DAMAGE_FLAG_REFLECTION.
--
-- Значения читаются через AbilityKV:Get НА ЛЕТУ в методе (грабли:
-- интринзик-модификатор в OnCreated не имеет ability-ссылки).
-- ============================================================

require('lib/ability_kv')

LinkLuaModifier("modifier_stargazer_inverse_field", "heroes/hero_stargazer/inverse_field", LUA_MODIFIER_MOTION_NONE)

stargazer_inverse_field = class({})

function stargazer_inverse_field:GetIntrinsicModifierName()
	return "modifier_stargazer_inverse_field"
end

------------------------------------------------------------------------------

modifier_stargazer_inverse_field = class({})

function modifier_stargazer_inverse_field:IsHidden()
	return true
end

function modifier_stargazer_inverse_field:IsPurgable()
	return false
end

function modifier_stargazer_inverse_field:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_stargazer_inverse_field:OnCreated()
	if not IsServer() then return end
	local parent = self:GetParent()
	local ability = self:GetAbility()
	print("[INVERSE] attached on " .. (parent and parent:GetUnitName() or "?")
		.. ", lvl=" .. tostring(ability and ability:GetLevel() or "nil"))
end

-- ⚠️ xpcall-обёртка: движковый хендлер скрывает текст ошибки
-- («error in error handling», debug=nil в этой сборке) — паттерн
-- pet_wolf_vampire/gamma_ray.
function modifier_stargazer_inverse_field:OnAttackLanded(params)
	local ok, err = xpcall(function() self:ReflectDamage(params) end, function(e) return tostring(e) end)
	if not ok then
		print("[INVERSE] OnAttackLanded error: " .. tostring(err))
	end
end

function modifier_stargazer_inverse_field:ReflectDamage(params)
	if not IsServer() then return end

	local parent = self:GetParent()
	if not parent or parent:IsNull() or not parent:IsAlive() then return end

	local ability = self:GetAbility()
	if not ability or ability:GetLevel() < 1 then return end

	-- только атаки ПО герою
	if params.target ~= parent then return end

	local attacker = params.attacker
	if not attacker or attacker:IsNull() then return end
	if attacker == parent then return end
	if attacker:GetTeamNumber() == parent:GetTeamNumber() then return end
	if attacker:IsBoss() or attacker:IsMagicImmune() or attacker:IsDebuffImmune() then return end
	if parent:PassivesDisabled() or parent:IsIllusion() then return end

	local base = AbilityKV:Get(ability, "base_reflection")
	if not base or base <= 0 then base = 10 end
	local str_pct = AbilityKV:Get(ability, "str_to_reflection_pct")
	if not str_pct or str_pct <= 0 then str_pct = 0.2 end
	local threshold = AbilityKV:Get(ability, "damage_threshold")
	if not threshold or threshold <= 0 then threshold = 2000 end

	local base_multiplier = base * 0.01
	-- ⚠️ GetStrength в этой сборке НЕ принимает аргумент («called with 2
	-- arguments - expected 1», проверено в игре 2026-08-12) — только
	-- GetStrength() без аргумента (базовая сила без бонусов аугментов).
	local str_multiplier = parent:GetStrength() * str_pct * 0.01 * 0.01

	if parent:HasTalent("stargazer_special_bonus_reflection") then
		base_multiplier = base_multiplier + 0.05
	end

	local raw_damage = params.original_damage or params.damage or 0
	if raw_damage <= 0 then return end

	local return_damage = raw_damage * base_multiplier + math.min(threshold, raw_damage) * str_multiplier
	if return_damage <= 0 then return end

	-- ⚠️ GameRules:GetGameTime() — единственная живая тайм-функция в этой
	-- сборке (timers.lua/boss_spawner/runes); DotaTime() тут nil (проверено
	-- в игре 2026-08-12), GameTime() — nil (известная грабля).
	-- Частица blademail УБРАНА совсем (2026-08-12): лагала при волнах
	-- крипов. Урон отражения от визуала не зависит.
	local t = GameRules:GetGameTime()
	if t - (self.last_print or 0) > 3 then
		self.last_print = t
		print("[INVERSE] reflect in=" .. math.floor(raw_damage) .. " out=" .. math.floor(return_damage)
			.. " on " .. attacker:GetUnitName() .. " str=" .. math.floor(parent:GetStrength()))
	end

	ApplyDamage({
		victim = attacker,
		attacker = parent,
		damage = return_damage,
		damage_type = ability:GetAbilityDamageType(),
		damage_flags = DOTA_DAMAGE_FLAG_REFLECTION + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
		ability = ability
	})
end
