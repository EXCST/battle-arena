-- ============================================================================
-- Battle Arena: Augments — champion creeps
-- Elite creeps that grant an instant team augment on kill.
-- ============================================================================

require("lib/augments/champions/modifier_ba_champion")

Champions = Champions or {}

CHAMPION_SPAWN_DELAY = { 180, 300 } -- seconds between champion waves (random min-max)
CHAMPION_EPIC_START_TIME = 20 * 60 -- champions may spawn as epic after this time
CHAMPION_EPIC_CHANCE = 50 -- %

CHAMPION_TIER_EARLY_TIME = 14 * 60

CHAMPION_TIER_WEIGHT_EARLY = {
	[AUGMENT_TIER.RARE] = { [1] = 1000, [2] = 5, [3] = 0 },
	[AUGMENT_TIER.EPIC] = { [1] = 50, [2] = 30, [3] = 0 },
}

CHAMPION_TIER_WEIGHT = {
	[AUGMENT_TIER.RARE] = { [1] = 40, [2] = 40, [3] = 20 },
	[AUGMENT_TIER.EPIC] = { [1] = 10, [2] = 20, [3] = 60 },
}

-- hp / damage multipliers applied on top of the regular creep stats
CHAMPION_STATS_BONUS = {
	[AUGMENT_TIER.RARE] = { hp = 1.6, damage = 1.5 },
	[AUGMENT_TIER.EPIC] = { hp = 2.2, damage = 2.0 },
}

TIER_BY_TYPE = {
	normal = 1,
	beast = 2,
	ancient = 3,
}


--- Picks one key by weights (own implementation, no shared RNG).
local function WeightedPick(weights)
	local total = 0
	for _, weight in pairs(weights) do total = total + weight end

	local roll = RandomInt(1, math.max(total, 1))
	for key, weight in pairs(weights) do
		roll = roll - weight
		if roll <= 0 then return key end
	end

	return 1
end


function Champions:Init()
	Champions.spawners = { -- team -> tier -> { {name, pos, unit_name} }
		[DOTA_TEAM_GOODGUYS] = { [1] = {}, [2] = {}, [3] = {} },
		[DOTA_TEAM_BADGUYS] = { [1] = {}, [2] = {}, [3] = {} },
	}

	local config = LoadKeyValues("scripts/npc/creep_spawners.kv")
	if config and config.root then
		config = config.root
	end

	for spawner_name, spawner_config in pairs(config or {}) do
		if type(spawner_config) == "table" then
			local tier = TIER_BY_TYPE[spawner_config.type]
			if tier then
				local team = string.ends(spawner_name, "_radiant") and DOTA_TEAM_GOODGUYS
					or (string.ends(spawner_name, "_dire") and DOTA_TEAM_BADGUYS)
					or nil

				if team then
					local unit_name = nil
					for _, creep_name in pairs(spawner_config.creeps or {}) do
						unit_name = creep_name
						break
					end

					local target = Entities:FindByName(nil, spawner_name)
					if target and unit_name then
						table.insert(Champions.spawners[team][tier], {
							name = spawner_name,
							pos = target:GetAbsOrigin(),
							unit_name = unit_name,
						})
					end
				end
			end
		end
	end
end


function Champions:Start()
	Timers:CreateTimer(Champions:GetDelay(), function()
		Champions:SpawnChampions()
		return Champions:GetDelay()
	end)
end


function Champions:GetDelay()
	return RandomInt(CHAMPION_SPAWN_DELAY[1], CHAMPION_SPAWN_DELAY[2])
end


function Champions:GetCreepLevel()
	local level = 0
	local count = 0

	for player_id = 0, DOTA_MAX_PLAYERS do
		if PlayerResource:IsValidPlayerID(player_id) then
			local hero = PlayerResource:GetSelectedHeroEntity(player_id)
			if IsValidEntity(hero) and hero:IsRealHero() then
				level = level + hero:GetLevel()
				count = count + 1
			end
		end
	end

	if count > 0 then return math.max(math.ceil(level / count), 1) end
	return 1
end


function Champions:SpawnChampions()
	local champion_kind = AUGMENT_TIER.RARE

	local game_time = GameRules:GetGameTime()
	local is_epic_start_time = game_time >= CHAMPION_EPIC_START_TIME
	local epic_chance_rolled = RollPercentage(CHAMPION_EPIC_CHANCE)

	if is_epic_start_time and epic_chance_rolled then
		champion_kind = AUGMENT_TIER.EPIC
	end

	local weight_source = CHAMPION_TIER_WEIGHT
	if game_time <= CHAMPION_TIER_EARLY_TIME then weight_source = CHAMPION_TIER_WEIGHT_EARLY end

	local tier = WeightedPick(weight_source[champion_kind])

	for team, tiers in pairs(Champions.spawners) do
		local spawners = tiers[tier]
		if #spawners > 0 then
			local spawner = table.random(spawners)
			Champions:SpawnChampion(team, spawner, champion_kind, tier)
		end
	end

	CustomGameEventManager:Send_ServerToAllClients("notifications:add", {
		token = "notification_champion_" .. champion_kind,
		style = { fontSize = "40px" },
	})
end


function Champions:SpawnChampion(team, spawner, champion_kind, tier)
	local unit_name = spawner.unit_name .. "_champion"

	local creep = CreateUnitByName(unit_name, spawner.pos + RandomVector(75), true, nil, nil, DOTA_TEAM_NEUTRALS)
	if not creep then
		print("[Champions] FAILED to create unit", unit_name, "at spawner", spawner.name)
		return
	end

	creep.champion_kind = champion_kind

	-- apply regular creep stats scaled to the average hero level
	if CreepLeveling and CreepLeveling.OnSpawnCallback then
		CreepLeveling:OnSpawnCallback({
			creep = creep,
			spawner_info = { spawner_type = tier == 1 and "normal" or (tier == 2 and "beast" or "ancient") },
		})
	end

	-- champion bonus
	local bonus = CHAMPION_STATS_BONUS[champion_kind]
	local max_hp = creep:GetMaxHealth() * bonus.hp
	creep:SetBaseMaxHealth(max_hp)
	creep:SetMaxHealth(max_hp)
	creep:SetHealth(max_hp)

	-- champions keep the KV model scale (1.5) instead of the regular creep scale
	creep:SetModelScale(1.5)

	-- champions do not drop regular creep loot
	creep._leveling_drop = nil

	local dmg_min = creep:GetBaseDamageMin() * bonus.damage
	local dmg_max = creep:GetBaseDamageMax() * bonus.damage
	creep:SetBaseDamageMin(dmg_min)
	creep:SetBaseDamageMax(dmg_max)

	creep:AddNewModifier(creep, nil, "modifier_ba_champion", { kind = champion_kind })

	local ability = champion_kind == AUGMENT_TIER.EPIC and "ability_ba_champion_epic" or "ability_ba_champion_rare"
	creep:AddAbility(ability)

	local icon = champion_kind == AUGMENT_TIER.EPIC and "npc_ba_minimap_champion_epic" or "npc_ba_minimap_champion_rare"
	local dummy = CreateUnitByName(icon, creep:GetOrigin(), false, nil, nil, DOTA_TEAM_NEUTRALS)
	if dummy then
		dummy:FollowEntity(creep, false)
		creep.minimap_entity = dummy
	end

	local origin = creep:GetOrigin()
	for ping_team = DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS do
		GameRules:ExecuteTeamPing(ping_team, origin.x, origin.y, nil, 2)
	end
end
