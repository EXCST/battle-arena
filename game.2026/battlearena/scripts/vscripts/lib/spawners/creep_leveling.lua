--if not IsServer() then return end

require('lib/dropbox')
require('lib/base_lua_helpers')

require('lib/random/generators')
require('lib/random/weighted_list')
require('lib/connection_helpers')

-- Configurables
local CONFIG_PATH = "scripts/npc/creep_stats.kv"
local RANDOM_GENERATOR_TYPE = "uniform"
local LOOT_RADIUS = 80

CreepLeveling = CreepLeveling or class({})

function CreepLeveling:Init()
	if self.inited then
		return
	end
	
	--print("CreepLeveling init start")

	local RAND_GEN = RandomGeneratorFactory:GetGenerator(RANDOM_GENERATOR_TYPE)

	local kv = LoadKeyValues(CONFIG_PATH)

	local data = kv
	if kv.root then
		data = kv.root
	end

	local base_stats = data.base_stats
	local stats = data.stats

	self.inited = true

	for spawner_type, spawners in pairs(stats) do
		merge_table(spawners, base_stats)
		
		for spawner_level, spawner_info in pairs(spawners) do

			local drops = spawner_info['drops']

			local newDrops = {}

			if drops then
				for key, chance in pairs(drops) do
					chance = tonumber(chance)
					local box = DropBox:GetDropbox(key)

					if box then
						table.insert(newDrops, { chance, box } )
					else
						print("[CreepLeveling] Failed to get dropbox", key, "for creep spawner", spawner_type, "for creep levels", spawner_level)
					end
				end
			end

			spawner_info['drops'] = WeightedList:Create(newDrops, RAND_GEN)

			spawner_info.hp 	  		= tonumber( spawner_info.hp or "100" )
			spawner_info.mp 	  		= tonumber( spawner_info.mp or "100" )
			spawner_info.bat 	  		= tonumber( spawner_info.bat or "1.7" )
			spawner_info.armor 	  		= tonumber( spawner_info.armor or "0" )
			spawner_info.dmg_min  		= tonumber( spawner_info.dmg_min or "0" )
			spawner_info.dmg_max  		= tonumber( spawner_info.dmg_max or "0" )

			spawner_info.exp 	  		= tonumber( spawner_info.exp or "0" )
			spawner_info.gold_min 		= tonumber( spawner_info.gold_min or "0" )
			spawner_info.gold_max 		= tonumber( spawner_info.gold_max or "0" )
			spawner_info.model_scale 	= tonumber( spawner_info.model_scale or "1.0" )
		end 
	end

	self.stats = stats
end 

function CreepLeveling:OnSpawnCallback( event )
	local creep 		= event.creep
	local spawner_info 	= event.spawner_info
	local spawner_type 	= spawner_info.spawner_type

	local seek_spawn_info = nil
	local seek_creep_level = -10000

	local level = self:_calculateHeroesAverageLevel()

	local total_creep_level
	if self.stats[spawner_type] == nil then
	    print("[CreepLeveling] Unknown spawner type:", spawner_type)
	    return
	end
	for creep_level, info in pairs(self.stats[spawner_type]) do
		local newSpawnLevel = tonumber(info["hero_avg_level"])
		if newSpawnLevel <= level and newSpawnLevel > seek_creep_level then
			seek_spawn_info  = info
			seek_creep_level = newSpawnLevel
			total_creep_level  = creep_level
		end
	end

	if not seek_spawn_info then
		local lowest_level = nil
		local lowest_key = -10000
		for creep_level, info in pairs(self.stats[spawner_type]) do
			local newSpawnLevel = tonumber(info["hero_avg_level"])
			if not lowest_level or newSpawnLevel < lowest_key then
				lowest_level = info
				lowest_key = newSpawnLevel
				total_creep_level = creep_level
			end
		end
		seek_spawn_info = lowest_level
	end

	if not seek_spawn_info then
		print("[CreepLeveling] No spawn information to this level, level = " .. tostring( level ))
		return
	end 

	creep._leveling_drop = seek_spawn_info['drops']

	creep:SetDeathXP( seek_spawn_info.exp )
	creep:SetMinimumGoldBounty( seek_spawn_info.gold_min )
	creep:SetMaximumGoldBounty( seek_spawn_info.gold_max )

	creep:SetBaseMaxHealth( seek_spawn_info.hp )
	creep:SetMaxHealth( seek_spawn_info.hp )
	creep:SetMaxMana( seek_spawn_info.mp )

	creep:SetPhysicalArmorBaseValue( seek_spawn_info.armor )
	creep:SetBaseAttackTime( seek_spawn_info.bat )
	creep:SetBaseDamageMin( seek_spawn_info.dmg_min )
	creep:SetBaseDamageMax( seek_spawn_info.dmg_max )

	creep:SetMana( creep:GetMaxMana() )
	creep:SetHealth( creep:GetMaxHealth() )
	
	creep:SetModelScale( seek_spawn_info.model_scale )

	-- AUGMENTS: orb weight by spawner tier (normal=1, beast=2, ancient=3)
	if spawner_type == "ancient" then
		creep.orb_value = 3
	elseif spawner_type == "beast" then
		creep.orb_value = 2
	else
		creep.orb_value = 1
	end
end

function CreepLeveling:OnDeathCallback( event )
	local creep = event.creep

	local dropList = creep._leveling_drop

	creep._leveling_drop = nil

	if not dropList then return end

	local dropbox = dropList:Get()

	dropbox:DropAtPos(creep:GetAbsOrigin(), LOOT_RADIUS)
end

function CreepLeveling:_calculateHeroesAverageLevel()
	local summ_level = 0
	local connected_count = 0
	local heroes = PlayerResource:GetAllHeroes()
	--print("Heroes...", heroes)

	for _, x in pairs(heroes) do
		if x and IsConnected(x) and IsValidEntity(x) and x:IsRealHero() then
			summ_level = summ_level + x:GetLevel()
			connected_count = connected_count + 1
		end
	end

	if connected_count == 0 then return 0 end
	return summ_level/connected_count
end 

CreepLeveling:Init()