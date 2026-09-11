GoldFilter = GoldFilter or {}

function GoldFilter:ModifyGoldFilter(event)
	local player_id = event.player_id_const
	if not PlayerResource:IsValidPlayerID(player_id) then return true end

	local gold_change = event.gold
	if gold_change <= 0 then return true end

	if GoldStorage and GoldStorage.guard then return true end

	-- Движок не даёт золоту игрока превысить 100000.
	-- Перехватываем начисление ДО применения капа: на руки даём ровно до потолка,
	-- излишек сразу кладём в хранилище, чтобы баунти не сгорало.
	if GoldStorage and GoldStorage.GOLD_STORAGE_MAX then
		local current = PlayerResource:GetGold(player_id)
		local room = GoldStorage.GOLD_STORAGE_MAX - current
		if event.gold > room then
			local excess = event.gold - room
			event.gold = math.max(room, 0)
			GoldStorage:StoreExcess(player_id, excess)
		end
	end

	return true
end

function GoldFilter:BountyRuneFilter(event)
	return true
end
