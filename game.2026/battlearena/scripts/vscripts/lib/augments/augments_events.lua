Augments = Augments or {}

-- ============================================================================
-- Battle Arena: Augments вЂ” CustomGameEvent handlers
-- ============================================================================

--- "Augments:get_orbs" вЂ” client asks for current orb meters.
function Augments:OnGetOrbs(event)
	local player_id = event.PlayerID
	if not player_id then return end

	Augments:BroadcastOrbs(PlayerResource:GetTeam(player_id))
end


--- "Augments:get_hand" вЂ” client re-opens the current hand.
function Augments:OnGetHand(event)
	local player_id = event.PlayerID
	if not player_id then return end
	if not Augments.hand[player_id] then return end

	local player = PlayerResource:GetPlayer(player_id)
	if not IsValidEntity(player) then return end

	CustomGameEventManager:Send_ServerToPlayer(player, "Augments:show_hand", {
		hand = Augments.hand[player_id],
		queued = Augments:PendingCount(player_id),
	})
end


--- "Augments:pick_card" вЂ” a card was chosen. Payload: { ability, name }
function Augments:OnPick(event)
	local player_id = event.PlayerID
	if not player_id then return end

	local player = PlayerResource:GetPlayer(player_id)
	if not IsValidEntity(player) then return end

	local hand = Augments.hand[player_id]
	if not hand then return end

	local hero = Augments:GetHero(player_id)
	if not hero then return end

	local card = nil
	for _, candidate in ipairs(hand.cards) do
		if candidate.name == event.name and candidate.ability == event.ability then
			card = candidate
			break
		end
	end

	if not card then
		print("[Augments] pick_card: card not in the hand", event.ability, event.name)
		return
	end

	local tier = hand.tier

	if card.kind == AUGMENT_KIND.ABILITY then
		Augments:GrantAbility(player_id, card.ability, card.name, tier, card.rolled)
	else
		Augments:GrantGeneric(player_id, card.name, tier, card.rolled_factor)
	end

	Augments.hand[player_id] = nil
	table.remove(Augments.queue[player_id], 1)

	if #Augments.queue[player_id] > 0 then
		Augments:ShowHand(player_id, hero, Augments.queue[player_id][1].tier, false)
	else
		-- queue drained: tell the client to close the picker
		CustomGameEventManager:Send_ServerToPlayer(player, "Augments:update_queue", { queued = 0 })
	end
end


--- "Augments:reroll_hand" вЂ” spend reroll points and roll a fresh hand.
function Augments:OnReroll(event)
	local player_id = event.PlayerID
	local hero = Augments:GetHero(player_id)
	if not hero then return end

	local hand = Augments.hand[player_id]
	if not hand then return end

	local cost = REROLL_COST[hand.tier]

	if RerollBank:Consume(player_id, cost) then
		Augments:ShowHand(player_id, hero, hand.tier, true)
	end
end


--- "Augments:get_favs" вЂ” client asks for its favorites.
function Augments:OnGetFavs(event)
	local player_id = event.PlayerID
	if not IsValidPlayerID(player_id) then return end
	if not Augments.favs[player_id] then return end

	local player = PlayerResource:GetPlayer(player_id)
	if not IsValidEntity(player) then return end

	CustomGameEventManager:Send_ServerToPlayer(player, "Augments:sync_favs", Augments.favs[player_id])
end


--- "Augments:set_favs" вЂ” client saves favorites. Payload: { favs }
function Augments:OnSetFavs(event)
	if not event.favs then return end

	local player_id = event.PlayerID
	if not player_id or not PlayerResource:IsValidPlayerID(player_id) then return end

	Augments.favs[player_id] = event.favs
end


--- "Augments:dev_grant" вЂ” tools-only cheats. Payload: { pid, ability, name, value }
function Augments:OnDevGrant(event)
	if not IsInToolsMode() then return end

	if event.ability == "generic" then
		Augments:GrantGeneric(event.pid, event.name, event.value or 1)
	else
		Augments:GrantAbility(event.pid, event.ability, event.name, event.value or 1)
	end
end
