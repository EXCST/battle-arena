-- Интринзик-способности скалинг-кемпа.
-- Модификаторы modifier_scaling_camp_bear/boss вешаются движком при спавне юнита
-- (НЕ через AddNewModifier из Lua — runtime-регистрация теряется после гибели
--  последнего экземпляра модификатора: "unknown modifier type" на респавнах).
-- LinkLuaModifier здесь обязателен: клиент должен знать классы модификаторов
-- (иначе "unknown modifier type" на клиенте при каждом спавне).

LinkLuaModifier("modifier_scaling_camp_bear", 'lib/spawners/modifier_scaling_camp_bear', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scaling_camp_boss", 'lib/spawners/modifier_scaling_camp_boss', LUA_MODIFIER_MOTION_NONE)

scaling_camp_passive_bear = scaling_camp_passive_bear or class({})
function scaling_camp_passive_bear:GetIntrinsicModifierName()
	return "modifier_scaling_camp_bear"
end

scaling_camp_passive_boss = scaling_camp_passive_boss or class({})
function scaling_camp_passive_boss:GetIntrinsicModifierName()
	return "modifier_scaling_camp_boss"
end
