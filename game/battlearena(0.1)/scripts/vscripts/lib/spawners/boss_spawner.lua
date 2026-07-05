BossSpawner = BossSpawner or class({})

LinkLuaModifier("BossModifier", 'lib/spawners/modifier_boss', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_power", 'lib/spawners/modifier_boss_power', LUA_MODIFIER_MOTION_NONE)

require("lib/timers")

local CONFIG_PATH = "scripts/npc/boss_spawners.kv"
local DEBUG = IsInToolsMode() 
local BOSS_SPAWN_TIME 	= 300
if DEBUG then
	BOSS_SPAWN_TIME = 300
end

function BossSpawner:Init()
	self.last_death_times = {}
    local raw = LoadKeyValues(CONFIG_PATH)
    self.spawn_names = raw
    if raw.boss_spawners then
        self.spawn_names = raw.boss_spawners
    end

	for spawn_name, _ in pairs(self.spawn_names) do
	    self.last_death_times[spawn_name] = -300
	end
end

function BossSpawner:IsBoss(unit)
	if not unit then return nil end
	
	return unit.IsAngelArenaBoss
end


function BossSpawner:StartSpawning()
    print("BossSpawner StartSpawning, spawn_names count:", 0)
    local cnt = 0
    for _ in pairs(self.spawn_names) do cnt = cnt + 1 end
    print("BossSpawner StartSpawning, spawn_names count:", cnt)
	self:_SpawnBosses()
end

function BossSpawner:_SpawnBosses()
	for spawn_name, info in pairs(self.spawn_names) do
	    print("Spawn name::: ", spawn_name, " type ",  info.type, GameRules:GetGameTime())
		print("Last death time:::", self.last_death_times[spawn_name])
		BossSpawner:_SpawnBoss(spawn_name, info.type)
	end
end

function BossSpawner:_SpawnBoss(spawn_name, boss_name)
    local entity = Entities:FindByName( nil, spawn_name )
    if not entity then
        print("BossSpawner: entity not found for", spawn_name)
        return
    end
	local spawner_pos  = entity:GetAbsOrigin()
	local spawner_dir  = entity:GetForwardVector()
	
	local boss = CreateUnitByName(boss_name, spawner_pos, true, nil, nil, DOTA_TEAM_NEUTRALS)
	boss.IsAngelArenaBoss = true
	FindClearSpaceForUnit(boss, boss:GetOrigin(), true)
	boss:SetForwardVector(spawner_dir)
	boss:Stop()
	
	boss:AddNewModifier(boss, nil, "BossModifier", { duration = -1 })
	boss:AddNewModifier(boss, nil, "modifier_boss_power", { duration = -1 })
	boss.spawn_name = spawn_name
    boss.boss_name = boss_name
end

function BossSpawner:_OnDeath( boss )
    print("ON boss death ", boss.spawn_name)
	local spawn_name = boss.spawn_name
	local boss_name = boss.boss_name
	
	Timers:CreateTimer(BOSS_SPAWN_TIME, function()
		BossSpawner:_SpawnBoss(spawn_name, boss_name)
	end)
end



