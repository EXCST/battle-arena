-- ============================================================
-- MIRRATIE — Sixth Sense: додж-холдер (Lua-часть перепорта из BS)
-- ⚠️ 2026-08-13: способность — datadriven (KV: движковая аура 940 +
-- PROVIDES_FOW_POSITION + эвейшн + BLIND — BS 1-в-1, работает).
-- ⚠️ Вариант А (self-навешивание маркера сканером) ПРОВАЛИЛСЯ:
-- FOW-позиция от «своего» модификатора видна только своей команде
-- юнита — чувство пропадало. Откат на движковую ауру.
-- В BS додж (dodge_chance_pct) жил в ОБЩЕМ Lua-фильтре урона
-- INCOMING_DAMAGE_MODIFIERS (data/ability_functions.lua:373-382) —
-- такой системы в нашем проекте нет (грабли: SetDamageFilter не
-- вызывается), поэтому адаптирован как скрытый модификатор-холдер
-- с MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE (рабочий паттерн
-- сборки; проверено 2026-08-13: DODGE SUCCESS в логе).
-- Вешается в on_npc_spawned.lua (паттерн stargazer cosmic_countdown).
-- ⚠️ DeclareFunctions обязателен для проперти (проверено 2026-08-13).
-- ============================================================

require('lib/ability_kv')

modifier_mirratie_sixth_sense_dodge = modifier_mirratie_sixth_sense_dodge or class({})

function modifier_mirratie_sixth_sense_dodge:IsHidden() return true end
function modifier_mirratie_sixth_sense_dodge:IsPurgable() return false end
function modifier_mirratie_sixth_sense_dodge:RemoveOnDeath() return false end

function modifier_mirratie_sixth_sense_dodge:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end

-- Додж ЛЮБОГО входящего урона (аналог BS INCOMING_DAMAGE_MODIFIERS).
-- Ролл только на сервере: клиент показывает превью урона, сервер
-- обнуляет. Смертельные удары доджатся корректно (урон обнулён ДО применения).
function modifier_mirratie_sixth_sense_dodge:GetModifierIncomingDamage_Percentage()
	if not IsServer() then return 0 end

	local parent = self:GetParent()
	if not parent or parent:IsNull() or not parent:IsAlive() then return 0 end
	if parent:PassivesDisabled() then return 0 end

	local ability = parent:FindAbilityByName("mirratie_sixth_sense")
	if not ability or not IsValidEntity(ability) then return 0 end

	local chance = AbilityKV:Get(ability, "dodge_chance_pct")
	if not chance or chance <= 0 then return 0 end

	if RollPercentage(chance) then
		ParticleManager:CreateParticle(
			"particles/units/heroes/hero_faceless_void/faceless_void_backtrack.vpcf",
			PATTACH_ABSORIGIN_FOLLOW, parent)
		return -100
	end
	return 0
end
