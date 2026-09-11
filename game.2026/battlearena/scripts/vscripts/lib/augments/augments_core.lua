-- ============================================================================
-- Battle Arena: Augments — core (state, queue, hand flow, init)
-- ============================================================================

Augments = Augments or {}

require("lib/augments/augments_tiers")
require("lib/augments/augments_math")
require("lib/augments/augments_reroll")
require("lib/augments/augments_summon_map")
require("lib/augments/augments_catalog")
require("lib/augments/augments_pool")
require("lib/augments/augments_roll")
require("lib/augments/augments_apply")
require("lib/augments/augments_orbs")
require("lib/augments/augments_summons")
require("lib/augments/augments_favorites")
require("lib/augments/augments_events")


function Augments:Init()
	local zero_meter = {
		[AUGMENT_TIER.COMMON] = 0,
		[AUGMENT_TIER.RARE] = 0,
		[AUGMENT_TIER.EPIC] = 0,
	}

	Augments.team_meter = {
		[DOTA_TEAM_GOODGUYS] = table.shallowcopy(zero_meter),
		[DOTA_TEAM_BADGUYS] = table.shallowcopy(zero_meter),
	}

	Augments.team_goal = {
		[DOTA_TEAM_GOODGUYS] = table.shallowcopy(ORB_START),
		[DOTA_TEAM_BADGUYS] = table.shallowcopy(ORB_START),
	}

	Augments.queue = {}
	Augments.hand = {}
	Augments.favs = {}
	Augments.hero_defs = {}
	Augments.hero_pools = {}
	Augments.player_points = {}
	Augments.tracked_summons = {}

	CustomGameEventManager:RegisterListener("Augments:get_hand", Dynamic_Wrap(Augments, "OnGetHand"))
	CustomGameEventManager:RegisterListener("Augments:get_orbs", Dynamic_Wrap(Augments, "OnGetOrbs"))
	CustomGameEventManager:RegisterListener("Augments:pick_card", Dynamic_Wrap(Augments, "OnPick"))
	CustomGameEventManager:RegisterListener("Augments:reroll_hand", Dynamic_Wrap(Augments, "OnReroll"))
	CustomGameEventManager:RegisterListener("Augments:get_favs", Dynamic_Wrap(Augments, "OnGetFavs"))
	CustomGameEventManager:RegisterListener("Augments:set_favs", Dynamic_Wrap(Augments, "OnSetFavs"))
	CustomGameEventManager:RegisterListener("Augments:dev_grant", Dynamic_Wrap(Augments, "OnDevGrant"))

	ListenToGameEvent("npc_spawned", Dynamic_Wrap(Augments, "OnNpcSpawned"), Augments)

	CustomNetTables:SetTableValue("augment_store", "catalog", AugmentCatalog.catalog_data)
end


--- @return CDOTA_BaseNPC|nil selected hero entity of the player
function Augments:GetHero(player_id)
	if not IsValidPlayerID(player_id) then return nil end

	local hero = PlayerResource:GetSelectedHeroEntity(player_id)
	if not IsValidEntity(hero) then return nil end

	return hero
end


--- @return table player_id -> hero (connected real heroes only)
function Augments:GetTeamHeroes(team)
	local heroes = {}

	for player_id = 0, DOTA_MAX_PLAYERS do
		if PlayerResource:IsValidPlayerID(player_id) and PlayerResource:GetTeam(player_id) == team then
			local hero = PlayerResource:GetSelectedHeroEntity(player_id)
			if IsValidEntity(hero) and hero:IsRealHero() then
				heroes[player_id] = hero
			end
		end
	end

	return heroes
end


function Augments:PendingCount(player_id)
	return #(Augments.queue[player_id] or {})
end


--- Estimated gold value of the player's augments.
function Augments:NetWorth(player_id)
	return GOLD_PER_UPGRADE * (Augments.player_points[player_id] or 0)
end


--- Queues an upgrade for every hero of the team.
function Augments:QueueForTeam(team, tier)
	for player_id, _ in pairs(Augments:GetTeamHeroes(team)) do
		Augments:QueueForPlayer(player_id, tier)
	end
end


--- Queues an upgrade for one player; opens the picker if none is open.
function Augments:QueueForPlayer(player_id, tier)
	if not IsValidPlayerID(player_id) then return end

	local hero = Augments:GetHero(player_id)
	if not hero then return end

	Augments.queue[player_id] = Augments.queue[player_id] or {}
	table.insert(Augments.queue[player_id], { tier = tier })

	if not Augments.hand[player_id] then
		Augments:ShowHand(player_id, hero, tier, false)
	else
		local player = PlayerResource:GetPlayer(player_id)
		if IsValidEntity(player) then
			CustomGameEventManager:Send_ServerToPlayer(player, "Augments:update_queue", {
				queued = #Augments.queue[player_id],
			})
		end
	end

	Augments.player_points[player_id] = (Augments.player_points[player_id] or 0) + tier
end


--- Rolls and sends a new hand to the player.
function Augments:ShowHand(player_id, hero, tier, is_reroll)
	local previous = (is_reroll and Augments.hand[player_id]) and Augments.hand[player_id].prev or {}

	local cards = {}
	local new_previous = {}

	for _, kind in ipairs({ AUGMENT_KIND.ABILITY, AUGMENT_KIND.GENERIC }) do
		local amount = CARDS_PER_HAND[kind]

		local rolled_cards
		if kind == AUGMENT_KIND.GENERIC then
			rolled_cards = Augments:RollBoonCards(player_id, tier, previous[kind], amount)
		else
			rolled_cards = Augments:RollAbilityCards(player_id, tier, previous[kind], amount)
		end

		new_previous[kind] = rolled_cards
		table.extend(cards, rolled_cards)
	end

	Augments.hand[player_id] = {
		tier = tier,
		cards = cards,
		reroll = is_reroll or false,
		prev = new_previous,
	}

	Timers:CreateTimer(0, function()
		local player = PlayerResource:GetPlayer(player_id)
		if not IsValidEntity(player) then return end

		CustomGameEventManager:Send_ServerToPlayer(player, "Augments:show_hand", {
			hand = Augments.hand[player_id],
			queued = Augments:PendingCount(player_id),
		})
	end)
end


--- "npc_spawned" — clones, illusions and summons inherit the owner's augments.
function Augments:OnNpcSpawned(event)
	local ok, err = pcall(function()
		local unit = EntIndexToHScript(event.entindex)
		if not IsValidEntity(unit) then return end

		local owner_player_id = unit:GetPlayerOwnerID()
		if not IsValidPlayerID(owner_player_id) then return end

		local hero = Augments:GetHero(owner_player_id)
		if not hero then return end

		local owner = unit:GetOwner()

		-- the hero itself respawning / being repicked
		if unit == hero then
			Augments:ApplyToClone(hero, hero, false)
			return
		end

		Timers:CreateTimer(0, function()
			if not owner or owner:IsNull() then return end
			if not IsValidEntity(unit) then return end

			local is_tempest_double = unit.IsTempestDouble and unit:IsTempestDouble()
			local is_meepo_clone = unit.IsClone and unit:IsClone()

			if unit:IsIllusion() or is_tempest_double or is_meepo_clone then
				Augments:ApplyToClone(unit, GetIllusionSource(unit) or hero)
			else
				Augments:ApplySummonBoosts(unit, unit:GetUnitName(), owner)
			end
		end)
	end)

	if not ok then
		print("[Augments] npc_spawned handler error: " .. tostring(err))
	end
end


Augments:Init()
