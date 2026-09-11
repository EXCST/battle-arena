Augments = Augments or {}

-- ============================================================================
-- Battle Arena: Augments вЂ” team orb meters
-- ============================================================================

--- Credits orb progress to the team; awards upgrades at each goal.
function Augments:AddOrbProgress(team, tier, amount)
	if not amount or amount == 0 then return end
	if team ~= DOTA_TEAM_GOODGUYS and team ~= DOTA_TEAM_BADGUYS then return end
	if not Augments.team_meter[team] then return end

	local meter = Augments.team_meter[team]
	local goal = Augments.team_goal[team]

	local progress = (meter[tier] or 0) + amount
	local threshold = goal[tier] or ORB_START[tier]

	if progress >= threshold then
		goal[tier] = math.min(threshold + ORB_GROWTH[tier], ORB_CEILING[tier])
		progress = progress - threshold
		Augments:QueueForTeam(team, tier)
	end

	meter[tier] = progress
	Augments:BroadcastOrbs(team)
end


--- Sends the current orb meters to the whole team.
function Augments:BroadcastOrbs(team)
	CustomGameEventManager:Send_ServerToTeam(team, "Augments:update_orbs", {
		filled = Augments.team_meter[team],
		needed = Augments.team_goal[team],
	})
end
