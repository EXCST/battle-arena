Augments = Augments or {}

-- ============================================================================
-- Battle Arena: Augments вЂ” hand rolling (filtering, weights, draws)
-- ============================================================================

--- Filters a definition pool down to cards that may be offered this hand.
---@param pool table array of canonical definitions
---@param tier AUGMENT_TIER
---@param hero CDOTA_BaseNPC
---@param exclude_map table<string, boolean> "stat_ability" keys to skip (reroll)
---@param use_favs boolean
---@param player_id number
function Augments:ApplyFilters(pool, tier, hero, exclude_map, use_favs, player_id)
	local hero_capability = hero:GetAttackCapability()
	local is_universal = hero:GetPrimaryAttribute() == DOTA_ATTRIBUTE_ALL
	local now = GameRules:GetDOTATime(false, false)
	local state = hero.augment_state or {}

	local result = {}

	for _, def in ipairs(pool) do
		local skip = false

		if not use_favs and exclude_map[def.name .. "_" .. def.ability] then skip = true end
		if not skip and def.floor and def.floor > tier then skip = true end
		if not skip and def.roof and def.roof < tier then skip = true end
		if not skip and def.off then skip = true end
		if not skip and def.off_for_universal and is_universal then skip = true end
		if not skip and def.style and def.style ~= hero_capability then skip = true end

		-- ability cards with a cap smaller than the tier can never be offered
		if not skip and def.cap and not def.floor and def.cap < tier then skip = true end

		if not skip and def.unlock_at and def.unlock_at > 0 and now < def.unlock_at then skip = true end

		if not skip and def.cap then
			local rec = (state[def.ability] or {})[def.name]
			local current = rec and (rec.picks or 0) or 0
			if current + tier > def.cap then skip = true end
		end

		if not skip and use_favs and not Augments:IsFav(player_id, def.ability, def.name) then skip = true end

		if not skip then table.insert(result, def) end
	end

	return result
end


--- Draws `amount` distinct cards with weights (picked cards are removed from the pool).
---@param hero CDOTA_BaseNPC used to read current picks for the decay law
function Augments:DrawWeighted(cards, amount, hero)
	local weight_of = function(def)
		local rec = hero and (hero.augment_state[def.ability] or {})[def.name]
		local picks = rec and (rec.picks or 0) or 0
		return math.max(1, WEIGHT_POINTS / (1 + picks))
	end

	local picked = {}
	local remaining = {}
	for i = 1, #cards do remaining[i] = i end

	local take = math.min(amount, #remaining)
	for _ = 1, take do
		local total = 0
		for _, i in ipairs(remaining) do total = total + weight_of(cards[i]) end

		local roll = RandomFloat(0, total)
		local acc = 0
		local chosen_pos = #remaining
		for pos, i in ipairs(remaining) do
			acc = acc + weight_of(cards[i])
			if roll <= acc then
				chosen_pos = pos
				break
			end
		end

		table.insert(picked, cards[remaining[chosen_pos]])
		table.remove(remaining, chosen_pos)
	end

	return picked
end


--- Takes `amount` random entries from a list (partial Fisher-Yates shuffle).
function Augments:TakeRandom(list, amount)
	local n = math.min(amount, #list)
	for i = 1, n do
		local j = RandomInt(i, #list)
		list[i], list[j] = list[j], list[i]
	end

	local out = {}
	for i = 1, n do out[i] = list[i] end
	return out
end


--- Appends extra cards when the filtered pool was too small.
function Augments:FillShortfall(hand, amount, pool, tier, hero)
	if amount <= 0 then return end

	local exclude_map = {}
	for _, card in ipairs(hand) do
		exclude_map[card.name .. "_" .. card.ability] = true
	end

	local extra = Augments:ApplyFilters(pool, tier, hero, exclude_map, false, nil)
	table.extend(hand, Augments:TakeRandom(extra, amount))
end


--- Rolls ability-stat cards for the player.
function Augments:RollAbilityCards(player_id, tier, previous_cards, amount)
	local hero = Augments:GetHero(player_id)
	if not hero then return {} end

	local pool = Augments:LoadHeroPool(hero)

	local exclude_map = {}
	for _, card in ipairs(previous_cards or {}) do
		exclude_map[card.name .. "_" .. card.ability] = true
	end

	local use_favs = Augments:HasFavs(player_id)
	local cards = Augments:ApplyFilters(pool, tier, hero, exclude_map, use_favs, player_id)

	if #cards < amount then
		Augments:FillShortfall(cards, amount - #cards, pool, tier, hero)
	end

	local hand = Augments:DrawWeighted(cards, amount, hero)

	-- reroll fallback: reuse the previous hand when the pool is exhausted
	if #hand < amount and previous_cards then
		table.extend(hand, Augments:TakeRandom(previous_cards, amount - #hand))
	end

	local state = hero.augment_state or {}
	for i, def in ipairs(hand) do
		local copy = table.shallowcopy(def)
		copy.rolled = AugmentMath:RollValue(def.base)
		local rec = (state[def.ability] or {})[def.name]
		copy.picks = rec and (rec.picks or 0) or 0
		copy.delta = AugmentMath:PickDelta(hero, def, copy.rolled, rec, tier, nil, def.ability, def.name)
		hand[i] = copy
	end

	return hand
end


--- Rolls boon cards (catalog) for the player.
function Augments:RollBoonCards(player_id, tier, previous_cards, amount)
	local hero = Augments:GetHero(player_id)
	if not hero then return {} end

	local pool = AugmentCatalog.catalog_list

	local exclude_map = {}
	for _, card in ipairs(previous_cards or {}) do
		exclude_map[card.name .. "_" .. card.ability] = true
	end

	local use_favs = Augments:HasFavs(player_id)
	local cards = Augments:ApplyFilters(pool, tier, hero, exclude_map, use_favs, player_id)

	if #cards < amount then
		Augments:FillShortfall(cards, amount - #cards, pool, tier, hero)
	end

	local hand = Augments:TakeRandom(cards, amount)

	if #hand < amount and previous_cards then
		table.extend(hand, Augments:TakeRandom(previous_cards, amount - #hand))
	end

	local state = hero.augment_state or {}
	local generic_state = state.generic or {}
	for i, def in ipairs(hand) do
		local copy = table.shallowcopy(def)
		local rec = generic_state[def.name]
		copy.picks = rec and (rec.picks or 0) or 0
		copy.rolled_factor = AugmentMath:RollValue(1)
		copy.stats_delta = AugmentMath:BoonDeltas(hero, def, rec, copy.picks, copy.rolled_factor, tier)
		hand[i] = copy
	end

	return hand
end
