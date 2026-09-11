BossSpawner = BossSpawner or class({})

LinkLuaModifier("modifier_boss", 'lib/spawners/modifier_boss', LUA_MODIFIER_MOTION_NONE)
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
	self.death_count = {}
	self.is_alive = {}
	self.repick_zones = {}
    local raw = LoadKeyValues(CONFIG_PATH)
    self.spawn_names = raw
    if raw.boss_spawners then
        self.spawn_names = raw.boss_spawners
    end

	for spawn_name, _ in pairs(self.spawn_names) do
	    self.last_death_times[spawn_name] = -300
	    self.death_count[spawn_name] = 0
	    self.is_alive[spawn_name] = false
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
	if not boss then
		print("BossSpawner: failed to create boss", boss_name, "on", spawn_name)
		return
	end
	boss.IsAngelArenaBoss = true
	FindClearSpaceForUnit(boss, boss:GetOrigin(), true)
	boss:SetForwardVector(spawner_dir)
	boss:Stop()
	
	self.is_alive[spawn_name] = true
	self:_RemoveRepickZone(spawn_name)

	LinkLuaModifier("modifier_boss", 'lib/spawners/modifier_boss', LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_boss_power", 'lib/spawners/modifier_boss_power', LUA_MODIFIER_MOTION_NONE)
	boss:AddNewModifier(boss, nil, "modifier_boss", { duration = -1 })
	boss:AddNewModifier(boss, nil, "modifier_boss_power", { duration = -1 })
	for i = 0, 15 do
		local ab = boss:GetAbilityByIndex(i)
		if ab and ab:GetLevel() == 0 then ab:SetLevel(1) end
	end
	boss.spawn_name = spawn_name
    boss.boss_name = boss_name
end

function BossSpawner:_OnDeath( boss )
    print("ON boss death ", boss.spawn_name)
	local spawn_name = boss.spawn_name
	local boss_name = boss.boss_name

	if not self.is_alive[spawn_name] then
		return
	end

	self.is_alive[spawn_name] = false
	self.death_count[spawn_name] = self.death_count[spawn_name] + 1

	if spawn_name == "target_mark_boss_omniknight" then
		self:_CreateRepickZone(boss)
	end
	
	Timers:CreateTimer(BOSS_SPAWN_TIME, function()
		BossSpawner:_SpawnBoss(spawn_name, boss_name)
	end)
end

local REPICK_ZONE_RADIUS = 300
local REPICK_ZONE_DURATION = 20

function BossSpawner:_CreateRepickZone(boss)
	local spawn_name = boss.spawn_name

	if self.repick_zones[spawn_name] then
		self:_RemoveRepickZone(spawn_name)
	end

	self.repick_used = false
	self.repick_claimer = nil

	local pos = boss:GetAbsOrigin()
	self.repick_pos = pos

	local particle = ParticleManager:CreateParticle("particles/repick_zone/doom_bringer_doom_aura.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, pos)
	ParticleManager:SetParticleControl(particle, 1, Vector(120, 0, 0))

	self.repick_zones[spawn_name] = {
		particle 	= particle,
		created_at 	= GameRules:GetGameTime(),
		timer 		= nil,
	}

	self.repick_zones[spawn_name].timer = Timers:CreateTimer(function()
		if not self.repick_zones[spawn_name] then
			return nil
		end

		if self.repick_used then
			if self.repick_claimer then
				RepickMenu:Close(self.repick_claimer.player)
			end
			self:_RemoveRepickZone(spawn_name)
			return nil
		end

		local elapsed = GameRules:GetGameTime() - self.repick_zones[spawn_name].created_at
		if elapsed > REPICK_ZONE_DURATION then
			if self.repick_claimer then
				RepickMenu:Close(self.repick_claimer.player)
			end
			self:_RemoveRepickZone(spawn_name)
			return nil
		end

		if self.repick_claimer then
			local hero = self.repick_claimer.hero
			if hero and hero:IsAlive() and not hero:IsNull() then
				local dist = (hero:GetAbsOrigin() - pos):Length2D()
				if dist > REPICK_ZONE_RADIUS then
					RepickMenu:Close(self.repick_claimer.player)
					self.repick_claimer = nil
				end
			end
			return 1.0
		end

		local heroes = HeroList:GetAllHeroes()
		for _, hero in pairs(heroes) do
			if IsServer() and hero and hero:IsAlive() and not hero:IsNull() then
				local player = hero:GetPlayerOwner()
				if player then
					local dist = (hero:GetAbsOrigin() - pos):Length2D()
					if dist <= REPICK_ZONE_RADIUS then
						self.repick_claimer = { hero = hero, player = player }
						RepickMenu:Open(player)
						return 1.0
					end
				end
			end
		end

		return 1.0
	end)
end

function BossSpawner:_RemoveRepickZone(spawn_name)
	if not self.repick_zones[spawn_name] then return end

	local zone = self.repick_zones[spawn_name]

	if zone.timer then
		Timers:RemoveTimer(zone.timer)
	end

	if zone.particle then
		ParticleManager:DestroyParticle(zone.particle, false)
	end

	self.repick_zones[spawn_name] = nil
	self.repick_pos = nil
	self.repick_claimer = nil
end



