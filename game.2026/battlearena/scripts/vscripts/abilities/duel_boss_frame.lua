-- Интринзик-«фрейм» дуэльных боссов: поствура-метр + threat-агро (идеи: docs/boss_ai_reference.md §8.4).
-- Навешивается интринзик-способностью (runtime AddNewModifier с ability=nil теряет
-- регистрацию модификатора на повторных спавнах — грабля из AGENTS.md).
-- LinkLuaModifier здесь же: клиент узнаёт класс мода через ScriptFile способности.

LinkLuaModifier("modifier_duel_boss_frame", "lib/duel_bosses/modifiers/modifier_duel_boss_frame", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_duel_boss_stagger", "lib/duel_bosses/modifiers/modifier_duel_boss_stagger", LUA_MODIFIER_MOTION_NONE)

duel_boss_frame = duel_boss_frame or class({})

function duel_boss_frame:GetIntrinsicModifierName()
	return "modifier_duel_boss_frame"
end
