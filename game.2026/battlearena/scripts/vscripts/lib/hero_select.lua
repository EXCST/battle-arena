-- Hero pick state machine, ported from wod custom pick and adapted for battlearena.
-- Differences from the original:
--   * hero roster + abilities come from battlearena's own PreloadCache (merged npc_heroes.txt + npc_heroes_custom.txt)
--   * herolist.txt is the pickable roster (matches the standard Dota pick behaviour)
--   * bans are ALWAYS enabled with a fixed number of bans per player (no tournament voting)
--   * no donations, no tournament mode, no rating maps, no first-pick steam ids, no chat-wheel sounds
--   * events use stock CustomGameEventManager (events_protector from wod is NOT ported)
--   * RegisterLoadListener replaced by player_connect_full hook wired in addon_game_mode.lua

_G.hero_select = class({})

PICK_STATE_PLAYERS_LOADED = "PICK_STATE_PLAYERS_LOADED"
PICK_STATE_BAN = "PICK_STATE_BAN"
PICK_STATE_SELECT_HERO = "PICK_STATE_SELECT_HERO"
PICK_STATE_PICK_END = "PICK_STATE_PICK_END"

PICK_STATE = PICK_STATE_PLAYERS_LOADED
TIME_OF_STATE = 30
TIME_TO_PICK_HERO = 20
TIME_TO_BAN_HERO = 10
LOBBY_PLAYERS = {}
LOBBY_PLAYERS_MAX = 0
HEROES_FOR_PICK = {}
PICKED_HEROES = {}
BANNED_HEROES = {}
PICK_ORDER = 0
BAN_ORDER = 0
PLAYER_IS_BAN_NEXT = false
_G.IN_STATE = false
MAX_BANS_COUNTER = 0

-- how many heroes each player may ban during the ban phase
PICK_BANS_PER_PLAYER = 1

function hero_select:init()
    _G.IN_STATE = true

    CustomTables:SetTableValue(
        "custom_pick",
        "pick_state",
        {
            in_progress = true
        }
    )

    CustomGameEventManager:RegisterListener( "chose_hero", Dynamic_Wrap(self, "ChoseHero"))
    CustomGameEventManager:RegisterListener( "select_ban_hero", Dynamic_Wrap(self, "select_ban_hero"))

    for i = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        if PlayerResource:IsValidTeamPlayerID(i) then
            self:RegisterPlayerInfo(i)
        end
    end

    self:CheckReadyPlayers()
end

function hero_select:CheckReadyPlayers(attempt)
    if PICK_STATE ~= PICK_STATE_PLAYERS_LOADED then
        return
    end

    local bAllReady = true
    for pid, pinfo in pairs(LOBBY_PLAYERS) do
        if pinfo.bRegistred and not pinfo.bLoaded then
            bAllReady = false
        end
    end

    if bAllReady then
        hero_select:Start()
    else
        local check_interval = 0.5
        attempt = (attempt or 0) + check_interval
        if attempt > TIME_OF_STATE then
            hero_select:Start()
        else
            Timers:CreateTimer(
                "",
                {
                    useGameTime = false,
                    endTime = check_interval,
                    callback = function()
                        hero_select:CheckReadyPlayers(attempt)
                    end
                }
            )
        end
    end
end

function hero_select:GetState()
    return PICK_STATE
end

function hero_select:PlayerConnected(params)
	if params.PlayerID == nil then return end
    local pinfo = hero_select:RegisterPlayerInfo(params.PlayerID)
    if not pinfo then return end
    pinfo.bRegistred = true
    pinfo.bLoaded = true
    hero_select:PlayerLoaded(params.PlayerID)
end

function hero_select:PlayerLoaded(pid)
    if pid == nil then return end

    if not LOBBY_PLAYERS[pid] then
        local player = PlayerResource:GetPlayer(pid)
        if player then
            CustomGameEventManager:Send_ServerToPlayer(player, "pick_end", {})
        end
        return
    end

    LOBBY_PLAYERS[pid].bLoaded = true

    if not IN_STATE then
        local player = PlayerResource:GetPlayer(pid)
        if player then
            CustomGameEventManager:Send_ServerToPlayer(player, "pick_end", {})
        end
        return
    end

    if PICK_STATE ~= PICK_STATE_PLAYERS_LOADED then
        hero_select:DrawPickScreenForPlayer(pid)
        if PICK_STATE == PICK_STATE_SELECT_HERO then
            local player = PlayerResource:GetPlayer(pid)
            if player then
                CustomGameEventManager:Send_ServerToPlayer( player, "reload_pick_heroes", { lobby_players = LOBBY_PLAYERS,  } )
            end
        elseif PICK_STATE == PICK_STATE_PICK_END then
            local player = PlayerResource:GetPlayer(pid)
            if player then
                CustomGameEventManager:Send_ServerToPlayer(player, "pick_end", {})
            end
        end
    end
end

function hero_select:RegisterHeroes()
    local enable_heroes = {}
    local hero_list = {}
    local custom_hero_list = {}

    local heroes = LoadKeyValues("scripts/npc/herolist.txt")
    if not heroes then
        print("[hero_select] ERROR: scripts/npc/herolist.txt not found")
        return
    end

    local hero_data = PreloadCache:GetHeroData()
    local ability_data = PreloadCache:GetAbilityData() or {}

    local innates_ignore_move =
    {
        ["dawnbreaker_break_of_dawn"] = true,
        ["dragon_knight_dragon_blood"] = true,
        ["huskar_blood_magic"] = true,
    }
    local enable_hud_abilities =
    {
        ["lone_druid_spirit_bear"] = true,
        ["monkey_king_mischief"] = true,
        ["phantom_assassin_blur"] = true,
        ["invoker_invoke"] = true,
        ["marci_special_delivery"] = true,
        ["kez_switch_weapons"] = true,
    }

    for hero_name, is_enable in pairs(heroes) do
        if is_enable == 1 then
            table.insert(enable_heroes, hero_name)
        end
    end

    for _, hero_name in pairs(enable_heroes) do
        local hero_info = hero_data[hero_name]
        local abilities_list = {}
        if hero_info then
            -- talents start at AbilityTalentStart (usually 10); the pick preview shows only skills, no talents
            local talent_start = tonumber(hero_info["AbilityTalentStart"]) or 10
            for ability_id = 1, 20 do
                local ability = hero_info["Ability" .. ability_id]
                if ability and ability ~= "" and ability ~= "generic_hidden" and not ability:find("_empty") then
                    if ability_id < talent_start or enable_hud_abilities[ability] then
                        local behavior = nil
                        local is_innate = false
                        local ability_info = ability_data[ability]
                        if ability_info then
                            behavior = ability_info.AbilityBehavior
                            if ability_info.Innate then
                                is_innate = true
                            end
                        end
                        -- NOTE: the base npc_abilities.txt lives in the VPK and LoadKeyValues cannot
                        -- read it, so base-game abilities have behavior == nil here. Treat nil behavior
                        -- as "visible" (the hero section itself is the source of truth for the slots).
                        local hidden = behavior and behavior:find("DOTA_ABILITY_BEHAVIOR_HIDDEN")
                        if is_innate and (hidden or (behavior and behavior:find("DOTA_ABILITY_BEHAVIOR_INNATE_UI")) or innates_ignore_move[ability]) then
                            -- skip hidden innate
                        elseif not is_innate and (behavior == nil or not hidden) then
                            table.insert(abilities_list, ability)
                        end
                        if enable_hud_abilities[ability] then
                            table.insert(abilities_list, ability)
                        end
                    end
                end
            end
            CustomTables:SetTableValue("custom_pick", tostring(hero_name), abilities_list)
            if hero_info.Model and hero_info.Model ~= "" then
                CustomTables:SetTableValue("custom_pick", tostring(hero_name) .. "_model", hero_info.Model)
            end
        end
    end

    HEROES_FOR_PICK = {}

    local sort_heroes = {[0]={}, [1]={}, [2]={}, [3]={}}
    for _, hero in pairs(enable_heroes) do
        local hero_info = hero_data[hero]
        if hero_info then
            -- gods are repick-only (IsGod flag comes from the override merge in kv_preloaded_data)
            -- NOTE: LoadKeyValues converts "1" to number 1, compare via tonumber
            if tonumber(hero_info.IsGod) == 1 then
                print("[hero_select] god hero " .. hero .. " excluded from pick (repick only)")
            else
                local primary = hero_info.AttributePrimary
                local attr = 3
                if primary == "DOTA_ATTRIBUTE_STRENGTH" then
                    attr = 0
                elseif primary == "DOTA_ATTRIBUTE_AGILITY" then
                    attr = 1
                elseif primary == "DOTA_ATTRIBUTE_INTELLECT" then
                    attr = 2
                end
                if tonumber(hero_info.IsCustom) == 1 then
                    custom_hero_list[hero] = attr
                else
                    hero_list[hero] = attr
                    table.insert(sort_heroes[attr], hero)
                end
                table.insert(HEROES_FOR_PICK, hero)
            end
        else
            print("[hero_select] WARNING: hero " .. hero .. " from herolist.txt has no data in PreloadCache, skipped")
        end
    end

    CustomTables:SetTableValue("custom_pick", "hero_list", hero_list)
    CustomTables:SetTableValue("custom_pick", "custom_hero_list", custom_hero_list)
end

function hero_select:RegisterPlayerInfo(pid)
    if PlayerResource:GetSteamAccountID(pid) == 0 then
        return
    end
    local pinfo = LOBBY_PLAYERS[pid]
    if pinfo == nil then
        pinfo = {
            bRegistred = false,
            bLoaded = false,
            steamid = PlayerResource:GetSteamAccountID(pid),
            picked_hero = nil,
            pick_order = nil,
            respawn = false,
            bans_counter = 0,
        }
        LOBBY_PLAYERS_MAX = LOBBY_PLAYERS_MAX + 1
        if PICK_STATE ~= PICK_STATE_PLAYERS_LOADED then
            pinfo.pick_order = LOBBY_PLAYERS_MAX - 1
        end
    end
    LOBBY_PLAYERS[pid] = pinfo
    return pinfo
end

function hero_select:AllPlayersRespawn()
    for _, info in pairs(LOBBY_PLAYERS) do
        if info and info.respawn == false then
            return false
        end
    end
    return true
end

function hero_select:Start()
    local r = 0
    local used_numbers = {}

    for i, player in pairs(LOBBY_PLAYERS) do
        repeat
            r = RandomInt(0, LOBBY_PLAYERS_MAX - 1)
        until not hero_select:check_used(used_numbers, r)
        used_numbers[#used_numbers + 1] = r
        player.pick_order = r
    end

    CustomTables:SetTableValue(
        "custom_pick",
        "player_lobby",
        {
            lobby_players = LOBBY_PLAYERS,
            lobby_players_length = LOBBY_PLAYERS_MAX
        }
    )

    for pid, pinfo in pairs(LOBBY_PLAYERS) do
        if pinfo.bLoaded then
            hero_select:DrawPickScreenForPlayer(pid)
        end
    end

    -- ban stage removed (2026-08-10): picking starts immediately
    hero_select:StartSelectionStage(true)
end

function hero_select:StartBanState()
    PICK_STATE = PICK_STATE_BAN
    local bans_counter = PICK_BANS_PER_PLAYER
    for pid, info in pairs(LOBBY_PLAYERS) do
        LOBBY_PLAYERS[pid].bans_counter = bans_counter
    end
    MAX_BANS_COUNTER = bans_counter
    hero_select:UpdateOrdersPick()
    local time = 3
    CustomGameEventManager:Send_ServerToAllClients("change_time", {time = time, id = -1})
    Timers:CreateTimer(
        "",
        {
            useGameTime = false,
            endTime = 1,
            callback = function()
                time = time - 1
                CustomGameEventManager:Send_ServerToAllClients("change_time", {time = time, id = -1})
                if time <= 0 then
                    hero_select:StartBanOrderPick()
                    return
                end
                return 1
            end
        }
    )
end

function hero_select:UpdateOrdersPick()
    local r = 0
    local used_numbers = {}

    for i, player in pairs(LOBBY_PLAYERS) do
        repeat
            r = RandomInt(0, LOBBY_PLAYERS_MAX - 1)
        until not hero_select:check_used(used_numbers, r)
        used_numbers[#used_numbers + 1] = r
        player.pick_order = r
    end

    CustomTables:SetTableValue("custom_pick", "player_lobby",
    {
        lobby_players = LOBBY_PLAYERS,
        lobby_players_length = LOBBY_PLAYERS_MAX
    })

    CustomGameEventManager:Send_ServerToAllClients("UpdatePlayersOrdersList", {})
end

function hero_select:StartBanOrderPick()
    PLAYER_IS_BAN_NEXT = false
    local time = TIME_TO_BAN_HERO
    local id = 0
    for pid, pinfo in pairs(LOBBY_PLAYERS) do
        if pinfo.pick_order == BAN_ORDER then
            CustomGameEventManager:Send_ServerToAllClients("pick_start_time", {id = pid, time = time})
            CustomTables:SetTableValue( "custom_pick", "active_player", { id = pid, is_ban = 1, is_ban_stage = true } )
            id = pid
            break
        end
    end
    CustomGameEventManager:Send_ServerToAllClients("change_time", {time = time, id = id})
    Timers:CreateTimer(
        "",
        {
            useGameTime = false,
            endTime = 1,
            callback = function()
                time = time - 1
                CustomGameEventManager:Send_ServerToAllClients("change_time", {time = time, id = id})
                if time <= 0 or (PLAYER_IS_BAN_NEXT) then
                    if time <= 0 then
                        local rand_hero = hero_select:RandomHero(id)
                        hero_select:select_ban_hero({PlayerID = id, hero = rand_hero})
                    end
                    BAN_ORDER = BAN_ORDER + 1
                    if BAN_ORDER >= LOBBY_PLAYERS_MAX then
                        BAN_ORDER = 0
                        MAX_BANS_COUNTER = MAX_BANS_COUNTER - 1
                        hero_select:DelayCircleBans()
                        return
                    end
                    if MAX_BANS_COUNTER > 0 then
                        hero_select:StartBanOrderPick()
                    else
                        hero_select:StartSelectionStage(true)
                    end
                    return
                end
                return 1
            end
        }
    )
end

function hero_select:DelayCircleBans()
    local time = 3
    CustomTables:SetTableValue( "custom_pick", "active_player", { id = -1, is_ban = 1, is_ban_stage = true } )
    CustomGameEventManager:Send_ServerToAllClients("change_time", {time = time, id = -1})
    Timers:CreateTimer(
        "",
        {
            useGameTime = false,
            endTime = 1,
            callback = function()
                time = time - 1
                CustomGameEventManager:Send_ServerToAllClients("change_time", {time = time, id = -1})
                if time <= 0 then
                    CustomGameEventManager:Send_ServerToAllClients("ban_client_hero_reload", {})
                    if MAX_BANS_COUNTER > 0 then
                        hero_select:StartBanOrderPick()
                    else
                        hero_select:StartSelectionStage(true)
                    end
                    return
                end
                return 1
            end
        }
    )
end

function hero_select:select_ban_hero(params)
    local player_id = params.PlayerID
    local hero_name = params.hero
    if LOBBY_PLAYERS[player_id].bans_counter ~= MAX_BANS_COUNTER then return end
    if hero_select:check_picked(hero_name) then return end
    LOBBY_PLAYERS[player_id].bans_counter = LOBBY_PLAYERS[player_id].bans_counter - 1
    table.insert(BANNED_HEROES, hero_name)
    PLAYER_IS_BAN_NEXT = true
    CustomGameEventManager:Send_ServerToAllClients("ban_client_hero", {hero_name = hero_name, player_id = player_id})
    CustomTables:SetTableValue(
        "custom_pick",
        "player_list",
        {
            picked_heroes = PICKED_HEROES,
            banned_heroes = BANNED_HEROES,
        }
    )
end

function hero_select:StartSelectionStage(delay_minus)
    local delay = 1
    if delay_minus then
        delay = FrameTime()
    end
    PICK_STATE = PICK_STATE_SELECT_HERO
    Timers:CreateTimer(
        "",
        {
            useGameTime = false,
            endTime = delay,
            callback = function()
                hero_select:StartOrderPick()
            end
        }
    )
end

function hero_select:StartOrderPick()
    CustomGameEventManager:Send_ServerToAllClients("change_color_timer", {})
    local time = TIME_TO_PICK_HERO
    local id = nil
    for pid, pinfo in pairs(LOBBY_PLAYERS) do
        if pinfo.pick_order == PICK_ORDER then
            CustomGameEventManager:Send_ServerToAllClients("pick_start_time", {id = pid, time = time})
            CustomTables:SetTableValue(
                "custom_pick",
                "active_player",
                {
                    id = pid
                }
            )
            id = pid
            break
        end
    end

    if id == nil then
        PICK_ORDER = PICK_ORDER + 1
        if PICK_ORDER < LOBBY_PLAYERS_MAX + 1 then
            hero_select:StartOrderPick()
        else
            hero_select:check_picked_players()
        end
        return
    end

    CustomGameEventManager:Send_ServerToAllClients("change_time", {time = time, id = id})

    Timers:CreateTimer(
        "",
        {
            useGameTime = false,
            endTime = 1,
            callback = function()
                if LOBBY_PLAYERS_MAX ~= 1 then
                    time = time - 1
                end

                CustomGameEventManager:Send_ServerToAllClients("change_time", {time = time, id = id, })

                if time <= 0 or (LOBBY_PLAYERS[id].picked_hero ~= nil) then
                    if LOBBY_PLAYERS[id].picked_hero == nil then
                        local rand_hero = hero_select:RandomHero(id)
                        hero_select:PickHero(id, rand_hero, 1, 1)
                    end

                    if PICK_STATE ~= PICK_STATE_SELECT_HERO then
                        return
                    end

                    PICK_ORDER = PICK_ORDER + 1

                    if PICK_ORDER < LOBBY_PLAYERS_MAX + 1 then
                        hero_select:StartOrderPick()
                    end

                    return
                end
                return 1
            end
        }
    )
end

function hero_select:EndPick()
    if PICK_STATE ~= PICK_STATE_PICK_END then
        PICK_STATE = PICK_STATE_PICK_END
        CustomTables:SetTableValue( "custom_pick", "pick_state", { in_progress = false } )
        CustomGameEventManager:Send_ServerToAllClients("pick_end", {})
        hero_select:GiveHeroesPlayersStart()
        Timers:CreateTimer(0.4, function()
            _G.IN_STATE = false
        end)
    end
end

function hero_select:RandomHero(id)
    local hero
    repeat
        local random = RandomInt(1, #HEROES_FOR_PICK)
        hero = HEROES_FOR_PICK[random]
    until not hero_select:check_used(PICKED_HEROES, hero) and not hero_select:check_used(BANNED_HEROES, hero)

    return hero
end

function HasHeroForPick(hero)
    for _, hero_name in pairs(HEROES_FOR_PICK) do
        if hero_name == hero then
            return false
        end
    end
    return true
end

function hero_select:check_used( t , n )
	if #t == 0 then return false end
	for i = 1,#t do
		if t[i] == n then return true end
	end
	return false
end

function hero_select:ChoseHero(params)
    if params.PlayerID == nil then
        return
    end

    if not params.hero then
        return
    end

    if PICK_STATE ~= PICK_STATE_SELECT_HERO then
        return
    end

    if HasHeroForPick(params.hero) then
        return
    end

    local id = params.PlayerID

    local player_info = LOBBY_PLAYERS[params.PlayerID]

    if params.random then
        local random_hero = hero_select:RandomHero(params.PlayerID)
        LOBBY_PLAYERS[params.PlayerID].randomed = true
        if player_info.picked_hero ~= nil or hero_select:check_picked(random_hero) then
            return
        end
        local player = PlayerResource:GetPlayer(params.PlayerID)
        if player then
            CustomGameEventManager:Send_ServerToPlayer(player, "change_random", {hero = random_hero, })
        end
        hero_select:PickHero(params.PlayerID, random_hero, 1)
        return
    end

    if player_info.picked_hero ~= nil or hero_select:check_picked(params.hero) then
        return
    end

    LOBBY_PLAYERS[params.PlayerID].randomed = false
    hero_select:PickHero(params.PlayerID, params.hero, 0)
    local player = PlayerResource:GetPlayer(params.PlayerID)
    if player then
        CustomGameEventManager:Send_ServerToPlayer(player, "change_random", {hero = params.hero, })
    end
end

function hero_select:check_picked_players()

    for id, i in pairs(LOBBY_PLAYERS) do
        if i.picked_hero == nil then
            return false
        end
    end

    hero_select:EndPickHeroes()
end

function hero_select:EndPickHeroes()
    CustomTables:SetTableValue(
        "custom_pick",
        "player_lobby",
        {
            lobby_players = LOBBY_PLAYERS,
            lobby_players_length = LOBBY_PLAYERS_MAX
        }
    )
    hero_select:EndPick()
end

function hero_select:check_picked(hero)
    for _, i in pairs(PICKED_HEROES) do
        if i == hero then
            return true
        end
    end
    for _, i in pairs(BANNED_HEROES) do
        if i == hero then
            return true
        end
    end

    return false
end

function hero_select:DrawPickScreenForPlayer(pid)
    if not PlayerResource:IsValidPlayerID(pid) then
        return
    end
    local player = PlayerResource:GetPlayer(pid)
    if not player then
        return
    end
    CustomGameEventManager:Send_ServerToPlayer(player, "pick_start", {})
end

function hero_select:PickHero(id, name, random, disc)
    local player_info = LOBBY_PLAYERS[id]
    LOBBY_PLAYERS[id].picked_hero = name
    table.insert(PICKED_HEROES, name)
    CustomTables:SetTableValue(
        "custom_pick",
        "player_list",
        {
            picked_heroes = PICKED_HEROES,
            banned_heroes = BANNED_HEROES,
        }
    )
    CustomTables:SetTableValue(
        "custom_pick",
        "player_current_hero"..id,
        {
            picked = 1
        }
    )

    CustomGameEventManager:Send_ServerToAllClients("pick_select_hero", {hero = name, id = id, random = random, })

    if disc == nil then
        local player = PlayerResource:GetPlayer(id)
        if player ~= nil then
            CustomGameEventManager:Send_ServerToPlayer(player, "change_random", {hero = name})
        end
    end

    local player = PlayerResource:GetPlayer(id)
    if player then
        player:SetSelectedHero(name)
    end

    hero_select:check_picked_players()
end

function hero_select:GiveHeroesPlayersStart()
    for id = 0, 24 do
        if PlayerResource:IsValidTeamPlayerID(id) and PlayerResource:GetSteamAccountID(id) ~= 0 then
            if PlayerResource:GetSelectedHeroName(id) == "" then
                if LOBBY_PLAYERS[id] ~= nil then
                    if LOBBY_PLAYERS[id].picked_hero == nil then
                        hero_select:PickHero(id, hero_select:RandomHero(id), 1, 1)
                    else
                        local player = PlayerResource:GetPlayer(id)
                        if player then
                            player:SetSelectedHero(LOBBY_PLAYERS[id].picked_hero)
                        end
                    end
                end
            end
        elseif PlayerResource:IsValidTeamPlayerID(id) and PlayerResource:GetSteamAccountID(id) == 0 then
            -- bots: assign a random hero so the game can start
            if PlayerResource:GetSelectedHeroName(id) == "" then
                local hero = hero_select:RandomHero(id)
                local player = PlayerResource:GetPlayer(id)
                if player then
                    player:SetSelectedHero(hero)
                end
            end
        end
    end
end
