function CDOTA_PlayerResource:SetPlayerTeam(playerId, newTeam)
	local oldTeam = PlayerResource:GetTeam(playerId)
	local hero = PlayerResource:GetSelectedHeroEntity(playerId)
	PlayerTables:RemovePlayerSubscription("dynamic_minimap_points_" .. oldTeam, playerId)
	local playerPickData = {}
	local tableData = PlayerTables:GetTableValue("hero_selection", oldTeam)
	if tableData and tableData[playerId] then
		table.merge(playerPickData, tableData[playerId])
		tableData[playerId] = nil
		PlayerTables:SetTableValue("hero_selection", oldTeam, tableData)
	end

	GameRules:SetCustomGameTeamMaxPlayers(newTeam, GameRules:GetCustomGameTeamMaxPlayers(newTeam) + 1)
	for _,v in ipairs(FindAllOwnedUnits(playerId)) do
		v:SetTeam(newTeam)
	end
	PlayerResource:UpdateTeamSlot(playerId, newTeam, 1)
	PlayerResource:SetCustomTeamAssignment(playerId, newTeam)
	GameRules:SetCustomGameTeamMaxPlayers(oldTeam, GameRules:GetCustomGameTeamMaxPlayers(oldTeam) - 1)

	local newTableData = PlayerTables:GetTableValue("hero_selection", newTeam)
	if newTableData and playerPickData then
		newTableData[playerId] = playerPickData
		PlayerTables:SetTableValue("hero_selection", newTeam, newTableData)
	end

	PlayerTables:RemovePlayerSubscription("dynamic_minimap_points_" .. oldTeam, playerId)
	PlayerTables:AddPlayerSubscription("dynamic_minimap_points_" .. newTeam, playerId)

	for i = 0, hero:GetAbilityCount() - 1 do
		local skill = hero:GetAbilityByIndex(i)
		if skill then
			--print(skill.GetIntrinsicModifierName and skill:GetIntrinsicModifierName())
			if (
				skill.GetIntrinsicModifierName and
				skill:GetIntrinsicModifierName() and
				skill:GetAbilityName() ~= "meepo_divided_we_stand"
		 	) then
				RecreateAbility(hero, skill)
			end
		end
	end

	Teams:RecalculateKillWeight(oldTeam)
	Teams:RecalculateKillWeight(newTeam)

	local player = PlayerResource:GetPlayer(playerId)
	-- if player then
		-- CustomGameEventManager:Send_ServerToPlayer(player, "arena_team_changed_update", {})
	-- end
end