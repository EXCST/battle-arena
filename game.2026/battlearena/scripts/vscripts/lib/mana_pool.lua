-- ============================================================
-- BATTLE ARENA — ManaPool
-- Обход движкового капа маны 65535/65536 (uint16-поле маны).
--
-- Движок Dota 2 жёстко клампит макс. ману на ~65535: при большом инте
-- + медицинских трактатах манапул «застревает».
--
-- Решение: «резерв» (виртуальная мана сверх капа).
--   overcap_max = несрезанный пул − MANA_CAP (считаем сами: инт + трактаты
--                 + флэт-бонусы предметов + остаток базы)
--   Движковая мана ведёт себя ПОЛНОСТЬЮ естественно: касты тратят её,
--   реген наполняет, ванильный бар/цифра реагируют как обычно.
--   Резерв тратится только когда движковой маны не хватает на каст:
--     в ExecuteOrderFilter дополняем движок из резерва (SetMana) — движок
--     сам спишет полную стоимость; блок при нехватке объединённого пула.
--   Покупки (тома/трактаты/аугменты/предметы) зачисляют в резерв ТОЛЬКО
--     «перелив» сверх капа: overflow = max(0, движковая + delta − CAP),
--     движок сам зачисляет min(delta, CAP − движковая) — сумма ровно delta.
--   Реген резерва: когда движковая мана полна (движковый реген уходит
--     впустую), переливаем GetManaRegen() в резерв (тикер 1с).
--
-- Клиент видит реальные цифры через nettable "mana_pool".
-- ============================================================

ManaPool = ManaPool or {}

ManaPool.MANA_CAP = 65535      -- подтверждено в игре: пул стоит на 65536 (0x10000)
ManaPool.INT_MANA = 12         -- 1 инт = 12 маны (движок)
ManaPool.TRACTATE_MANA = 300   -- modifier_medical_tractate: 300 маны за том
ManaPool.SYNC_INTERVAL = 0.5   -- синк nettable
ManaPool.RECHECK_INTERVAL = 1.0 -- пересчёт предметов/остатка базы + реген резерва

-- Ордера каста: CAST_TARGET(3), CAST_POSITION(4), CAST_TARGET_TREE(5),
-- CAST_NO_TARGET(6), CAST_TOGGLE(7), CAST_TOGGLE_AUTO(8)
local CAST_ORDERS = {
	[DOTA_UNIT_ORDER_CAST_TARGET] = true,
	[DOTA_UNIT_ORDER_CAST_POSITION] = true,
	[DOTA_UNIT_ORDER_CAST_TARGET_TREE] = true,
	[DOTA_UNIT_ORDER_CAST_NO_TARGET] = true,
	[DOTA_UNIT_ORDER_CAST_TOGGLE] = true,
	[DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO] = true,
}

function ManaPool:Init()
	if self._initialized then return end
	self._initialized = true
	self.heroes = {}

	-- Тикер синка + пересчёта предметов/базы + регена резерва (0.5с/1с)
	local sync_elapsed = 0
	Timers:CreateTimer(function()
		sync_elapsed = sync_elapsed + self.SYNC_INTERVAL
		self:SyncTick(sync_elapsed >= self.RECHECK_INTERVAL)
		if sync_elapsed >= self.RECHECK_INTERVAL then sync_elapsed = 0 end
		return self.SYNC_INTERVAL
	end)
end

--- Регистрация героя (пик/репик/спавн).
function ManaPool:TrackHero(hero)
	if not hero or hero:IsNull() then return end
	if not hero:IsRealHero() then return end
	if hero.mana_pool then return end

	self.heroes = self.heroes or {}

	local pool = { overcap_max = 0, overcap_cur = 0, base_estimate = nil }
	hero.mana_pool = pool
	self.heroes[hero] = pool
	self:Recalc(hero)
	print("[ManaPool] tracked " .. hero:GetUnitName() .. " int=" .. math.floor(hero:GetIntellect(true)) .. " maxMana=" .. math.floor(hero:GetMaxMana()))
end

--- Полный «несрезанный» манапул героя.
function ManaPool:GetUncappedMana(hero, pool)
	local known = hero:GetIntellect(true) * self.INT_MANA
		+ (hero.medical_tractates or 0) * self.TRACTATE_MANA
		+ self:GetItemMana(hero)

	local max_engine = hero:GetMaxMana()

	-- Остаток базы (базовая мана героя + неизвестные источники) захватываем,
	-- пока движок считает корректно (ниже капа).
	if pool.base_estimate == nil or max_engine < self.MANA_CAP then
		pool.base_estimate = math.max(0, max_engine - known)
	end

	return known + pool.base_estimate
end

--- Сумма флэт-мана-бонусов предметов (инвентарь + бэкпак + сташ + нейтрал).
function ManaPool:GetItemMana(hero)
	local total = 0
	for slot = 0, 17 do
		local item = hero:GetItemInSlot(slot)
		if item and not item:IsNull() then
			local bonus = item.mana_pool_bonus
			if bonus == nil then
				bonus = AbilityKV:Get(item, "bonus_mana")
				if bonus == 0 then bonus = AbilityKV:Get(item, "mana_bonus") end
				item.mana_pool_bonus = bonus
			end
			total = total + bonus
		end
	end
	return total
end

--- Пересчёт резерва. Вызывается СИНХРОННО в момент изменения пула
--- (покупка тома, трактат, аугмент, репик) — ничего не теряется.
--- В резерв зачисляется ТОЛЬКО «перелив» сверх движкового капа:
---   overflow = max(0, движковая_текущая + delta − MANA_CAP).
--- Движок сам зачисляет min(delta, CAP − движковая) — сумма ровно delta,
--- двойного начисления нет ни при каком уровне движковой маны.
function ManaPool:Recalc(hero)
	local pool = hero.mana_pool
	if not pool then return end

	local uncapped = self:GetUncappedMana(hero, pool)
	local new_max = math.max(0, math.floor(uncapped - self.MANA_CAP))

	if new_max ~= pool.overcap_max then
		local delta = new_max - pool.overcap_max
		pool.overcap_max = new_max

		local overflow = math.max(0, hero:GetMana() + delta - self.MANA_CAP)
		pool.overcap_cur = math.max(0, math.min(pool.overcap_cur + overflow, new_max))

		self:SyncPlayer(hero, pool)
		print("[ManaPool] " .. hero:GetUnitName() .. " uncapped=" .. math.floor(uncapped) .. " overcap_max=" .. new_max .. " overcap_cur=" .. math.floor(pool.overcap_cur))
	end
end

--- Тикер синка: nettable + пересчёт (предметы, база) + реген резерва.
function ManaPool:SyncTick(recheck)
	for hero, pool in pairs(self.heroes) do
		if hero:IsNull() then
			self.heroes[hero] = nil
		else
			if recheck then
				self:Recalc(hero)
				self:RegenReserve(hero, pool)
			end
			self:SyncPlayer(hero, pool)
		end
	end
end

--- Реген резерва: движковая мана полна → её реген уходит впустую,
--- переливаем его в резерв (до overcap_max).
function ManaPool:RegenReserve(hero, pool)
	if pool.overcap_max <= 0 then return end
	if pool.overcap_cur >= pool.overcap_max then return end

	local cur = hero:GetMana()
	local max_mana = hero:GetMaxMana()
	if cur + 1 < max_mana then return end -- движковая не полна — пусть регенерит движок

	local regen = hero:GetManaRegen()
	if not regen or regen <= 0 then return end

	pool.overcap_cur = math.min(pool.overcap_cur + regen * self.RECHECK_INTERVAL, pool.overcap_max)
end

function ManaPool:SyncPlayer(hero, pool)
	local pid = hero:GetPlayerOwnerID()
	if not IsValidPlayerID(pid) then return end

	CustomNetTables:SetTableValue("mana_pool", tostring(pid), {
		cur = math.floor(hero:GetMana() + pool.overcap_cur),
		max = math.floor(hero:GetMaxMana() + pool.overcap_max),
		oc = math.floor(pool.overcap_max),
	})
end

--- Обработка ордера каста: блок при нехватке объединённого пула;
--- при нехватке движковой маны (но покрытии резервом) — дополняем движок
--- из резерва, движок сам спишет полную стоимость.
--- Вызывается из ExecuteOrderFilter. Возвращает true = пропустить заказ.
function ManaPool:BlockCastOrder(event)
	if not event then return true end
	if not CAST_ORDERS[event.order_type] then return true end

	local unit = EntIndexToHScript(event.units and event.units["0"])
	if not unit or unit:IsNull() then return true end

	local pool = unit.mana_pool
	if not pool or pool.overcap_max <= 0 then return true end

	local ability = unit:FindAbilityByName(event.abilityname)
	if not ability then return true end

	local cost = self:GetManaCost(ability)
	if cost <= 0 then return true end

	local engine_cur = unit:GetMana()
	local available = engine_cur + pool.overcap_cur

	if available < cost then
		print("[ManaPool] blocked cast " .. tostring(event.abilityname) .. " (cost=" .. cost .. ", available=" .. math.floor(available) .. ")")
		return false
	end

	if engine_cur < cost and pool.overcap_cur > 0 then
		local need = cost - engine_cur
		local take = math.min(need, pool.overcap_cur)
		pool.overcap_cur = pool.overcap_cur - take
		unit:SetMana(engine_cur + take)
	end
	return true
end

--- Реальная стоимость каста (после редукций манакоста, если API доступен).
function ManaPool:GetManaCost(ability)
	local level = ability:GetLevel()

	if ability.GetActualManaCost then
		local ok, cost = xpcall(function()
			return ability:GetActualManaCost(level)
		end, function() return nil end)
		if ok and type(cost) == "number" and cost > 0 then
			return cost
		end
	end

	return ability:GetManaCost(level)
end
