if RepickItem then return end

RepickItem = class({})

require('lib/utils')
require('lib/hero_change')
require('lib/kv_preloaded_data')
require('lib/duel/duel_controller')
require('lib/attentions')

local REPICK_ITEM_NAME = "item_repick"

function RepickItem:_init()
	if self.initialized then return end
	self.initialized = true

	self.roster = {}
	self.pending = {}

	local heroes = LoadKeyValues("scripts/npc/herolist.txt")
	if not heroes then
		print("[RepickItem] ERROR: scripts/npc/herolist.txt not found")
		return
	end

	local hero_data = PreloadCache:GetHeroData()

	for hero_name, is_enable in pairs(heroes) do
		if is_enable == 1 then
			local info = hero_data[hero_name]
			if info then
				-- gods are boss-kill rewards, not available via the item
				if tonumber(info.IsGod) ~= 1 then
					self.roster[hero_name] = { custom = tonumber(info.IsCustom) == 1 and 1 or 0 }
				end
			else
				print("[RepickItem] WARNING: hero " .. hero_name .. " has no data in PreloadCache, skipped")
			end
		end
	end

	CustomGameEventManager:RegisterListener("aa_repick_item_start_repick", Dynamic_Wrap(self, '_repickHero'))
end

function RepickItem:CanUseNow()
	if DuelController and DuelController:IsDuelOngoing() then
		return false
	end
	return true
end

function RepickItem:_BuildPicked()
	local picked = {}

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero and not hero:IsNull() and hero:IsRealHero() and not hero:IsIllusion() then
			local name = hero:GetUnitName()
			if name and #name > 0 then
				picked[name] = true
			end
		end
	end

	for name, taken in pairs(self.pending) do
		if taken then
			picked[name] = true
		end
	end

	return picked
end

function RepickItem:Open(player)
	local playerid = player:GetPlayerID()
	if playerid == nil then return false end

	if not self:CanUseNow() then
		Attentions:SendChatMessage("#AA_REPICK_ITEM_DUEL_BLOCKED", playerid, 0)
		return false
	end

	local hero = player:GetAssignedHero()
	if not hero or not IsConnected(hero) then return false end

	local picked = self:_BuildPicked()

	local data = {}
	for hero_name, info in pairs(self.roster) do
		data[hero_name] = { picked = picked[hero_name] and 1 or 0, custom = info.custom or 0 }
	end

	CustomGameEventManager:Send_ServerToPlayer(player, "aa_repick_item_set_data", data)
	CustomGameEventManager:Send_ServerToPlayer(player, "aa_repick_item_open", {})

	return true
end

function RepickItem:Close(player)
	CustomGameEventManager:Send_ServerToPlayer(player, "aa_repick_item_close", {})
end

function RepickItem:PickHero(player, hero_name)
	local playerid = player:GetPlayerID()

	local hero = player:GetAssignedHero()
	if not hero or not IsConnected(hero) then return false end

	if not self.roster[hero_name] then return false end

	-- re-check server-side: another player may have repicked into this hero meanwhile
	local picked = self:_BuildPicked()
	if picked[hero_name] then
		self:Close(player)
		return false
	end

	local checkFunction = function()
		return self:CanUseNow()
	end

	if not checkFunction() then
		self:Close(player)
		Attentions:SendChatMessage("#AA_REPICK_ITEM_DUEL_BLOCKED", playerid, 0)
		return false
	end

	local onSuccess = function()
		self.pending[hero_name] = nil

		CustomGameEventManager:Send_ServerToAllClients("aa_repick_item_set_hero_picked", {
			["hero_name"] = hero_name,
			["picked"]    = 1,
		})
		CustomGameEventManager:Send_ServerToPlayer(player, "aa_repick_item_close", {})
	end

	local onFailed = function()
		self.pending[hero_name] = nil
		CustomGameEventManager:Send_ServerToPlayer(player, "aa_repick_item_close", {})
	end

	self.pending[hero_name] = true

	ChangeHero(player, hero, hero_name, onSuccess, onFailed, checkFunction, REPICK_ITEM_NAME)

	return true
end

function RepickItem:_repickHero(data)
	local player_id = data['PlayerID']
	if not player_id then return end

	local player = PlayerResource:GetPlayer(player_id)
	if not player then return end

	local hero_name = data['hero_name']
	if not hero_name then return end

	RepickItem:PickHero(player, hero_name)
end

RepickItem:_init()