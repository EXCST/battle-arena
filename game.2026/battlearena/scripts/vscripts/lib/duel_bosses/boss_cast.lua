-- lib/duel_bosses/boss_cast.lua
-- Каст-цикл дуэльных боссов (адапт. MonsterAbility_CS, см. docs/boss_ai_reference.md §4):
--   OnPhaseStart       — защита на прекаст + ОКНО КОНТР-БРЕЙКА в хвосте стойки
--                        (window = max(15% стойки, 0.25с); тюнинг — WINDOW_FRAC/WINDOW_MIN)
--   OnSpellStart       — «занятость» на канал, запись ритма duel_next_action_at,
--                        постура «выдыхается» на завершённом касте
--   OnPhaseInterrupted — срыв: КД всегда; само-стан 4с только если это НЕ контр-брейк
--                        (на контр-брейк стан уже выдан короче — 1.2с)

require('lib/duel_bosses/modifiers/modifier_duel_boss_cast')
require('lib/duel_bosses/modifiers/modifier_duel_boss_frame')

DuelBossCast = DuelBossCast or {}

local SELF_STUN_DURATION = 4
local WINDOW_FRAC = 0.15   -- доля стойки, доступная для контр-брейка
local WINDOW_MIN = 0.4     -- пол окна в секундах (2026-09-03: 0.25 → 0.4 — вариант C,
                           -- контр-брейк должен случаться чаще, чтобы влиять на постуру)
local COUNTER_GRACE = 0.6  -- сек, в которые прерывание считается «контр-брейком»

local function ensureLinks()
	LinkLuaModifier("modifier_duel_boss_cast_protection", "lib/duel_bosses/modifiers/modifier_duel_boss_cast", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_duel_boss_busy", "lib/duel_bosses/modifiers/modifier_duel_boss_cast", LUA_MODIFIER_MOTION_NONE)
end

-- Из OnAbilityPhaseStart способности.
-- opts: castPoint (длительность прекаста), window (переопределение окна)
function DuelBossCast:OnPhaseStart(ability, opts)
	opts = opts or {}

	local caster = ability:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	local castPoint = opts.castPoint or 0
	if castPoint <= 0 then return end

	local win = opts.window or math.max(castPoint * WINDOW_FRAC, WINDOW_MIN)

	ensureLinks()
	caster:AddNewModifier(caster, ability, "modifier_duel_boss_cast_protection", {
		duration = castPoint,
		window = win,
	})
end

-- Из OnAbilityPhaseInterrupted способности: срыв каста (контр-брейк или внешний стан).
function DuelBossCast:OnPhaseInterrupted(ability)
	local caster = ability:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	caster:RemoveModifierByName("modifier_duel_boss_cast_protection")
	caster:RemoveModifierByName("modifier_duel_boss_busy")

	-- контр-брейк: короткий стан уже висит — длинный «само-стан» не нужен
	local now = GameRules:GetGameTime()
	local countered = caster.duel_counter_break_at and (now - caster.duel_counter_break_at) < COUNTER_GRACE

	if not countered then
		LinkLuaModifier("modifier_duel_boss_stagger", "lib/duel_bosses/modifiers/modifier_duel_boss_stagger", LUA_MODIFIER_MOTION_NONE)
		caster:AddNewModifier(caster, ability, "modifier_duel_boss_stagger", { duration = SELF_STUN_DURATION, big = 1 })
	end

	ability:StartCooldown(ability:GetCooldown(0))

	-- после срыва босс «приходит в себя» и не кастует сразу
	caster.duel_next_action_at = now + (countered and 1.4 or SELF_STUN_DURATION + 0.5)

	print("[DuelBossCast] cast interrupted" .. (countered and " (counter-break)" or " (self-stun)"))
end

-- Из OnSpellStart способности (после успешного прекаста).
-- opts: castDuration (длительность канала, если есть)
function DuelBossCast:OnSpellStart(ability, opts)
	opts = opts or {}

	local caster = ability:GetCaster()
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	caster:RemoveModifierByName("modifier_duel_boss_cast_protection")

	local busy = opts.castDuration or 0
	local now = GameRules:GetGameTime()

	if busy > 0 then
		ensureLinks()
		caster:AddNewModifier(caster, ability, "modifier_duel_boss_busy", { duration = busy })
	end

	-- пауза от реального КД способности (формула китайцев):
	-- next = занятость + max(0, cd − занятость) + rand(1..2) + cd·rand(0.05..0.15)
	-- КД тикает и во время канала, поэтому «добираем» только остаток.
	local level = math.max(0, ability:GetLevel() - 1)
	local cd = ability:GetCooldown(level)
	if cd <= 0 then cd = 0 end

	local base = busy + math.max(0, cd - busy)
	caster.duel_next_action_at = now + base + RandomFloat(1, 2) + cd * RandomFloat(0.05, 0.15)

	DuelBossFrameUtil:CastCompleted(caster)
end

-- «Наказание за стену» для таранов: вызывается из mover-колбэка при упоре в блок.
function DuelBossCast:CrashPunish(caster, ability, staggerDur)
	if not IsValidEntity(caster) or not caster:IsAlive() then return end

	LinkLuaModifier("modifier_duel_boss_stagger", "lib/duel_bosses/modifiers/modifier_duel_boss_stagger", LUA_MODIFIER_MOTION_NONE)
	caster:AddNewModifier(caster, ability, "modifier_duel_boss_stagger", { duration = staggerDur or 0.9, big = 0 })
	DuelBossFrameUtil:AddPosture(caster, DuelBossFrameUtil.CRASH_BONUS)

	caster.duel_next_action_at = GameRules:GetGameTime() + (staggerDur or 0.9) + 0.6

	caster:EmitSound("Hero_Spirit_Breaker.GreaterBash")
	ScreenShake(caster:GetAbsOrigin(), 8, 8, 0.3, 1200, 0, true)
end
