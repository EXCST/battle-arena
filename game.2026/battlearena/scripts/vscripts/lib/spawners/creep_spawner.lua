CreepSpawner = CreepSpawner or class({})

LinkLuaModifier("modifier_dominate_protection", 'lib/spawners/modifier_dominate_protection', LUA_MODIFIER_MOTION_NONE)

require("lib/timers")

local DEBUG = IsInToolsMode()
local FORCE_DEBUG = false
local CONFIG_PATH = "scripts/npc/creep_spawners.kv"

local CREEP_SPAWN_TIME = 60
local CREEP_RANDOM_OFFSET = 50

if DEBUG then
    CREEP_SPAWN_TIME = 60
end

local SPAWN_DELAY_PER_UNIT = 0.005
local SPAWN_DELAY_LIMIT = 0.25

-- Добавленная переменная
local totalCreepCount = 0

-------------------------------------------- PUBLIC -----------------------------------------------------------------

function emptyFunc(...)
end

function CreepSpawner:Init()
    self.onSpawnCallbacks = {}
    self.onDeathCallbacks = {}

    self.spawnTime = CREEP_SPAWN_TIME
    self.spawnEnabled = true

    self.spawners, self.creepCount = self:_parseSpawners(CONFIG_PATH)

    if DEBUG then
        self.preacachedCount = 0
    end

    self._spawnerCounts = self._spawnerCounts or {}

    self:StopSpawning()

    for spawner_info, creeps in pairs(self.spawners) do
        for _, creepname in pairs(creeps) do
            if DEBUG then
                PrecacheUnitByNameAsync(creepname, function(...)
                    self.preacachedCount = self.preacachedCount + 1
                    if FORCE_DEBUG then
                        print("Precached unit ", creepname, tostring(self.preacachedCount) .. "/" .. tostring(self.creepCount))
                    end
                end)
            else
                PrecacheUnitByNameAsync(creepname, emptyFunc)
            end
        end

        self._spawnerCounts[spawner_info.name] = self._spawnerCounts[spawner_info.name] or {}
    end
end

function CreepSpawner:StartSpawning()
    print("[DEBUG] CreepSpawner:StartSpawning called, spawners count:", self.creepCount)
    self:SpawnCreeps()

    Timers:CreateTimer("CreepSpawner", {
        useGameTime = true,
        endTime = self.spawnTime,
        callback = function()
            self:SpawnCreeps()
            return self.spawnTime
        end
    })
end

function CreepSpawner:StopSpawning()
    Timers:RemoveTimer("CreepSpawner")
end

function CreepSpawner:SpawnCreeps()
    local spawnDelay = 0.0
    print("[DEBUG] SpawnCreeps called, spawners:", self.spawners and "exists" or "NIL")

    self:_CreateEasyStacks()

    local spawnerCount = 0
    for spawner_info, creep_names in pairs(self.spawners) do
        spawnerCount = spawnerCount + 1
        local spawner_name = spawner_info.name

        local base_spawner_pos = spawner_info.pos
        local spawner_dir = spawner_info.direction

        for _, creep_name in pairs(creep_names) do
            local offset = RandomVector(CREEP_RANDOM_OFFSET)
            local spawner_pos = base_spawner_pos + offset

            spawnDelay = spawnDelay + SPAWN_DELAY_PER_UNIT

            if spawnDelay > SPAWN_DELAY_LIMIT then
                spawnDelay = SPAWN_DELAY_LIMIT
            end

            Timers:CreateTimer(spawnDelay, function()
                if totalCreepCount >= 500 then
                    print("Достигнуто максимальное количество крипов. Спаун прекращен.")
                    return
                end

                local creep = CreateUnitByName(creep_name, spawner_pos, true, nil, nil, DOTA_TEAM_NEUTRALS)

                if not creep then
                    print("Error handled, no unit with name", creep_name, " exists. Trying to spawn it on spawner ", spawner_name)
                    return nil
                end

                creep:SetForwardVector(spawner_dir)
                creep:Stop()

                self:_CreateCreep(creep, spawner_info)
            end)
        end
    end
end

function CreepSpawner:RegisterOnSpawnCallback(func) table.insert(self.onSpawnCallbacks, func); end
function CreepSpawner:UnregisterOnSpawnCallback(func) table.remove(self.onSpawnCallbacks, func); end

function CreepSpawner:RegisterOnDeathCallback(func) table.insert(self.onDeathCallbacks, func); end
function CreepSpawner:UnregisterOnDeathCallback(func) table.remove(self.onDeathCallbacks, func); end

-------------------------------------------- PRIVATE -----------------------------------------------------------------

function CreepSpawner:_parseSpawners(sSettingsFile)
    print("[DEBUG] Loading spawners from", sSettingsFile)
    local temp = LoadKeyValues(sSettingsFile)
    if not temp then
        print("[DEBUG] CRITICAL: LoadKeyValues returned nil for", sSettingsFile)
        return {}, 0
    end

    local ret = {}

    local creepCount = 0

    local spawners = temp
    if temp.root then
        spawners = temp.root
        print("[DEBUG] Found 'root' key, unwrapped")
    else
        print("[DEBUG] No 'root' key, using top-level")
    end

    local count = 0
    for spawner_name, spawner_table in pairs(spawners) do
        count = count + 1
        local entity = Entities:FindByName(nil, spawner_name)

        if not entity then
            print("Failed to parse point, there is not point on map, point =", spawner_name)
        else
            local spawner_info = {
                name = spawner_name,
                pos = entity:GetAbsOrigin(),
                direction = entity:GetForwardVector(),
                spawner_type = spawner_table["type"]
            }

            local creeps = spawner_table["creeps"]

            ret[spawner_info] = creeps

            for _, _ in pairs(creeps) do
                creepCount = creepCount + 1
            end
        end
    end

    print("[DEBUG] _parseSpawners: found", count, "entries in KV,", creepCount, "total creeps,", #ret, "valid spawners")
    return ret, creepCount
end

function CreepSpawner:_notifyCallbackList(callback_list, arg_kv)
    for _, callback in pairs(callback_list) do
        xpcall(function()
            callback(arg_kv)
        end,
                function(msg)
                    local m = type(msg) == "string" and msg or tostring(msg)
                    print("Error notify callback in CreepSpawner:_notifyCallbacks + " .. m)
                end)
    end
end

function CreepSpawner:_FreeCreep(unit)
    unit.spawner_info = nil
end

function CreepSpawner:_CreateCreep(unit, spawner_info)
    LinkLuaModifier("modifier_dominate_protection", 'lib/spawners/modifier_dominate_protection', LUA_MODIFIER_MOTION_NONE)
    unit:AddNewModifier(unit, nil, "modifier_dominate_protection", { duration = -1 })

    unit.spawner_info = spawner_info

    self:_notifyCallbackList(self.onSpawnCallbacks, { creep = unit, spawner_info = spawner_info })

    -- Добавлена проверка на максимальное количество крипов
    totalCreepCount = totalCreepCount + 1
    if totalCreepCount >= 500 then
        print("Достигнуто максимальное количество крипов. Спаун прекращен.")
        return
    end
end

function CreepSpawner:_OnDominated(unit)
    self:_FreeCreep(unit)
end

function CreepSpawner:_OnDied(unit)
	local spawner_info = unit.spawner_info
	unit.spawner_info = nil
	self:_notifyCallbackList(self.onDeathCallbacks, { creep = unit, spawner_info = spawner_info })

	-- only decrement for spawner-registered creeps (champions are created directly)
	if spawner_info then
		totalCreepCount = math.max(totalCreepCount - 1, 0)
	end
end

function CreepSpawner:_CreateEasyStacks()
    local entity_radiant = Entities:FindByName(nil, "target_mark_spawner_mid_1_radiant")
    local entity_dire = Entities:FindByName(nil, "target_mark_spawner_mid_1_dire")
    if not entity_radiant or not entity_dire then return end
    local point_radiant = entity_radiant:GetAbsOrigin()
    local point_dire = entity_dire:GetAbsOrigin()

    local creeps_to_spawn = 3
    local cu
    for i = 1, creeps_to_spawn do
        if totalCreepCount >= 500 then
            print("Достигнуто максимальное количество крипов. Спаун в функции _CreateEasyStacks прекращен.")
            return
        end

        cu = RandomInt(1, 11)
        local unitname
        if cu == 1 then unitname = "npc_dota_neutral_kobold" end;
        if cu == 2 then unitname = "npc_dota_neutral_harpy_scout" end;
        if cu == 3 then unitname = "npc_dota_neutral_ghost" end;
        if cu == 4 then unitname = "npc_dota_neutral_gnoll_assassin" end;
        if cu == 5 then unitname = "npc_dota_neutral_harpy_storm" end;
        if cu == 6 then unitname = "npc_dota_neutral_alpha_wolf" end;
        if cu == 7 then unitname = "npc_dota_neutral_forest_troll_berserker" end;
        if cu == 8 then unitname = "npc_dota_neutral_gnoll_assassin" end;
        if cu == 9 then unitname = "npc_dota_neutral_kobold_taskmaster" end;
        if cu == 10 then unitname = "npc_dota_neutral_satyr_soulstealer" end;
        if cu == 11 then unitname = "npc_dota_neutral_satyr_trickster" end;

        CreateUnitByName(unitname, point_radiant, true, nil, nil, DOTA_TEAM_NEUTRALS)
        CreateUnitByName(unitname, point_dire, true, nil, nil, DOTA_TEAM_NEUTRALS)

        -- Увеличиваем счетчик общего количества крипов
        totalCreepCount = totalCreepCount + 2
    end
end
