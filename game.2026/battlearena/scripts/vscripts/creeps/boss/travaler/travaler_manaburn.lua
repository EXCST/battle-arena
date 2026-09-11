-- ============================================================
-- BATTLE ARENA — Travaler: Mana Burn
-- Пассивка с интринзик-модификатором: каждый удар жжёт ману,
-- наносит урон и показывает дотовский визуал сжигания маны.
-- ============================================================

travaler_manaburn = travaler_manaburn or class({})

local ability = travaler_manaburn

require('lib/ability_kv')

LinkLuaModifier("modifier_travaler_manaburn", "creeps/boss/travaler/modifiers/modifier_travaler_manaburn", LUA_MODIFIER_MOTION_NONE)


function ability:GetIntrinsicModifierName()
	return "modifier_travaler_manaburn"
end
