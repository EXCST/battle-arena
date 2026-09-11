-- ============================================================
-- STARGAZER — Cosmic Countdown (stargazer_cosmic_countdown, ability_lua)
-- Портировано из BS heroes/hero_stargazer/cosmic_countdown.lua
-- (там был datadriven OnIntervalThink 0.1 → переведено на интринзик,
-- паттерн stegius_desolating_touch).
-- Правки:
--   * GetLevelSpecialValueFor → AbilityKV:Get
--   * AutoStartCooldown → StartCooldown(GetCooldown(level-1)) — см. «Критичные грабли»
--   * таланты: +3 стата за цикл (stargazer_special_bonus_cosmic_stats),
--     цикл на 25% быстрее (stargazer_special_bonus_cosmic_interval)
-- ⚠️ Аттач modifier_stargazer_talent_stats ПЕРЕЕХАЛ в on_npc_spawned.lua
-- (интринзик уровня 0 не создаётся при спавне в этой сборке — см. 2026-08-12).
-- Сам интринзик cosmic тоже НЕ вешается через GetIntrinsicModifierName
-- (та же причина): модификатор навешивается при спавне в on_npc_spawned.lua,
-- тикер стартует в OnCreated. До прокачки ульты гард GetLevel() < 1 молчит.
-- ============================================================

require('lib/ability_kv')

LinkLuaModifier("modifier_stargazer_cosmic_countdown", "heroes/hero_stargazer/cosmic_countdown", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_stargazer_talent_stats", "heroes/hero_stargazer/modifier_stargazer_talent_stats", LUA_MODIFIER_MOTION_NONE)

stargazer_cosmic_countdown = class({})

-------------------------------------------------------------------------------

modifier_stargazer_cosmic_countdown = class({})

function modifier_stargazer_cosmic_countdown:IsHidden()
	return true
end

function modifier_stargazer_cosmic_countdown:IsPurgable()
	return false
end

function modifier_stargazer_cosmic_countdown:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(0.1)
end

function modifier_stargazer_cosmic_countdown:OnIntervalThink()
	if not IsServer() then return end

	local ability = self:GetAbility()
	if not ability then return end
	if ability:GetLevel() < 1 then return end
	if not ability:IsCooldownReady() then return end

	local caster = self:GetParent()
	if not caster or caster:IsNull() then return end

	local stats = AbilityKV:Get(ability, "stats_per_cycle")
	if not stats or stats <= 0 then stats = 4 end

	if caster:HasTalent("stargazer_special_bonus_cosmic_stats") then
		stats = stats + 3
	end

	caster:ModifyStrength(stats)
	caster:ModifyAgility(stats)
	caster:ModifyIntellect(stats)

	local cd = ability:GetCooldown(ability:GetLevel() - 1)
	if cd <= 0 then cd = 90 end
	if caster:HasTalent("stargazer_special_bonus_cosmic_interval") then
		cd = cd * 0.75
	end
	ability:StartCooldown(cd)

	caster:EmitSound("Arena.Hero_Stargazer.CosmicCountdown.Cast")

	local particle = ParticleManager:CreateParticle(
		"particles/arena/units/heroes/hero_stargazer/cosmic_countdown.vpcf",
		PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(particle)
end
