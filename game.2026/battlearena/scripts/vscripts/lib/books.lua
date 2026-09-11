-- ============================================================
-- BATTLE ARENA — Книги (томы)
-- Мгновенное потребление томов:
--  1. Покупка: перехват DOTA_UNIT_ORDER_PURCHASE_ITEM в
--     ExecuteOrderFilter — золото списывается, эффект применяется,
--     заказ отменяется (предмет не создаётся, инвентарь не нужен).
--  2. Подбор/передача/взятие из сташа: ItemAddedToInventoryFilter
--     (filters/neutral_slot_filter.lua) — OnSpellStart предмета.
-- ============================================================

Books = Books or {}

Books.tome_items = {
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

local TOME_NAMES = {}
for _, name in ipairs(Books.tome_items) do
	TOME_NAMES[name] = true
end

local TOME_CONFIG = {
	item_tome_str_3  = { str = 3 },
	item_tome_str_6  = { str = 6 },
	item_tome_str_60 = { str = 60 },
	item_tome_agi_3  = { agi = 3 },
	item_tome_agi_6  = { agi = 6 },
	item_tome_agi_60 = { agi = 60 },
	item_tome_int_3  = { int = 3 },
	item_tome_int_6  = { int = 6 },
	item_tome_int_60 = { int = 60 },
	item_tome_un_3   = { str = 3, agi = 3, int = 3 },
	item_tome_un_6   = { str = 6, agi = 6, int = 6 },
	item_tome_un_60  = { str = 60, agi = 60, int = 60 },
}

function Books:IsTome(itemName)
	return TOME_NAMES[itemName] == true
end

function Books:GetCost(itemName)
	return self.costs[itemName] or 0
end

function Books:Init()
	if self._initialized then return end
	self._initialized = true

	self.costs = {}
	local kv = LoadKeyValues("scripts/npc/npc_items_custom.txt")
	if not kv then return end

	local abilities = kv.DOTAAbilities or kv
	for name, def in pairs(abilities) do
		if type(def) == "table" and TOME_NAMES[name] and def.ItemCost then
			self.costs[name] = tonumber(def.ItemCost) or 0
		end
	end
end

local function IsValidCaster(caster)
	if not caster or caster:IsNull() then return false end
	if not caster:IsRealHero() then return false end
	if caster:HasModifier("modifier_arc_warden_tempest_double") then return false end
	return true
end

--- Единая точка применения эффекта книги. Вызывается и при покупке,
--- и из OnSpellStart предмета (подбор/передача/сташ).
function Books:ApplyByName(caster, itemName)
	if not IsValidCaster(caster) then return end

	if itemName == "item_tome_lvlup" then
		caster:HeroLevelUp(true)
	elseif itemName == "item_tome_med" then
		caster.medical_tractates = (caster.medical_tractates or 0) + 1

		while caster:HasModifier("modifier_medical_tractate") do
			caster:RemoveModifierByName("modifier_medical_tractate")
		end

		caster:AddNewModifier(caster, nil, "modifier_medical_tractate", nil)
	else
		local cfg = TOME_CONFIG[itemName]
		if not cfg then return end

		if cfg.str and cfg.str > 0 then caster:ModifyStrength(cfg.str) end
		if cfg.agi and cfg.agi > 0 then caster:ModifyAgility(cfg.agi) end
		if cfg.int and cfg.int > 0 then caster:ModifyIntellect(cfg.int) end
	end

	-- пересчёт оверкап-пула маны (синхронно, ничего не теряется)
	if ManaPool and caster.mana_pool then
		ManaPool:Recalc(caster)
	end
end

--- Пытается мгновенно применить том при попадании в инвентарь героя.
--- Возвращает true, если том потреблён (предмет не добавляется в инвентарь).
function Books:TryConsume(unit, item)
	if not unit or not item then return false end
	local itemName = item:GetName()
	if not itemName or not self:IsTome(itemName) then return false end
	if not IsValidCaster(unit) then return false end

	local ok = xpcall(function()
		self:ApplyByName(unit, itemName)
		item:SpendCharge(0)
	end, function(e)
		print("[Books] consume error on " .. itemName .. ": " .. tostring(e))
	end)

	return ok == true
end

--- Перехват заказа покупки тома: списывает золото, применяет эффект и
--- отменяет заказ движка (предмет не создаётся — инвентарь не требуется).
--- Возвращает true, если заказ обработан (движку нужно вернуть false).
function Books:OnPurchaseOrder(event)
	if not event then return false end
	if event.order_type ~= DOTA_UNIT_ORDER_PURCHASE_ITEM then return false end

	local unit = EntIndexToHScript(event.units and event.units["0"])
	if not unit or unit:IsNull() then return false end
	if not IsValidCaster(unit) then return false end

	local itemName = event.shop_item_name
	if not itemName or not self:IsTome(itemName) then return false end

	self:Init()

	local cost = self:GetCost(itemName)
	if cost <= 0 then return false end

	if (unit:GetGold() or 0) < cost then return true end

	unit:ModifyGold(-cost, true, DOTA_ModifyGold_PurchaseItem)

	local ok = xpcall(function()
		self:ApplyByName(unit, itemName)
	end, function(e)
		print("[Books] purchase error on " .. itemName .. ": " .. tostring(e))
	end)

	if not ok then
		unit:ModifyGold(cost, true, DOTA_ModifyGold_PurchaseItem)
		return true
	end

	EmitSoundOn("Item.TomeOfKnowledge", unit)
	return true
end
