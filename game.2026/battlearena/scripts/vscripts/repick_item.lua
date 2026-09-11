-- ============================================================
-- BATTLE ARENA — Свиток перевоплощения (item_repick)
-- item_lua-класс. Активация открывает игроку меню репика;
-- предмет расходуется только при УСПЕШНОЙ смене героя
-- (ChangeHero снимает его через repickItemName).
-- ============================================================

-- Клиент тоже грузит ScriptFile предмета (тултипы/HUD) — там нет
-- CustomGameEventManager/LoadKeyValues, поэтому модуль инициализируем
-- только на сервере (паттерн tp_s.lua).
if IsServer() then
	require('lib/repick_item')
end

item_repick = class({})

function item_repick:OnSpellStart()
	if not RepickItem then return end

	local caster = self:GetCaster()
	if not caster then return end

	local player = caster:GetPlayerOwner()
	if not player then return end

	RepickItem:Open(player)
end