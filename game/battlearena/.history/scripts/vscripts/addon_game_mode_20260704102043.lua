print("[BATTLEARENA] addon_game_mode.lua loaded!")

if AngelArena == nil then
	AngelArena = class({})
end

require("util/init")
require('lib/damage_to_exp_global')
require('lib/comeback_system')
require('lib/spawners/boss_spawner')
require('lib/spawners/creep_spawner')
require('lib/spawners/creep_leveling')
require('lib/duel/duel_controller')
require('lib/move_limiter')
require('lib/runes/runes')
require('lib/utils')
require('listeners/on_entity_killed')
require('listeners/on_npc_spawned')

require('filters/neutral_slot_filter')
require('filters/gold')

local heroCfgOK, heroCfgErr = pcall(require, 'lib/hero_selection_config')
if not heroCfgOK then
    print("[BATTLEARENA] Failed to load hero_selection_config: " .. tostring(heroCfgErr))
else
    print("[BATTLEARENA] hero_selection_config loaded successfully")
end

local heroSelOK, heroSelErr = pcall(require, 'lib/hero_selection')
if not heroSelOK then
    print("[BATTLEARENA] Failed to load hero_selection: " .. tostring(heroSelErr))
else
    print("[BATTLEARENA] hero_selection loaded successfully")
end


-- Список модулей которые нужно загружать в InitGameMode, а не при создании VM'ки 
local postRequireList = {
	'lib/base/player'
}

local Constants = require('consts') -- XP TABLE

function CEntityInstance:SetNetworkableEntityInfo(key, value)
    local t = CustomNetTables:GetTableValue("custom_entity_values", tostring(self:GetEntityIndex())) or {}
    t[key] = value
    CustomNetTables:SetTableValue("custom_entity_values", tostring(self:GetEntityIndex()), t)
end
function Precache( context )
	PrecacheResource("model", "models/heroes/enchantress/enchantress.vmdl", context)
	PrecacheResource("model", "models/heroes/omniknight/omniknight.vmdl", context)
	PrecacheResource("model", "models/heroes/doom/doom.vmdl", context)
	PrecacheResource("model", "models/heroes/beastmaster/beastmaster.vmdl", context)
	PrecacheResource("model", "models/heroes/dark_seer/dark_seer.vmdl", context)
	PrecacheResource("model", "models/items/terrorblade/endless_purgatory_demon/endless_purgatory_demon.vmdl", context)
	PrecacheResource("model", "models/items/terrorblade/marauders_demon/marauders_demon.vmdl", context)
	PrecacheUnitByNameAsync("npc_aac_creep_golem_radiant", emptyFunc)
	PrecacheUnitByNameAsync("npc_aac_creep_centaur_radiant", emptyFunc)
	PrecacheUnitByNameAsync("npc_aac_creep_dragon_radiant", emptyFunc)
	PrecacheUnitByNameAsync("npc_aac_creep_vulture_dire", emptyFunc)
	PrecacheUnitByNameAsync("npc_aac_creep_satyr_dire", emptyFunc)
	PrecacheUnitByNameAsync("npc_aac_creep_dragon_dire", emptyFunc)
	PrecacheResource("particle", "particles/life_catcher/life_catcher_out.vpcf", context)
	PrecacheResource("particle", "particles/life_catcher/life_catcher_in.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_visage/visage_soul_assumption_bolt.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_enchantress/enchantress_impetus.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_base_attack.vpcf", context)
end

function Activate()
    print( "AngelArena Activate start." )
	GameRules.AngelArena = AngelArena()
	GameRules.AngelArena:InitGameMode()
end

function AngelArena:InitGameMode()
	print( "AngelArena InitGameMode start." )
	
	for _, moduleName in pairs(postRequireList) do
		require(moduleName)
	end
	GameRules:SetTimeOfDay(0.25)
	GameRules:SetCustomGameSetupAutoLaunchDelay(0)
    GameRules:SetHeroSelectPenaltyTime(0)
    GameRules:SetPreGameTime(0)
    GameRules:SetShowcaseTime(0)
    GameRules:SetStrategyTime(0)
    GameRules:SetPostGameTime(0)
    GameRules:SetCustomGameBansPerTeam(0)
    -- Отключаем стандартный выбор героя Dota, чтобы он не назначал случайных героев.
    -- Выбором полностью управляет наша кастомная система (HeroSelection).
    GameRules:SetHeroSelectionTimeOverride(0)
	GameRules:SetUseUniversalShopMode(true)
    GameRules:GetGameModeEntity():SetFreeCourierModeEnabled(true)
	GameRules:SetGoldPerTick(2.5)
	GameRules:SetSameHeroSelectionEnabled(true)

	GameRules:SetHeroRespawnEnabled(true)
	GameRules:SetGoldTickTime(1)
	GameRules:SetTreeRegrowTime(40)
	GameRules:SetUseBaseGoldBountyOnHeroes(true)

	local GameMode = GameRules:GetGameModeEntity()
	Convars:SetInt("dota_max_physical_items_purchase_limit", 10000)
	GameMode:SetDraftingHeroPickSelectTimeOverride(60)
	GameMode:SetDraftingBanningTimeOverride(0)
	GameMode:SetBountyRuneSpawnInterval(120.0)
	GameMode:SetFixedRespawnTime(45)
	GameMode:SetCameraDistanceOverride(1440)
	GameMode:SetNeutralStashEnabled(false)
	for i = 0, 11 do
		GameMode:SetRuneEnabled(i, true)
	end
	
	GameMode:SetCustomXPRequiredToReachNextLevel(Constants.XP_PER_LEVEL_TABLE)
	GameMode:SetUseCustomHeroLevels(true)

	--Init listeners
	ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(AngelArena, 'OnGameRulesStateChange'), self)
	ListenToGameEvent('dota_rune_activated_server', function(context, event) return Runes:OnRuneActivate(event); end, {})
	ListenToGameEvent("entity_killed", Dynamic_Wrap(OnEntityKilledListener, "OnEntityKilled"), {})
	ListenToGameEvent('npc_spawned', Dynamic_Wrap(OnNPCSpawnedListener, "OnNPCSpawned"), {})
	
	--################################## BASE MODIFIERS ############################################### --
	LinkLuaModifier("modifier_full_disable_stun", 'modifiers/modifier_full_disable_stun', LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_hidden_from_map", 'modifiers/modifier_hidden_from_map', LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_dissapear", 'modifiers/modifier_dissapear', LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_stop", 'modifiers/modifier_stop', LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_medical_tractate", 'modifiers/modifier_medical_tractate', LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_godmode", 'modifiers/modifier_godmode', LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_courier", 'modifiers/modifier_courier', LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_fix_resist", 'modifiers/modifier_fix_resist', LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_magical_resistance", 'modifiers/modifier_magical_resistance', LUA_MODIFIER_MOTION_NONE)
	
	--########################################## FILTERS ############################################### --
	GameMode:SetRuneSpawnFilter(function(context, event) return Runes:ModifierRuneSpawn(event); end, {})
	GameMode:SetItemAddedToInventoryFilter(function(context, event) return NeutralSlotFilter:ItemAddedToInventoryFilter(event) end, {})
	GameMode:SetExecuteOrderFilter(function(context, event) return NeutralSlotFilter:ExecuteOrderFilter(event) end, {})
	GameMode:SetModifyGoldFilter(function(context, event) return GoldFilter:ModifyGoldFilter(event); end, {})
	GameMode:SetBountyRunePickupFilter(function(context, event) return GoldFilter:BountyRuneFilter(event); end, {})
	
	print("All modifiers linked")

    CreepSpawner:Init()
	CreepSpawner:RegisterOnSpawnCallback(function(arg) CreepLeveling:OnSpawnCallback(arg); end)
	CreepSpawner:RegisterOnDeathCallback(function(arg) CreepLeveling:OnDeathCallback(arg); end)
	
	BossSpawner:Init()
end


function AngelArena:OnGameInProgress(event)
    print("event on game start")
	CreepSpawner:StartSpawning()
	BossSpawner:StartSpawning()
	
	local heroes = HeroList:GetAllHeroes()
	for _, hero in pairs(heroes) do
		if hero and hero:IsRealHero() then
			print("IsRealHero")
			hero:AddNewModifier(nil, nil, "modifier_magical_resistance", {duration = -1})
		end
	end
end

function AngelArena:OnGameRulesStateChange(event)
    local newState = GameRules:State_Get()
    if newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
        print("[BATTLEARENA] HERO_SELECTION state! HeroSelection=" .. tostring(HeroSelection))
        if HeroSelection then
            if not HeroSelection._initialized then
                print("[BATTLEARENA] Calling HeroSelection:_init()")
                local ok, err = pcall(function() HeroSelection:_init() end)
                if not ok then
                    print("[BATTLEARENA] HeroSelection:_init() FAILED: " .. tostring(err))
                else
                    print("[BATTLEARENA] HeroSelection:_init() SUCCESS")
                end
            else
                print("[BATTLEARENA] HeroSelection already initialized")
            end
        else
            print("[BATTLEARENA] HeroSelection is nil!")
        end
    elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        -- FireGameEvent("dota_hud_error_message", {reason=80,message="Error msg!"})
        print("Game time: ", GameRules:GetGameTime())
        DuelController:OnGameStart()
        AngelArena:OnGameInProgress(event)
        for iPlayerID = 0, PlayerResource:GetPlayerCount() - 1 do
        local hero = PlayerResource:GetSelectedHeroEntity(iPlayerID)
        if hero then
            hero:AddNewModifier(hero, nil, "modifier_fix_resist", nil)
        end
    end
end
end