if HeroSelection then return end

HeroSelection = class({})

local PHASE_NONE   = "none"
local PHASE_BAN    = "ban"
local PHASE_PICK   = "pick"
local PHASE_DONE   = "done"

require("lib/timers")

function HeroSelection:_init()
    if self._initialized then return end
    self._initialized = true

    print("[HeroSelection] Initializing...")

    if not HeroSelectionConfig then
        print("[HeroSelection] ERROR: HeroSelectionConfig not loaded!")
        return
    end

    self.state = {
        phase    = PHASE_NONE,
        time_left = 0,
        banned   = {},
        picked   = {},
    }

    self:_BuildHeroPool()
    self:_RegisterGameEvents()
    self:_StartBanPhase()
end

local ATTR_MAP = {
    ["DOTA_ATTRIBUTE_STRENGTH"]     = "STR",
    ["DOTA_ATTRIBUTE_AGILITY"]      = "AGI",
    ["DOTA_ATTRIBUTE_INTELLECT"]    = "INT",
    ["DOTA_ATTRIBUTE_INTELLECTUAL"] = "INT",
    ["DOTA_ATTRIBUTE_UNIVERSAL"]    = "UNIVERSAL",
}

function HeroSelection:_BuildHeroPool()
    local normal = { STR = {}, AGI = {}, INT = {}, UNIVERSAL = {} }

    local hero_kv = LoadKeyValues("scripts/npc/heroes.kv")
    if not hero_kv then
        hero_kv = LoadKeyValues("scripts/npc/npc_heroes.kv")
    end
    local hero_count = 0
    if hero_kv then
        for hero_name, data in pairs(hero_kv) do
            if type(data) == "table" and string.find(hero_name, "npc_dota_hero_") then
                hero_count = hero_count + 1
                if not HeroSelectionConfig:IsExcludedFromNormal(hero_name) then
                    local attr_raw = data["AttributePrimary"]
                    local attr = attr_raw and ATTR_MAP[attr_raw]
                    if attr and normal[attr] then
                        table.insert(normal[attr], hero_name)
                    else
                        table.insert(normal.STR, hero_name)
                    end
                end
            end
        end
    end

    print("[HeroSelection] Loaded " .. hero_count .. " heroes from KV")

    if hero_count == 0 then
        print("[HeroSelection] KV load failed, using hardcoded hero list")
        local ALL_HEROES = {
            STR = {
                "npc_dota_hero_abaddon","npc_dota_hero_alchemist","npc_dota_hero_axe",
                "npc_dota_hero_beastmaster","npc_dota_hero_brewmaster","npc_dota_hero_bristleback",
                "npc_dota_hero_centaur","npc_dota_hero_chaos_knight","npc_dota_hero_clockwerk",
                "npc_dota_hero_dawnbreaker","npc_dota_hero_doom_bringer","npc_dota_hero_dragon_knight",
                "npc_dota_hero_earth_spirit","npc_dota_hero_earthshaker","npc_dota_hero_elder_titan",
                "npc_dota_hero_huskar","npc_dota_hero_kunkka","npc_dota_hero_legion_commander",
                "npc_dota_hero_life_stealer","npc_dota_hero_lycan","npc_dota_hero_magnataur",
                "npc_dota_hero_marci","npc_dota_hero_mars","npc_dota_hero_omniknight",
                "npc_dota_hero_pudge","npc_dota_hero_sand_king","npc_dota_hero_slardar",
                "npc_dota_hero_snapfire","npc_dota_hero_spirit_breaker","npc_dota_hero_tidehunter",
                "npc_dota_hero_treant","npc_dota_hero_tusk","npc_dota_hero_abyssal_underlord",
                "npc_dota_hero_undying","npc_dota_hero_wraith_king",
            },
            AGI = {
                "npc_dota_hero_antimage","npc_dota_hero_arc_warden","npc_dota_hero_bloodseeker",
                "npc_dota_hero_bounty_hunter","npc_dota_hero_clinkz","npc_dota_hero_drow_ranger",
                "npc_dota_hero_ember_spirit","npc_dota_hero_faceless_void","npc_dota_hero_gyrocopter",
                "npc_dota_hero_juggernaut","npc_dota_hero_luna","npc_dota_hero_medusa",
                "npc_dota_hero_morphling","npc_dota_hero_naga_siren","npc_dota_hero_nyx_assassin",
                "npc_dota_hero_pangolier","npc_dota_hero_phantom_assassin","npc_dota_hero_phantom_lancer",
                "npc_dota_hero_razor","npc_dota_hero_riki","npc_dota_hero_shadow_fiend",
                "npc_dota_hero_slark","npc_dota_hero_sniper","npc_dota_hero_spectre",
                "npc_dota_hero_terrorblade","npc_dota_hero_troll_warlord","npc_dota_hero_vengefulspirit",
                "npc_dota_hero_viper","npc_dota_hero_weaver","npc_dota_hero_lone_druid",
                "npc_dota_hero_broodmother",
            },
            INT = {
                "npc_dota_hero_ancient_apparition","npc_dota_hero_bane","npc_dota_hero_batrider",
                "npc_dota_hero_chen","npc_dota_hero_crystal_maiden","npc_dota_hero_dark_seer",
                "npc_dota_hero_dark_willow","npc_dota_hero_dazzle","npc_dota_hero_death_prophet",
                "npc_dota_hero_disruptor","npc_dota_hero_enchantress","npc_dota_hero_grimstroke",
                "npc_dota_hero_invoker","npc_dota_hero_jakiro","npc_dota_hero_keeper_of_the_light",
                "npc_dota_hero_leshrac","npc_dota_hero_lich","npc_dota_hero_lina",
                "npc_dota_hero_lion","npc_dota_hero_furion","npc_dota_hero_necrolyte",
                "npc_dota_hero_oracle","npc_dota_hero_outworld_destroyer","npc_dota_hero_puck",
                "npc_dota_hero_pugna","npc_dota_hero_queenofpain","npc_dota_hero_shadow_demon",
                "npc_dota_hero_shadow_shaman","npc_dota_hero_silencer","npc_dota_hero_skywrath_mage",
                "npc_dota_hero_storm_spirit","npc_dota_hero_techies","npc_dota_hero_tinker",
                "npc_dota_hero_witch_doctor","npc_dota_hero_warlock","npc_dota_hero_winter_wyvern",
            },
        }
        for attr, list in pairs(ALL_HEROES) do
            for _, h in ipairs(list) do
                if not HeroSelectionConfig:IsExcludedFromNormal(h) then
                    table.insert(normal[attr], h)
                end
            end
        end
    end

    for _, list in pairs(normal) do
        table.sort(list)
    end

    local custom = {}
    for name, data in pairs(HeroSelectionConfig.CUSTOM_HEROES) do
        table.insert(custom, {
            name      = name,
            display   = data.display,
            base_hero = data.base_hero,
            attribute = data.attribute,
        })
    end

    self.hero_pool = {
        normal = normal,
        custom = custom,
    }

    print("[HeroSelection] Hero pool built: STR=" .. #normal.STR .. " AGI=" .. #normal.AGI .. " INT=" .. #normal.INT .. " UNIV=" .. #normal.UNIVERSAL .. " custom=" .. #custom)
end

function HeroSelection:_RegisterGameEvents()
    CustomGameEventManager:RegisterListener("hero_ban", function(playerID, data)
        data.PlayerID = playerID
        self:_OnBanHero(data)
    end)

    CustomGameEventManager:RegisterListener("hero_selected_custom", function(playerID, data)
        data.PlayerID = playerID
        self:_OnPickHero(data)
    end)

    CustomGameEventManager:RegisterListener("hero_selected_normal", function(playerID, data)
        data.PlayerID = playerID
        self:_OnPickHero(data)
    end)
end

function HeroSelection:_StartBanPhase()
    print("[HeroSelection] Starting ban phase")
    self.state.phase = PHASE_BAN
    self.state.time_left = HeroSelectionConfig.BAN_TIME
    self.state.banned = {}
    self.state.picked = {}
    self:_SyncToClients()

    Timers:CreateTimer(1, function()
        if self.state.phase ~= PHASE_BAN then return end
        self.state.time_left = self.state.time_left - 1
        self:_SyncToClients()

        if self.state.time_left <= 0 then
            self:_StartPickPhase()
            return
        end
        return 1
    end)
end

function HeroSelection:_StartPickPhase()
    print("[HeroSelection] Starting pick phase")
    self.state.phase = PHASE_PICK
    self.state.time_left = HeroSelectionConfig.PICK_TIME
    self:_SyncToClients()

    Timers:CreateTimer(1, function()
        if self.state.phase ~= PHASE_PICK then return end
        self.state.time_left = self.state.time_left - 1
        self:_SyncToClients()

        if self.state.time_left <= 0 then
            self:_FinishSelection()
            return
        end
        return 1
    end)
end

function HeroSelection:_FinishSelection()
    print("[HeroSelection] Selection finished")
    self.state.phase = PHASE_DONE
    self:_SyncToClients()

    GameRules:FinishCustomGameSetup()

    Timers:CreateTimer(0.5, function()
        for pid, info in pairs(self.state.picked) do
            local player = PlayerResource:GetPlayer(pid)
            if player then
                local ok, err = pcall(function()
                    PlayerResource:ReplaceHeroWith(pid, info.hero, 625, 0)
                end)
                if ok then
                    print("[HeroSelection] Assigned " .. info.hero .. " to player " .. pid)
                else
                    print("[HeroSelection] ReplaceHeroWith failed for player " .. pid .. ": " .. tostring(err))
                end
            end
        end

        -- Auto-pick random heroes for players who didn't pick
        for pid = 0, PlayerResource:GetPlayerCount() - 1 do
            if PlayerResource:IsValidPlayer(pid) and not self.state.picked[pid] then
                local pool = {}
                for _, list in pairs(self.hero_pool.normal) do
                    for _, h in ipairs(list) do
                        if not self.state.banned[h] then
                            table.insert(pool, h)
                        end
                    end
                end
                if #pool > 0 then
                    local rnd = pool[RandomInt(1, #pool)]
                    local ok, err = pcall(function()
                        PlayerResource:ReplaceHeroWith(pid, rnd, 625, 0)
                    end)
                    if ok then
                        print("[HeroSelection] Auto-assigned random hero " .. rnd .. " to player " .. pid)
                    else
                        print("[HeroSelection] Auto-assign failed for player " .. pid .. ": " .. tostring(err))
                    end
                end
            end
        end
    end)
end

function HeroSelection:_OnBanHero(data)
    print("[HeroSelection] _OnBanHero called, phase=" .. tostring(self.state and self.state.phase))

    if not self.state or self.state.phase ~= PHASE_BAN then
        print("[HeroSelection] REJECTED: wrong phase")
        return
    end

    local pid = data.PlayerID
    print("[HeroSelection] PlayerID=" .. tostring(pid))
    if pid == nil or pid < 0 then
        print("[HeroSelection] REJECTED: invalid PlayerID")
        return
    end

    local hero_name = data.hero_name
    if not hero_name or hero_name == "" then return end

    local total_bans = 0
    for _, info in pairs(self.state.banned) do
        if info.by == pid then total_bans = total_bans + 1 end
    end
    if total_bans >= HeroSelectionConfig.BANS_PER_PLAYER then return end

    if self.state.banned[hero_name] then return end
    if self.state.picked[pid] then return end

    self.state.banned[hero_name] = { by = pid }

    print("[HeroSelection] Player " .. pid .. " banned " .. hero_name)
    self:_SyncToClients()
end

function HeroSelection:_OnPickHero(data)
    print("[HeroSelection] _OnPickHero called, phase=" .. tostring(self.state and self.state.phase))

    if not self.state or self.state.phase ~= PHASE_PICK then
        print("[HeroSelection] REJECTED: wrong phase")
        return
    end

    local pid = data.PlayerID
    print("[HeroSelection] PlayerID=" .. tostring(pid))
    if pid == nil or pid < 0 then
        print("[HeroSelection] REJECTED: invalid PlayerID")
        return
    end

    local hero_name = data.hero_name
    print("[HeroSelection] hero_name=" .. tostring(hero_name))
    if not hero_name or hero_name == "" then
        print("[HeroSelection] REJECTED: empty hero_name")
        return
    end

    if self.state.picked[pid] then
        print("[HeroSelection] REJECTED: player " .. pid .. " already picked")
        return
    end
    if self.state.banned[hero_name] then
        print("[HeroSelection] REJECTED: hero " .. hero_name .. " is banned")
        return
    end

    local is_custom = HeroSelectionConfig:IsCustomHero(hero_name)
    local real_hero = is_custom and HeroSelectionConfig:GetBaseHero(hero_name) or hero_name

    print("[HeroSelection] ACCEPTED: player " .. pid .. " -> " .. real_hero)
    self:_PickHero(pid, real_hero, is_custom)

    local picked_count = 0
    for _ in pairs(self.state.picked) do
        picked_count = picked_count + 1
    end
    if picked_count >= 10 then
        print("[HeroSelection] All 10 players picked, finishing early")
        self:_FinishSelection()
    end
end

function HeroSelection:_PickHero(pid, hero_name, is_custom)
    self.state.picked[pid] = {
        hero      = hero_name,
        is_custom = is_custom,
    }

    local player = PlayerResource:GetPlayer(pid)
    if player then
        CustomGameEventManager:Send_ServerToPlayer(player, "hero_selection_picked", {
            hero      = hero_name,
            is_custom = is_custom and 1 or 0,
        })
    end

    print("[HeroSelection] Player " .. pid .. " picked " .. hero_name)
    self:_SyncToClients()
end

function HeroSelection:_GetDataForClients()
    local banned_data = {}
    for hero_name, info in pairs(self.state.banned) do
        local base_hero = nil
        if HeroSelectionConfig:IsCustomHero(hero_name) then
            base_hero = HeroSelectionConfig:GetBaseHero(hero_name)
        end
        banned_data[hero_name] = {
            by        = info.by,
            base_hero = base_hero,
        }
    end

    return {
        phase      = self.state.phase,
        timer      = self.state.time_left,
        banned     = banned_data,
        picked     = self.state.picked,
        normal     = self.hero_pool.normal,
        custom     = self.hero_pool.custom,
    }
end

function HeroSelection:_SyncToClients()
    local data = self:_GetDataForClients()
    CustomNetTables:SetTableValue("hero_selection", "data", data)
end
