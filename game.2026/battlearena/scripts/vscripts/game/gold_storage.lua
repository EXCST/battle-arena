GoldStorage = GoldStorage or {}

GOLD_STORAGE_THRESHOLD = 95000
GoldStorage.GOLD_STORAGE_MAX = 100000

function GoldStorage:Init()
	GoldStorage.stored_gold = {}
	GoldStorage.current_gold = {}

	CustomGameEventManager:RegisterListener("GoldStorage:poll", function(player_id, event)
		if GoldStorage.current_gold[player_id] then
			GoldFilter.guard = true
			GoldStorage:GoldChanged(player_id, GoldStorage.current_gold[player_id])
			GoldFilter.guard = false
		end
	end)

	Convars:RegisterCommand("gs_gold", function(name, amount)
		local player = Convars:GetCommandClient()
		if not player then return end
		local pid = player:GetPlayerID()
		amount = tonumber(amount)
		if not amount or amount <= 0 then return end
		GoldStorage:Deposit(pid, amount)
	end, "GoldStorage: add gold to storage", 0)

	Timers:CreateTimer(0, function()
		GoldStorage:_StorageTick()
		return 0.1
	end)
end

function GoldStorage:_StorageTick()
	for player_id = 0, 23 do
		if PlayerResource:IsValidPlayerID(player_id) then
			local hero = PlayerResource:GetSelectedHeroEntity(player_id)
			if hero and not hero:IsNull() and hero:IsRealHero() then
				local current_gold = PlayerResource:GetGold(player_id)
				local prev = GoldStorage.current_gold[player_id]
				if not prev then
					GoldStorage.current_gold[player_id] = current_gold
					GoldStorage:GoldChanged(player_id, current_gold)
				elseif current_gold ~= prev then
					GoldStorage.current_gold[player_id] = current_gold
					GoldStorage:GoldChanged(player_id, current_gold)
				end
			end
		end
	end
end

function GoldStorage:GoldChanged(player_id, current_gold)
	-- защита от петли: свои ModifyGold не должны попадать в редирект фильтра
	GoldFilter.guard = true
	if not GoldStorage.stored_gold[player_id] then GoldStorage.stored_gold[player_id] = 0 end

	if current_gold > GOLD_STORAGE_THRESHOLD then
		local gold_excess = current_gold - GOLD_STORAGE_THRESHOLD
		GoldStorage.stored_gold[player_id] = GoldStorage.stored_gold[player_id] + gold_excess
		PlayerResource:ModifyGold(player_id, -gold_excess, true, 0)
		GoldStorage.current_gold[player_id] = GOLD_STORAGE_THRESHOLD
	end

	if current_gold < GOLD_STORAGE_THRESHOLD and GoldStorage.stored_gold[player_id] > 0 then
		local missing_gold = GOLD_STORAGE_THRESHOLD - current_gold
		local available_gold = GoldStorage.stored_gold[player_id]
		if available_gold > missing_gold then
			GoldStorage.stored_gold[player_id] = available_gold - missing_gold
			PlayerResource:ModifyGold(player_id, missing_gold, true, 0)
			GoldStorage.current_gold[player_id] = GOLD_STORAGE_THRESHOLD
		else
			GoldStorage.stored_gold[player_id] = 0
			PlayerResource:ModifyGold(player_id, available_gold, true, 0)
			GoldStorage.current_gold[player_id] = current_gold + available_gold
		end
	end

	local total = GoldStorage.current_gold[player_id] + GoldStorage.stored_gold[player_id]
	local player = PlayerResource:GetPlayer(player_id)
	if player and not player:IsNull() then
		CustomGameEventManager:Send_ServerToPlayer(player, "GoldStorage:gold_changed", {
			new_gold = total
		})
	end
	CustomNetTables:SetTableValue("gold_storage", tostring(player_id), {
		total = total
	})
	GoldFilter.guard = false
end

function GoldStorage:StoreExcess(player_id, value)
	if not GoldStorage.stored_gold[player_id] then GoldStorage.stored_gold[player_id] = 0 end
	GoldStorage.stored_gold[player_id] = GoldStorage.stored_gold[player_id] + math.floor(value)
	GoldStorage.current_gold[player_id] = PlayerResource:GetGold(player_id) or 0
	local total = GoldStorage.current_gold[player_id] + GoldStorage.stored_gold[player_id]
	local player = PlayerResource:GetPlayer(player_id)
	if player and not player:IsNull() then
		CustomGameEventManager:Send_ServerToPlayer(player, "GoldStorage:gold_changed", {
			new_gold = total
		})
	end
	CustomNetTables:SetTableValue("gold_storage", tostring(player_id), {
		total = total
	})
end

function GoldStorage:Deposit(player_id, value)
	GoldStorage.stored_gold[player_id] = (GoldStorage.stored_gold[player_id] or 0) + math.ceil(value)
	GoldStorage.current_gold[player_id] = PlayerResource:GetGold(player_id) or 0
	local total = GoldStorage.current_gold[player_id] + GoldStorage.stored_gold[player_id]
	local player = PlayerResource:GetPlayer(player_id)
	if player and not player:IsNull() then
		CustomGameEventManager:Send_ServerToPlayer(player, "GoldStorage:gold_changed", { new_gold = total })
	end
	CustomNetTables:SetTableValue("gold_storage", tostring(player_id), { total = total })
end

function GoldStorage:GetTotalGold(player_id)
	return (GoldStorage.current_gold[player_id] or 0) + (GoldStorage.stored_gold[player_id] or 0)
end
