require('lib/ability_kv')

Runes = Runes or {}

function Runes:ModifierRuneSpawn(keys)
    self.round = self.round + 1
	local runes = { DOTA_RUNE_DOUBLEDAMAGE,
					DOTA_RUNE_HASTE,
					DOTA_RUNE_ILLUSION,
					DOTA_RUNE_INVISIBILITY,
					DOTA_RUNE_REGENERATION,
					DOTA_RUNE_ARCANE }
	
	if (self.round % 2 == 0 and self.bountyWasSetUp == true) 
	or (self.round % 2 == 1 and RandomInt(1, 2) == 2) then
		keys.rune_type = runes[RandomInt(1, #runes)]
		self.bountyWasSetUp = false
	else
		keys.rune_type = DOTA_RUNE_BOUNTY
		self.bountyWasSetUp = true
	end
	return true
end

function Runes:OnRuneActivate(event)
    print("On Rune Activate start")
	local runeid = event.rune
	local playerid = event.PlayerID
	local hero = PlayerResource:GetPlayer(playerid):GetAssignedHero()

	if not hero then return end
	
	local item
	-- https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Scripting/API
	for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
		item = hero:GetItemInSlot(i)
		if item and item:GetPurchaser() == hero then
			if item and (item:GetName() == "item_power_amulet" or item:GetName() == "item_mystic_amulet" or item:GetName() == "item_strange_amulet" )then
				item:SetCurrentCharges(item:GetCurrentCharges() + 1)
				return
			end
		end
	end

	if runeid == DOTA_RUNE_XP then
		-- AUGMENTS: wisdom/xp rune grants a rare augment to the whole team
		local team = hero:GetTeamNumber()
		if Augments and Augments.QueueForTeam then
			Augments:QueueForTeam(team, AUGMENT_TIER.RARE)
		end
		return
	end

	if runeid == DOTA_RUNE_BOUNTY then
		local cur_min = GameRules:GetGameTime() / 60

		local item_mod_table = {
			{ "item_hand_of_midas",  200 + 15 * cur_min },
			{ "item_advanced_midas", 600 + 30 * cur_min }
		}

		local hero_mod_table = {
			["npc_dota_hero_alchemist"] = 2,
		}
	
		local gold_without_mods = 100 + 20 * cur_min

		-- arthas (Plus Morality): бонти-руна даёт +1 стак баффа (как в BS —
		-- modules/custom_runes/data.lua) подобравшему герою
		local arthas_ability = hero:FindAbilityByName("arthas_plus_morality")
		if arthas_ability and arthas_ability:GetLevel() > 0 then
			ModifyStacks(arthas_ability, hero, hero, "modifier_arthas_plus_morality_buff", 1, false)
		end

		function CalcBountyGold( hero )
			local hero_mult = hero_mod_table[ hero:GetUnitName() ] or 1

			-- arthas: множитель золота из KV способности (bounty_multiplier 2.5)
			local arthas_ability = hero:FindAbilityByName("arthas_plus_morality")
			if arthas_ability and arthas_ability:GetLevel() > 0 then
				local m = AbilityKV:Get(arthas_ability, "bounty_multiplier")
				if m and m > 0 then hero_mult = hero_mult * m end
			end

			local item_gold = 0
			for _, data in pairs(item_mod_table) do
				local item = data[1]
				local gold = data[2]

				if hero:HasItemInInventory(item) and gold > item_gold then
					item_gold = gold
				end
			end

			return hero_mult * ( gold_without_mods + item_gold )
		end

		local team = hero:GetTeamNumber()

		TeamHelper:ApplyForHeroes(team, function(playerid, unit)
			unit:ModifyGold(CalcBountyGold( unit ), false, 0)
		end)
	end
	
	if runeid == DOTA_RUNE_ILLUSION then
		hero:AddNewModifier(hero, nil, "modifier_rune_illusion_one", { duration = 30 }) -- 30%dmg, +20mvspd
		hero:AddNewModifier(hero, nil, "modifier_rune_illusion_two", { duration = 30 }) --+15dmg resist
	end
	
	print("On Rune Activate end")
end

function Runes:Init()
    self.round = 0
	self.bountyWasSetUp = false
end

Runes:Init()