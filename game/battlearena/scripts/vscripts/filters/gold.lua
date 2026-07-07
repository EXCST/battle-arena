GoldFilter = GoldFilter or {}

function GoldFilter:ModifyGoldFilter(event)
	local player_id = event.player_id_const
	if not PlayerResource:IsValidPlayerID(player_id) then return true end

	local hero = PlayerResource:GetSelectedHeroEntity(player_id)
	if not hero or hero:IsNull() then return true end

	return true
end

function GoldFilter:BountyRuneFilter(event)
	local player_id = event.player_id_const
	if not PlayerResource:IsValidPlayerID(player_id) then return true end

	local hero = PlayerResource:GetSelectedHeroEntity(player_id)
	if not hero or hero:IsNull() then return true end

	return true
end
