Augments = Augments or {}

-- ============================================================================
-- Battle Arena: Augments вЂ” hero definition pools
-- ============================================================================

--- Loads and normalizes the KV file of a hero, then shares it with clients.
function Augments:LoadHeroDefs(hero_name)
	Augments.hero_defs[hero_name] = LoadKeyValues("scripts/augments/heroes/" .. hero_name .. ".txt") or {}

	for ability_name, ability_records in pairs(Augments.hero_defs[hero_name]) do
		for stat_name, record in pairs(ability_records) do
			AugmentMath:Normalize(record, stat_name, AUGMENT_KIND.ABILITY, ability_name)
		end
	end

	CustomNetTables:SetTableValue("augment_store", hero_name, Augments.hero_defs[hero_name])
	return Augments.hero_defs[hero_name]
end


--- Returns a flat list of all ability-stat records of the hero (cached).
--- Records of abilities the hero doesn't actually have are skipped (dead cards).
function Augments:LoadHeroPool(hero)
	local hero_name = hero:GetUnitName()
	hero.augment_state = hero.augment_state or {}

	if Augments.hero_pools[hero_name] then return Augments.hero_pools[hero_name] end
	if not Augments.hero_defs[hero_name] then Augments:LoadHeroDefs(hero_name) end

	local pool = {}
	local filtered_defs = {}

	for ability_name, ability_records in pairs(Augments.hero_defs[hero_name] or {}) do
		if hero:FindAbilityByName(ability_name) then
			filtered_defs[ability_name] = ability_records
			for _, record in pairs(ability_records) do
				table.insert(pool, record)
			end
		end
	end

	Augments.hero_pools[hero_name] = pool

	-- share only the abilities the hero actually has with the client
	CustomNetTables:SetTableValue("augment_store", hero_name, filtered_defs)

	return pool
end
