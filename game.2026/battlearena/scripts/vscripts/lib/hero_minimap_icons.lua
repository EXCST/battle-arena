-- ============================================================
-- BATTLE ARENA — HeroMinimapIcons
-- Серверные позиции кастомных героев для клиентского оверлея миникарты
-- (topbar_custom_icons.js). Клиент не может получить entity из индекса
-- (Entities.GetEntityByIndex отсутствует в этой сборке), а Game.GetMapInfo()
-- на клиенте пуст — поэтому проценты миникарты считает СЕРВЕР
-- (паттерн mana_pool / BS dynamic_minimap WorldPosToMinimap).
-- Границы мира: GetWorldMinBound/GetWorldMaxBound (штатный API), фолбэк ±8192.
-- ============================================================

HeroMinimapIcons = HeroMinimapIcons or {}

HeroMinimapIcons.NET_TABLE = "hero_minimap_icons"
HeroMinimapIcons.SYNC_INTERVAL = 0.5

-- Кастомные герои с кастомными иконками миникарты (синхронно со списком
-- CUSTOM_HEROES в topbar_custom_icons.js)
HeroMinimapIcons.CUSTOM_HEROES = {
	["npc_dota_hero_stegius"] = true,
	["npc_dota_hero_saber"] = true,
	["npc_dota_hero_arthas"] = true,
	["npc_dota_hero_stargazer"] = true,
}

function HeroMinimapIcons:Init()
	if self._initialized then return end
	self._initialized = true
	self:GetWorldBounds()

	Timers:CreateTimer(function()
		self:SyncTick()
		return self.SYNC_INTERVAL
	end)
end

--- Границы мира (кэш). Фолбэк ±8192, если API недоступен.
function HeroMinimapIcons:GetWorldBounds()
	if self.world_bounds then return self.world_bounds end

	local min_v, max_v = nil, nil
	local ok = pcall(function()
		min_v = GetWorldMinBound()
		max_v = GetWorldMaxBound()
	end)
	if ok and min_v and max_v then
		self.world_bounds = { min_x = min_v.x, max_x = max_v.x, min_y = min_v.y, max_y = max_v.y }
		print("[HeroMinimapIcons] world bounds (API): min=" .. math.floor(self.world_bounds.min_x)
			.. "," .. math.floor(self.world_bounds.min_y)
			.. " max=" .. math.floor(self.world_bounds.max_x)
			.. "," .. math.floor(self.world_bounds.max_y))
	else
		self.world_bounds = { min_x = -8192, max_x = 8192, min_y = -8192, max_y = 8192 }
		print("[HeroMinimapIcons] world bounds (FALLBACK +-8192): GetWorldMin/MaxBound failed")
	end
	return self.world_bounds
end

--- Мир → проценты миникарты (Y инвертирован: юг внизу).
function HeroMinimapIcons:WorldPosToMinimap(pos)
	local b = self:GetWorldBounds()
	local pct1 = (pos.x - b.min_x) / (b.max_x - b.min_x) * 100
	local pct2 = (b.max_y - pos.y) / (b.max_y - b.min_y) * 100
	return math.max(0, math.min(100, pct1)), math.max(0, math.min(100, pct2))
end

function HeroMinimapIcons:SyncTick()
	local diag_time = GameRules:GetGameTime()
	local do_diag = not self._last_diag or diag_time - self._last_diag > 10
	if do_diag then self._last_diag = diag_time end

	for player_id = 0, DOTA_MAX_PLAYERS - 1 do
		if PlayerResource:IsValidPlayerID(player_id) then
			local hero = PlayerResource:GetSelectedHeroEntity(player_id)
			local key = tostring(player_id)
			local is_custom = false
			if hero and not hero:IsNull() and hero:IsRealHero() and not hero:IsIllusion() then
				local name = hero:GetUnitName()
				if self.CUSTOM_HEROES[name] then
					is_custom = true
					local pos = hero:GetAbsOrigin()
					local pct_x, pct_y = self:WorldPosToMinimap(pos)
					CustomNetTables:SetTableValue(self.NET_TABLE, key, {
						hero = name,
						x = pct_x,
						y = pct_y,
					})
					if do_diag then
						print("[HeroMinimapIcons] pid=" .. player_id .. " hero=" .. name
							.. " pct=" .. math.floor(pct_x) .. "%," .. math.floor(pct_y) .. "%")
					end
				end
			end
			if not is_custom then
				-- герой не кастомный / отсутствует — убираем ключ (nil удаляет)
				CustomNetTables:SetTableValue(self.NET_TABLE, key, nil)
			end
		end
	end
end
