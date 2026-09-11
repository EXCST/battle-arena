-- lib/duel_bosses/modifiers/modifier_duel_boss_dummy.lua
-- Пустой думающий-модификатор для CreateModifierThinker
-- (мишень tracking-снарядов, якоря и т.п.).

modifier_duel_boss_dummy = modifier_duel_boss_dummy or class({})

function modifier_duel_boss_dummy:IsHidden()         return true end
function modifier_duel_boss_dummy:IsPurgable()       return false end
function modifier_duel_boss_dummy:IsDebuff()          return false end
function modifier_duel_boss_dummy:DestroyOnExpire()  return true  end