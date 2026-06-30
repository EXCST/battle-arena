require('lib/duel/duel_lib')
require('lib/attentions')
require('lib/team_helper')
require('lib/message_formatters')

local DUEL_INTERVAL = 300
local DUEL_NOBODY_WINS = 100

local DUEL_FIRST_BONUS_GOLD = 350
local DUEL_FIRST_BONUS_EXP  = 350
local DUEL_WINNER_GOLD_MULTIPLER = 150
local DUEL_WINNER_EXP_MULTIPLER = 50
local DUEL_GOLD_PER_MINUTE = 30

if DuelController == nil then
	_G.DuelController = class({})
	DuelController.timer = DuelController.timer or nil
	DuelController.is_duel = false
end

function DuelController:StartDuel(duelDuration)
	if not DuelController:_StartDuel() then
		DuelController:EndDuel( DuelLibrary.DRAW_TEAM )
		return
	end

	CustomNetTables:SetTableValue("duel", "info", {
		is_duel = true,
		countdown = duelDuration,
		last_duel_time = GameRules:GetGameTime()
	})
	
	DuelController.timer = Timers:CreateTimer({
		endTime = duelDuration,
		callback = function()
			DuelLibrary:EndDuel( DuelLibrary.DRAW_TEAM )
			--self:DelayDuelStart( DUEL_INTERVAL )
		end
	})
end

function DuelController:DelayDuelStart(duelInterval)
    CustomNetTables:SetTableValue("duel", "info", {
		is_duel = false,
		countdown = duelInterval,
		last_duel_time = GameRules:GetGameTime()
	})
	
    DuelController.timer = Timers:CreateTimer({
		endTime = duelInterval,
		callback = function()
			DuelController:StartDuel(DUEL_NOBODY_WINS)
		end
	})
end

function DuelController:EndDuel(i_winnerTeam)
	if DuelController.timer ~= nil then
		Timers:RemoveTimer(DuelController.timer)
		DuelController.timer = nil
	end
	
	DuelController.is_duel = false
	
	DuelController:DelayDuelStart(DUEL_INTERVAL)

	local duelCount = DuelLibrary:GetDuelCount()

	local goldBonus
	local expBonus

	if duelCount == 1 then
		goldBonus = DUEL_FIRST_BONUS_GOLD
		expBonus = DUEL_FIRST_BONUS_EXP
	else
		local minute = GameRules:GetGameTime() / 60

		goldBonus = DUEL_WINNER_GOLD_MULTIPLER * duelCount + DUEL_GOLD_PER_MINUTE * minute
		expBonus  = DUEL_WINNER_EXP_MULTIPLER * minute
	end

	TeamHelper:ApplyForHeroes( i_winnerTeam, function(playerid, hero)
		PlayerResource:ModifyGold(playerid, goldBonus, true, 0)

		if hero and IsValidEntity(hero) and hero:IsRealHero() and not hero:IsNull() then
			hero:AddExperience(expBonus, 0, false, true)
		end
	end,
	true)

	print("Duel end")
	--Attentions:SendChatMessage("#duel_end") 
end

function DuelController:OnGameStart()
	DuelController:DelayDuelStart(DUEL_INTERVAL)
end

--PRIVATE:
----------

function DuelController:_StartDuel()
    print("DuelController:_StartDuel start")
	local radiantHeroes = TeamHelper:GetHeroes(DOTA_TEAM_GOODGUYS)
	local direHeroes 	= TeamHelper:GetHeroes(DOTA_TEAM_BADGUYS)

	local nRadiants, nTotalRadiants, nDires, nTotalDires = DuelLibrary:GetMaximumHeroes( radiantHeroes, direHeroes, false )

	local nUnits = min(nTotalRadiants, nTotalDires)

	if nRadiants == 0 or nDires == 0 then
		--Attentions:SendChatMessage("#duel_error")
		print("Not enought players to start duel")
		return false
	end

	-- Attentions:SendChatMessage("#duel_start")
    DuelController.is_duel = true	

	DuelLibrary:StartDuel(radiantHeroes, direHeroes, nUnits, 
		function(winnerTeam) 
			DuelController:EndDuel(winnerTeam)
		end)
	
	print("DuelController:_StartDuel end")

	return true
end

function DuelController:IsDuelOngoing()
	return DuelController.is_duel
end