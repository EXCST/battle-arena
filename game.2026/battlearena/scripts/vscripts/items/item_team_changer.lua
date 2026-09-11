function SetPlayerGold(playerid, gold)
	if IsServer() then
		PlayerResource:SetGold(playerid, 0, false)
		PlayerResource:SetGold(playerid, 0, true)

		PlayerResource:ModifyGold( playerid, gold, false, 0 )
	end
end

function ChangeTeam(keys)
	local hero = keys.caster
	local ability = keys.ability
	local player = hero:GetPlayerOwner() 
	local playerid = hero:GetPlayerOwnerID()
	
	print("Duel controller is duel going", DuelController:IsDuelOngoing())
	
	if not hero:IsRealHero() or DuelController:IsDuelOngoing() then
		return
	end

	-- SOLO MODE: team switching is disabled (all players fight together)
	if SoloMode and SoloMode:IsActive() then
		return
	end
	
	local oldTeam = hero:GetTeamNumber()
	local newTeam = oldTeam == DOTA_TEAM_BADGUYS and DOTA_TEAM_GOODGUYS or DOTA_TEAM_BADGUYS
	if GetTeamPlayerCount(newTeam) > GetTeamPlayerCount(oldTeam) and not IsInToolsMode() then
		FireGameEvent("dota_hud_error_message", { reason=80, message="Too many players in your team!" })
		return
	end

	GameRules:SetCustomGameTeamMaxPlayers(newTeam, GameRules:GetCustomGameTeamMaxPlayers(newTeam) + 1)
	
	local gold = hero:GetGold()
	player:SetTeam(newTeam)
	hero:SetTeam(newTeam)
	SetPlayerGold(playerid, gold)
	
	local cour = Entities:FindAllByName("npc_dota_courier") 
	if cour then
		for i, x in pairs(cour) do
			if x and x:GetTeamNumber() == oldTeam and x:GetPlayerOwnerID() == player:GetPlayerID() then
				UTIL_Remove(x)
			end
		end
	end
	
	PlayerResource:UpdateTeamSlot(playerid, newTeam, 1)
	PlayerResource:SetCustomTeamAssignment(playerid, newTeam)

	GameRules:SetCustomGameTeamMaxPlayers(oldTeam, GameRules:GetCustomGameTeamMaxPlayers(oldTeam) - 1)
	
	PlayerResource:UpdateTeamSlot(playerid, newTeam, 1)
	PlayerResource:SetCustomTeamAssignment(playerid, newTeam)
	
	local tpPoint = newTeam == DOTA_TEAM_BADGUYS and 'DIRE_BASE' or 'RADIANT_BASE'
	FindClearSpaceForUnit(hero, Entities:FindByName( nil, tpPoint ):GetAbsOrigin(), true)
	player:SpawnCourierAtPosition(hero:GetAbsOrigin() + RandomVector(150))

	
	print("Team changer -1 charge")

	ability:SpendCharge()
end

function OnAttacked(keys)
	local ability = keys.ability
	local attacker = keys.attacker
	if attacker then
		if keys.Damage > 0 and ((attacker.IsControllableByAnyPlayer and attacker:IsControllableByAnyPlayer()) or attacker:IsBoss()) then
			ability:StartCooldown(ability:GetLevelSpecialValueFor("attacked_cooldown", ability:GetLevel() - 1))
		end
	end
end