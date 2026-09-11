-- ============================================================================
-- Battle Arena: Augments — reroll bank (free points, no monetization)
-- ============================================================================

RerollBank = RerollBank or class({})

function RerollBank:Init()
	RerollBank.remaining = {} -- player_id -> points left this match
	RerollBank.unlimited = IsInToolsMode()
	RerollBank.synced = {}
end


--- Called when a hero first spawns: fills the free pool.
function RerollBank:PreparePlayer(player_id)
	if RerollBank.unlimited then
		RerollBank.remaining[player_id] = 99999
	else
		RerollBank.remaining[player_id] = FREE_REROLLS_PER_MATCH
	end

	RerollBank:UpdateCount(player_id)
end


function RerollBank:_Spend(player_id, tier)
	local points = RerollBank.remaining[player_id] or 0

	if RerollBank.unlimited then
		tier = 0
	end

	if points >= tier then
		RerollBank.remaining[player_id] = points - tier
		return true
	end

	return false
end


function RerollBank:Consume(player_id, tier)
	if RerollBank:_Spend(player_id, tier) then
		RerollBank:UpdateCount(player_id)
		return true
	end

	return false
end


function RerollBank:UpdateCount(player_id)
	CustomNetTables:SetTableValue("reroll_bank", tostring(player_id), {
		count = RerollBank.remaining[player_id] or 0,
	})
end


RerollBank:Init()
