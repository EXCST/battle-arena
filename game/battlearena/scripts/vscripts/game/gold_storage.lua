GoldStorage = GoldStorage or {}

GOLD_STORAGE_THRESHOLD = 95000

function GoldStorage:Init()
	GoldStorage.stored_gold = {}
	GoldStorage.current_gold = {}

	Timers:CreateTimer(0, function()
		GoldStorage:_StorageTick()
		return 0.1
	end)
end

function GoldStorage:_StorageTick()
	for player_id, _ in pairs(GoldStorage.known_heroes or {}) do
		local hero = PlayerResource:GetSelectedHeroEntity(player_id)
		if hero and not hero:IsNull() then
			local current_gold = PlayerResource:GetGold(player_id)
			if not GoldStorage.current_gold[player_id] then
				GoldStorage.current_gold[player_id] = current_gold
				GoldStorage:GoldChanged(player_id, current_gold)
			elseif current_gold ~= GoldStorage.current_gold[player_id] then
				GoldStorage.current_gold[player_id] = current_gold
				GoldStorage:GoldChanged(player_id, current_gold)
			end
		end
	end
end

function GoldStorage:GoldChanged(player_id, current_gold)
	local player = PlayerResource:GetPlayer(player_id)
	if not player or player:IsNull() then return end
	if not GoldStorage.stored_gold[player_id] then GoldStorage.stored_gold[player_id] = 0 end

	if current_gold > GOLD_STORAGE_THRESHOLD then
		local gold_excess = current_gold - GOLD_STORAGE_THRESHOLD
		GoldStorage.stored_gold[player_id] = GoldStorage.stored_gold[player_id] + gold_excess
		PlayerResource:SpendGold(player_id, gold_excess, 0)
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

	CustomGameEventManager:Send_ServerToPlayer(player, "GoldStorage:gold_changed", {
		new_gold = GoldStorage.current_gold[player_id] + GoldStorage.stored_gold[player_id]
	})
end

function GoldStorage:Deposit(player_id, value)
	GoldStorage.stored_gold[player_id] = (GoldStorage.stored_gold[player_id] or 0) + math.ceil(value)
	GoldStorage:_StorageTick()
end

function GoldStorage:GetTotalGold(player_id)
	return (GoldStorage.current_gold[player_id] or 0) + (GoldStorage.stored_gold[player_id] or 0)
end

GoldStorage:Init()
