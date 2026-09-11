-- lib/solo/solo_mode.lua
-- Solo game mode (map "5v5_solo"): all players are forced to radiant,
-- duels become solo boss fights (see lib/solo/solo_duel.lua).

SoloMode = SoloMode or class({})

local SOLO_MAP_NAME = "5v5_solo"

function SoloMode:Init()
	self.active = GetMapName() == SOLO_MAP_NAME
	if self.active then
		print("[SOLO] Solo mode active")
		GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 10)
		GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 0)
	end
end

function SoloMode:IsActive()
	return self.active or false
end

function SoloMode:OnPlayerConnected(playerID)
	if not self:IsActive() then return end
	if playerID == nil or not PlayerResource:IsValidPlayerID(playerID) then return end

	local team = PlayerResource:GetTeam(playerID)
	if team ~= DOTA_TEAM_GOODGUYS then
		PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_GOODGUYS)
		PlayerResource:UpdateTeamSlot(playerID, DOTA_TEAM_GOODGUYS, 1)
		print("[SOLO] Player", playerID, "forced to radiant")
	end
end

-- Called at PRE_GAME / GAME_IN_PROGRESS: moves any stragglers (heroes already spawned)
-- to radiant so the whole lobby ends up in one team.
function SoloMode:ForceAllToRadiant()
	if not self:IsActive() then return end

	for playerID = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:IsValidPlayerID(playerID) then
			local team = PlayerResource:GetTeam(playerID)
			if team ~= DOTA_TEAM_GOODGUYS then
				local player = PlayerResource:GetPlayer(playerID)
				local hero = PlayerResource:GetSelectedHeroEntity(playerID)
				if player and not player:IsNull() then
					player:SetTeam(DOTA_TEAM_GOODGUYS)
				end
				if hero and not hero:IsNull() and IsValidEntity(hero) then
					hero:SetTeam(DOTA_TEAM_GOODGUYS)
				end
				PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_GOODGUYS)
				PlayerResource:UpdateTeamSlot(playerID, DOTA_TEAM_GOODGUYS, 1)
				print("[SOLO] Forced player", playerID, "to radiant")
			end
		end
	end
end