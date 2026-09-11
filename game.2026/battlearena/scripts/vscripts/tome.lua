-- ============================================================
-- BATTLE ARENA — Книги (томы)
-- item_lua-классы томов. Логика эффектов — в lib/books.lua
-- (Books:ApplyByName), здесь только обвязка: предмет потребляет
-- заряд при активации.
-- Список имён должен совпадать с Books.tome_items в lib/books.lua.
-- ============================================================

local BOOK_NAMES = {
	"item_tome_str_3",
	"item_tome_str_6",
	"item_tome_str_60",
	"item_tome_agi_3",
	"item_tome_agi_6",
	"item_tome_agi_60",
	"item_tome_int_3",
	"item_tome_int_6",
	"item_tome_int_60",
	"item_tome_un_3",
	"item_tome_un_6",
	"item_tome_un_60",
	"item_tome_lvlup",
	"item_tome_med",
}

for _, tomeName in ipairs(BOOK_NAMES) do
	_G[tomeName] = class({})

	_G[tomeName].OnSpellStart = function(self)
		if not Books then return end

		local caster = self:GetCaster()
		Books:ApplyByName(caster, self:GetName())
		self:SpendCharge(0)
	end
end
