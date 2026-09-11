Augments = Augments or {}

-- ============================================================================
-- Battle Arena: Augments вЂ” favorites
-- ============================================================================

function Augments:IsFav(player_id, ability_name, stat_name)
	if not Augments.favs[player_id] then return false end
	if not Augments.favs[player_id][ability_name] then return false end
	return Augments.favs[player_id][ability_name][stat_name] ~= nil
end


function Augments:HasFavs(player_id)
	return table.count(Augments.favs[player_id] or {}) > 0
end


function Augments:HasFavsFor(player_id, ability_name)
	return table.count((Augments.favs[player_id] or {})[ability_name] or {}) > 0
end
