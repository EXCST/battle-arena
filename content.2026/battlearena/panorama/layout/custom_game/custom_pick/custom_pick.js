const ContextPanel = $.GetContextPanel()
const main = $.GetContextPanel
$.GetContextPanel = () => main() || ContextPanel

const heroesId = 
{
    npc_dota_hero_antimage: 1,
    npc_dota_hero_axe: 2,
    npc_dota_hero_bane: 3,
    npc_dota_hero_bloodseeker: 4,
    npc_dota_hero_crystal_maiden: 5,
    npc_dota_hero_drow_ranger: 6,
    npc_dota_hero_earthshaker: 7,
    npc_dota_hero_juggernaut: 8,
    npc_dota_hero_mirana: 9,
    npc_dota_hero_nevermore: 11,
    npc_dota_hero_morphling: 10,
    npc_dota_hero_phantom_lancer: 12,
    npc_dota_hero_puck: 13,
    npc_dota_hero_pudge: 14,
    npc_dota_hero_razor: 15,
    npc_dota_hero_sand_king: 16,
    npc_dota_hero_storm_spirit: 17,
    npc_dota_hero_sven: 18,
    npc_dota_hero_tiny: 19,
    npc_dota_hero_vengefulspirit: 20,
    npc_dota_hero_windrunner: 21,
    npc_dota_hero_zuus: 22,
    npc_dota_hero_kunkka: 23,
    npc_dota_hero_lina: 25,
    npc_dota_hero_lich: 31,
    npc_dota_hero_lion: 26,
    npc_dota_hero_shadow_shaman: 27,
    npc_dota_hero_slardar: 28,
    npc_dota_hero_tidehunter: 29,
    npc_dota_hero_witch_doctor: 30,
    npc_dota_hero_riki: 32,
    npc_dota_hero_enigma: 33,
    npc_dota_hero_tinker: 34,
    npc_dota_hero_sniper: 35,
    npc_dota_hero_necrolyte: 36,
    npc_dota_hero_warlock: 37,
    npc_dota_hero_beastmaster: 38,
    npc_dota_hero_queenofpain: 39,
    npc_dota_hero_venomancer: 40,
    npc_dota_hero_faceless_void: 41,
    npc_dota_hero_skeleton_king: 42,
    npc_dota_hero_death_prophet: 43,
    npc_dota_hero_phantom_assassin: 44,
    npc_dota_hero_pugna: 45,
    npc_dota_hero_templar_assassin: 46,
    npc_dota_hero_viper: 47,
    npc_dota_hero_luna: 48,
    npc_dota_hero_dragon_knight: 49,
    npc_dota_hero_dazzle: 50,
    npc_dota_hero_rattletrap: 51,
    npc_dota_hero_leshrac: 52,
    npc_dota_hero_furion: 53,
    npc_dota_hero_life_stealer: 54,
    npc_dota_hero_dark_seer: 55,
    npc_dota_hero_clinkz: 56,
    npc_dota_hero_omniknight: 57,
    npc_dota_hero_enchantress: 58,
    npc_dota_hero_huskar: 59,
    npc_dota_hero_night_stalker: 60,
    npc_dota_hero_broodmother: 61,
    npc_dota_hero_bounty_hunter: 62,
    npc_dota_hero_weaver: 63,
    npc_dota_hero_jakiro: 64,
    npc_dota_hero_batrider: 65,
    npc_dota_hero_chen: 66,
    npc_dota_hero_spectre: 67,
    npc_dota_hero_doom_bringer: 69,
    npc_dota_hero_ancient_apparition: 68,
    npc_dota_hero_ursa: 70,
    npc_dota_hero_spirit_breaker: 71,
    npc_dota_hero_gyrocopter: 72,
    npc_dota_hero_alchemist: 73,
    npc_dota_hero_invoker: 74,
    npc_dota_hero_silencer: 75,
    npc_dota_hero_obsidian_destroyer: 76,
    npc_dota_hero_lycan: 77,
    npc_dota_hero_brewmaster: 78,
    npc_dota_hero_shadow_demon: 79,
    npc_dota_hero_lone_druid: 80,
    npc_dota_hero_chaos_knight: 81,
    npc_dota_hero_meepo: 82,
    npc_dota_hero_treant: 83,
    npc_dota_hero_ogre_magi: 84,
    npc_dota_hero_undying: 85,
    npc_dota_hero_rubick: 86,
    npc_dota_hero_disruptor: 87,
    npc_dota_hero_nyx_assassin: 88,
    npc_dota_hero_naga_siren: 89,
    npc_dota_hero_keeper_of_the_light: 90,
    npc_dota_hero_wisp: 91,
    npc_dota_hero_visage: 92,
    npc_dota_hero_slark: 93,
    npc_dota_hero_medusa: 94,
    npc_dota_hero_troll_warlord: 95,
    npc_dota_hero_centaur: 96,
    npc_dota_hero_magnataur: 97,
    npc_dota_hero_shredder: 98,
    npc_dota_hero_bristleback: 99,
    npc_dota_hero_tusk: 100,
    npc_dota_hero_skywrath_mage: 101,
    npc_dota_hero_abaddon: 102,
    npc_dota_hero_elder_titan: 103,
    npc_dota_hero_legion_commander: 104,
    npc_dota_hero_ember_spirit: 106,
    npc_dota_hero_earth_spirit: 107,
    npc_dota_hero_abyssal_underlord: 108,
    npc_dota_hero_terrorblade: 109,
    npc_dota_hero_phoenix: 110,
    npc_dota_hero_techies: 105,
    npc_dota_hero_oracle: 111,
    npc_dota_hero_winter_wyvern: 112,
    npc_dota_hero_arc_warden: 113,
    npc_dota_hero_monkey_king: 114,
    npc_dota_hero_dark_willow: 119,
    npc_dota_hero_pangolier: 120,
    npc_dota_hero_grimstroke: 121,
    npc_dota_hero_hoodwink: 123,
    npc_dota_hero_void_spirit: 126,
    npc_dota_hero_snapfire: 128,
    npc_dota_hero_mars: 129,
    npc_dota_hero_dawnbreaker: 135,
    npc_dota_hero_marci: 136,
    npc_dota_hero_primal_beast: 137,
    npc_dota_hero_muerta: 138,
    npc_dota_hero_kez: 145,
    npc_dota_hero_stegius: 206,
    npc_dota_hero_mirratie: 209,
};

function init() 
{
	if (IsSpectator())
	{
		return
	}

	GameEvents.Subscribe("pick_start", pick_start)
	GameEvents.Subscribe("pick_select_hero", pick_select_hero)
	GameEvents.Subscribe("reload_pick_heroes", reload_pick_heroes)
	GameEvents.Subscribe("pick_end", end_pick)
	GameEvents.Subscribe("pick_start_time", pick_start_time)
	GameEvents.Subscribe("change_time", change_time)
	GameEvents.Subscribe("change_random", change_random)
	GameEvents.Subscribe("ban_client_hero", ban_client_hero)
	GameEvents.Subscribe("ban_client_hero_reload", ban_client_hero_reload)
	GameEvents.Subscribe("UpdatePlayersOrdersList", UpdatePlayersOrdersList)
	GameEvents.Subscribe("change_color_timer", change_color_timer)
}

function Player_Loaded() 
{
	if (IsSpectator()) 
	{
		$.GetContextPanel().AddClass('Deletion');
		$.GetContextPanel().style.opacity = "0"
		return
	}
	check_connection()

	WaitForHeroDataAndStart(0)
}

function WaitForHeroDataAndStart(attempt)
{
	const pick_state = Game.GetCustomTable("custom_pick", "pick_state")

	if (pick_state === undefined || pick_state === null || pick_state.in_progress)
	{
		const hero_list = Game.GetCustomTable("custom_pick", "hero_list")
		if (hero_list === undefined || hero_list === null)
		{
			if (attempt < 300)
			{
				$.Schedule(0.1, function() { WaitForHeroDataAndStart(attempt + 1) })
				return
			}
		}

		pick_load_heroes()
		pick_start()
	}
	else
	{
		end_pick()
	}
}

function check_connection() 
{
	for (var id = 0; id <= 23; id++) 
	{
		if (Players.GetPlayerSelectedHero(id) != 'invalid index') 
		{
			var playerInfo = Game.GetPlayerInfo(id);
			var icon = $.GetContextPanel().FindChildTraverse("player_icon" + id)

			if (icon && playerInfo) 
			{
				var connect = icon.FindChildTraverse("hero_connect" + id)
				var state = playerInfo.player_connection_state

				if (!connect && (state == DOTAConnectionState_t.DOTA_CONNECTION_STATE_DISCONNECTED || state == DOTAConnectionState_t.DOTA_CONNECTION_STATE_ABANDONED)) 
				{
					connect = $.CreatePanel("Panel", icon, "hero_connect" + id)
					connect.AddClass("hero_disconnect")
				}

				if (connect && playerInfo.player_connection_state == DOTAConnectionState_t.DOTA_CONNECTION_STATE_CONNECTED) 
				{
					connect.DeleteAsync(0)
				}

				if (playerInfo.player_connection_state == DOTAConnectionState_t.DOTA_CONNECTION_STATE_ABANDONED) {
					icon.AddClass("hero_abandon")
				}
			}
		}
	}

	$.Schedule(0.2, function() {
		const pick_state = Game.GetCustomTable("custom_pick", "pick_state")
		if (pick_state === undefined || pick_state === null || pick_state.in_progress)
		{
			check_connection()
		}
	})
}

function end_pick() 
{
	$.GetContextPanel().AddClass('Deletion');
	$.GetContextPanel().style.opacity = "0"

	$.Schedule(5, function() 
	{
		if ($("#BGScene_1"))
		{
			$("#BGScene_1").DeleteAsync(10)
		}
	})
}

function RandomHero() {
	Game.EmitSound("ui.pick_select")
	GameEvents.SendCustomGameEventToServer("chose_hero", 
	{
		random: true,
		hero: "npc_dota_hero_wisp",
		
	});
	Refresh_Button()
	Refresh_Random_Button()
}

var hero_selected = ''

function pick_start_time(kv)
{
	var hero_panel = $.GetContextPanel().FindChildTraverse("player" + kv.id)

	if (Game.GetLocalPlayerID() == kv.id)
	{
		$.Schedule(1, function()
        {
			Game.EmitSound("UI.Your_turn")
		})

		if (hero_selected !== '')
		{
			RefreshButtonUntilActive(0)
		}
		Refresh_Ban_Button()
		return
	}

	if (hero_selected !== '')
	{
		Refresh_Button()
		Refresh_Random_Button()
	}
	Refresh_Ban_Button()
}

function RefreshButtonUntilActive(attempt)
{
	Refresh_Button()
	Refresh_Random_Button()
	Refresh_Ban_Button()
	var active_player = Game.GetCustomTable("custom_pick", "active_player");
	if ((!active_player || active_player.id !== Game.GetLocalPlayerID()) && attempt < 20)
	{
		$.Schedule(0.05, function() { RefreshButtonUntilActive(attempt + 1) })
	}
}

function change_time(kv) 
{
	var timer = $.GetContextPanel().FindChildTraverse("pick_timer")

	if (timer) 
	{
		if (Game.GetLocalPlayerID() == kv.id) 
        {
			if (kv.time == 10) 
            {
				Game.EmitSound("UI.Pick_10_sec")
			}
			if (kv.time == 5) 
            {
				Game.EmitSound("UI.Pick_5_sec")
			}
			if (kv.time < 5) 
            {
				Game.EmitSound("General.ButtonClick");
			}
		}
		timer.text = String(kv.time)
	}
}

function CreatePlayerPanel(parent, pid)
{
    let has_player_child = $.CreatePanel("Panel", parent, "player" + pid);
    has_player_child.AddClass("player_portrait")
    
    let hero_icon = $.CreatePanel("Panel", has_player_child, "player_icon" + pid);
    hero_icon.AddClass("hero_icon")
    hero_icon.backgroundSize = "100%"

    if (pid == Game.GetLocalPlayerID()) 
    {
        hero_icon.AddClass("player_portrait_local")
    }
    else if (Players.GetTeam(Number(pid)) == Players.GetTeam(Game.GetLocalPlayerID()))
    {
        hero_icon.AddClass("player_portrait_local_team")
    }

    let player_portrait_text = $.CreatePanel("Label", has_player_child, "nicname" + pid);
    player_portrait_text.text = Players.GetPlayerName(parseInt(pid))
    player_portrait_text.AddClass("player_portrait_text")
}

function pick_start() 
{
	var lobby_heroes = $.GetContextPanel().FindChildTraverse("lobby_players")
	var player_list = Game.GetCustomTable("custom_pick", "player_lobby");

	if (player_list) {
		const players = Object.entries(player_list.lobby_players).map(([pid, data]) => [pid, data.pick_order]).sort((a, b) => a[1] - b[1])
		for (const [pid, i] of players) 
        {
			let has_player_child = lobby_heroes.FindChildTraverse( "player" + pid)
			if (!has_player_child)
			{
				CreatePlayerPanel(lobby_heroes, pid)
			}
		}
	}
}

function UpdatePlayersOrdersList()
{
    var lobby_heroes = $.GetContextPanel().FindChildTraverse("lobby_players")
    lobby_heroes.RemoveAndDeleteChildren()
	var player_list = Game.GetCustomTable("custom_pick", "player_lobby");

	if (player_list) 
    {
		const players = Object.entries(player_list.lobby_players).map(([pid, data]) => [pid, data.pick_order]).sort((a, b) => a[1] - b[1])
		for (const [pid, i] of players) 
        {
			let has_player_child = lobby_heroes.FindChildTraverse( "player" + pid)
			if (!has_player_child)
			{
				CreatePlayerPanel(lobby_heroes, pid)
			}
		}
	}
}

function ShowHero(panel, hero) 
{
	panel.SetPanelEvent('onmouseover', function() 
	{
		$.CreatePanel("DOTAScenePanel", $.GetContextPanel(), 'portrait_' + hero, {
			class: "hero_portrait_hover",
			unit: hero,
			particleonly: "false",
			drawbackground: false,
			hittest: "false"
		});

		var m = Game.GetScreenHeight() / 1080
		var pos = panel.GetPositionWithinWindow()
		var portrait_panel = $.GetContextPanel().FindChild('portrait_' + hero)
		portrait_panel.SetPositionInPixels(pos.x / m, pos.y / m, 0)
	});

	panel.SetPanelEvent('onmouseout', function() {
		var movie = $.GetContextPanel().FindChild('portrait_' + hero + '')
		if (movie) {
			movie.DeleteAsync(0)
		}
	})
}

var ACTIVE_HERO_TAB = "default"
var HERO_LIST_INIT = false

function SelectHeroTab(tab)
{
	if (ACTIVE_HERO_TAB == tab) return
	ACTIVE_HERO_TAB = tab
	Game.EmitSound("ui_topmenu_select")
	$("#HeroTabDefault").SetHasClass("HeroTabSelected", tab == "default")
	$("#HeroTabCustom").SetHasClass("HeroTabSelected", tab == "custom")
	HERO_LIST_INIT = false
	pick_load_heroes()
}

function pick_load_heroes() 
{
    if (HERO_LIST_INIT) { return }
    HERO_LIST_INIT = true

	var is_custom = ACTIVE_HERO_TAB == "custom"
	var hero_list = Game.GetCustomTable("custom_pick", is_custom ? "custom_hero_list" : "hero_list");

	$("#InfoStr").style.visibility = is_custom ? "collapse" : "visible"
	$("#InfoAgi").style.visibility = is_custom ? "collapse" : "visible"
	$("#InfoInt").style.visibility = is_custom ? "collapse" : "visible"
	$("#InfoAll").style.visibility = is_custom ? "collapse" : "visible"
	$("#InfoCustom").style.visibility = is_custom ? "visible" : "collapse"

	if (is_custom)
	{
		$("#CustomHeroSelector").RemoveAndDeleteChildren()
	}
	else
	{
		$("#StrengthSelector").RemoveAndDeleteChildren()
		$("#AgilitySelector").RemoveAndDeleteChildren()
		$("#IntellectSelector").RemoveAndDeleteChildren()
		$("#AllSelector").RemoveAndDeleteChildren()
	}

	if (hero_list === undefined || hero_list === null)
		return

	const hero_names_sorted = [...Object.keys(hero_list)].sort()
	for (const hero_name of hero_names_sorted) {
		const attribute = hero_list[hero_name]
		let selector, attribute_name
		if (is_custom)
		{
			selector = $("#CustomHeroSelector")
			attribute_name = "all"
		}
		else
		{
			switch (attribute) {
				case 0:
					selector = $("#StrengthSelector")
					attribute_name = "str"
					break
				case 1:
					selector = $("#AgilitySelector")
					attribute_name = "agi"
					break
				case 2:
					selector = $("#IntellectSelector")
					attribute_name = "int"
					break
				case 3:
					selector = $("#AllSelector")
					attribute_name = "all"
					break
				default:
					continue
			}
		}
		var hero_creating = selector.FindChild(hero_name)
		if (hero_creating)
			continue
		var panel = $.CreatePanel("Panel", selector, hero_name)
		panel.AddClass("hero_select_panel")
		SetPSelectEvent(panel, hero_name, attribute_name)

		var port
		if (is_custom)
		{
			port = $.CreatePanel("Panel", panel, 'hero_portrait')
			port.AddClass("hero_portrait")
			// s2r:// + vtex (скомпилированный *_png.vtex_c): file://{images}/<hero>.png не находит
			// портрет кастомного героя в game-папке (см. Failed loading resource ..._png.vtex_c)
			port.style.backgroundImage = HeroPortraitUrl(hero_name)
			port.style.backgroundSize = "cover"
			port.style.backgroundPosition = "50% 50%"
		}
		else
		{
			port = $.CreatePanel("DOTAHeroImage", panel, 'hero_portrait', {
				heroname: hero_name,
				heroimagestyle: "portrait",
				scaling: "stretch-to-cover-preserve-aspect"
			})
		}

        let banned_overlay = $.CreatePanel("Panel", port, "")
        banned_overlay.AddClass("banned_overlay")

		var level_container = $.CreatePanel("Panel", port, "")
		level_container.AddClass("level_container")

		if (!is_custom)
		{
			panel.BLoadLayoutSnippet('hero_portrait')
		}

		ShowHero(panel, hero_name)
	}
}

function reload_pick_heroes(data) 
{
	const lobby_players = data.lobby_players || {}
	for (let pid of Object.keys(lobby_players)) 
    {
		let player_info = lobby_players[pid]
		if (!player_info || !player_info.picked_hero) continue
		let icon = $.GetContextPanel().FindChildTraverse(String(player_info.picked_hero))
		if (icon) 
        {
			icon.AddClass("hero_picked")
		}
		let left_hero = $.GetContextPanel().FindChildTraverse("player_icon" + String(pid))
		if (left_hero) 
        {
			left_hero.style.backgroundImage = HeroPortraitUrl(String(player_info.picked_hero))
			left_hero.style.backgroundSize = 'contain'
		}
	}
    let hero_list = Game.GetCustomTable("custom_pick", "player_list");
    if (hero_list && hero_list.banned_heroes)
    {
        for (let i = 1; i <= Object.keys(hero_list.banned_heroes).length; i++) 
        {
            if (hero_list.banned_heroes[i]) 
            {
                let icon = $.GetContextPanel().FindChildTraverse(String(hero_list.banned_heroes[i]))
                if (icon)
                {
                    icon.AddClass("hero_banned")
                }
            }
        }
    }
}

function ban_client_hero(data)
{
    let icon = $.GetContextPanel().FindChildTraverse(String(data.hero_name))
    if (icon) 
    {
		icon.AddClass("hero_banned")
	}

    var left_hero = $.GetContextPanel().FindChildTraverse("player_icon" + String(data.player_id))
	if (left_hero) 
	{
		left_hero.style.backgroundImage = HeroPortraitUrl(String(data.hero_name))
		left_hero.style.backgroundSize = 'contain'
        left_hero.AddClass("hero_banned")
	}
	Refresh_Ban_Button()
}

function ban_client_hero_reload()
{
    let lobby_players = $("#lobby_players")
    for (let child of lobby_players.Children())
    {
        let icon = child.GetChild(0)
        icon.style.backgroundImage = "url('')"
    }
}

function pick_select_hero(data) 
{
	var icon = $.GetContextPanel().FindChildTraverse(String(data.hero))

	if (icon) {
		icon.AddClass("hero_picked")
	}

	if (Game.GetLocalPlayerID() == data.id) 
	{
		Game.EmitSound("UI.Pick_Hero");
	}

	Game.EmitSound("UI.Pick_" + String(data.hero));

	var left_hero = $.GetContextPanel().FindChildTraverse("player_icon" + String(data.id))
	if (left_hero) 
	{
        left_hero.RemoveClass("hero_banned")
		left_hero.style.backgroundImage = HeroPortraitUrl(String(data.hero))
		left_hero.style.backgroundSize = 'contain'
	}
}

// helper: скомпилированный портрет героя (s2r:// + vtex работает и для кастомных героев)
function HeroPortraitUrl(hero)
{
	return 'url("s2r://panorama/images/heroes/' + hero + '_png.vtex")'
}

function SetPSelectEvent(panel, hero, attribute) 
{
	panel.SetPanelEvent("onactivate", function() {
		ChangeHeroInfo(hero, attribute);
	});
}

function Refresh_Random_Button() {

	var RandomHero_button = $.GetContextPanel().FindChildTraverse("SelectRandomHero")

	RandomHero_button.SetPanelEvent("onactivate", function() {});
	RandomHero_button.RemoveClass("SelectRandomHero_picked")
	RandomHero_button.RemoveClass("SelectRandomHero_visible")
	RandomHero_button.AddClass("SelectRandomHero_hidden")

	if (HasHero())
	{
		RandomHero_button.RemoveClass("SelectRandomHero_visible")
		RandomHero_button.RemoveClass("SelectRandomHero_hidden")
		RandomHero_button.AddClass("SelectRandomHero_picked")
		RandomHero_button.SetPanelEvent("onactivate", function() {});
		return
	}

	var active_player = Game.GetCustomTable("custom_pick", "active_player");
	if (active_player)
	{
		if (active_player.id !== Game.GetLocalPlayerID()) {
			return
		}
		if (active_player.is_ban == 1) {
			return
		}
	}


	RandomHero_button.RemoveClass("SelectRandomHero_picked")
	RandomHero_button.RemoveClass("SelectRandomHero_hidden")
	RandomHero_button.AddClass("SelectRandomHero_visible")
	RandomHero_button.SetPanelEvent("onactivate", function() {
		RandomHero();
	});
}

function Refresh_Button() 
{
	var ChoseHero = $.GetContextPanel().FindChildTraverse("ChoseHero")
	var hero_list = Game.GetCustomTable("custom_pick", "player_list");
	ChoseHero.RemoveClass("ChoseHero_visible")
	ChoseHero.RemoveClass("ChoseHero_picked")
	ChoseHero.AddClass("ChoseHero")
	ChoseHero.style.visibility = "visible"
	if (HasHero())
	{
		ChoseHero.RemoveClass("ChoseHero")
		ChoseHero.AddClass("ChoseHero_picked")
		ChoseHero.SetPanelEvent("onactivate", function() {});
		return
	} 

	var active_player = Game.GetCustomTable("custom_pick", "active_player");
	if (!active_player || active_player.id !== Game.GetLocalPlayerID()) 
	{
		return
	}  
	if (active_player.is_ban == 1) 
	{
		// ban phase: collapse the pick button so BanHero (in flow) takes its place
		ChoseHero.style.visibility = "collapse"
		return
	}  

	if (hero_list) 
    {
        if (hero_list.picked_heroes)
        {
            for (var i = 1; i <= Object.keys(hero_list.picked_heroes).length; i++) 
            {
                if (hero_list.picked_heroes[i] == hero_selected) 
                {
                    ChoseHero.RemoveClass("ChoseHero")
                    ChoseHero.AddClass("ChoseHero_picked")
                    ChoseHero.SetPanelEvent("onactivate", function() {});
                    return
                }
            }
        }
        if (hero_list.banned_heroes)
        {
            for (var i = 1; i <= Object.keys(hero_list.banned_heroes).length; i++) 
            {
                if (hero_list.banned_heroes[i] == hero_selected) 
                {
                    ChoseHero.RemoveClass("ChoseHero")
                    ChoseHero.AddClass("ChoseHero_picked")
                    ChoseHero.SetPanelEvent("onactivate", function() {});
                    return
                }
            }
        }
	}

	ChoseHero.RemoveClass("ChoseHero_picked")
	ChoseHero.RemoveClass("ChoseHero")
	ChoseHero.AddClass("ChoseHero_visible")
	ChoseHero.SetPanelEvent("onactivate", function() {
		Game.EmitSound("ui.pick_select")
		GameEvents.SendCustomGameEventToServer("chose_hero", 
		{
			hero: hero_selected,
			
		});
		Refresh_Button()
		Refresh_Random_Button()
	});
}

function ChangeHeroInfo(hero_name, attribute) 
{
	var active_player = Game.GetCustomTable("custom_pick", "active_player");

	if (active_player == null) 
	{
		return
	}

	var is_ban_phase = active_player.is_ban == 1

	if (is_ban_phase && active_player.is_ban_stage && active_player.id != Game.GetLocalPlayerID())
	{
		// ban interlude or not my turn — ignore clicks
		return
	}

	Game.EmitSound("UI.Click_Hero")

	if (is_ban_phase)
	{
		// ban phase: select the hero for banning (Ban button confirms), no instant ban
		ShowHeroPreview(hero_name)
		return
	}

	ShowHeroPreview(hero_name)
}

function ShowHeroPreview(hero_name)
{
	hero_selected = hero_name

	var InfoText = $.GetContextPanel().FindChildTraverse("InfoText")
	InfoText.text = $.Localize('#' + hero_name)

	var HeroContainerModel = $.GetContextPanel().FindChildTraverse("HeroContainerModel")
	HeroContainerModel.RemoveAndDeleteChildren()
	var custom_list = Game.GetCustomTable("custom_pick", "custom_hero_list")
	if (custom_list && custom_list[hero_name] !== undefined) {
		// custom heroes (e.g. Stegius): the client scene system cannot render custom-named heroes
		// (unit:/HeroMovie/map variants all fail on this engine) — show the 2D portrait instead
		var port = $.CreatePanel("Panel", HeroContainerModel, "hero_model")
		port.style.width = "100%"
		port.style.height = "100%"
		port.style.backgroundImage = HeroPortraitUrl(hero_name)
		port.style.backgroundSize = "cover"
		port.style.backgroundPosition = "50% 50%"
	} else {
		$.CreatePanel("DOTAScenePanel", HeroContainerModel, "hero_model", { style: "width:100%;height:100%;", drawbackground: false, unit: hero_name, particleonly:"false", antialias:"false",allowrotation:"true" });
	}

	var HeroContainerAbilities = $.GetContextPanel().FindChildTraverse("HeroContainerAbilities")
	HeroContainerAbilities.RemoveAndDeleteChildren()
	var abilities = GetHeroAbility(hero_name);
	$.Msg("[PICK] abilities for " + hero_name + ": " + JSON.stringify(abilities))
    var abilities_pick = 0;
    let innate_ability = GetInnateAbility(hero_name)
    if (innate_ability)
    {
        let ability_panel = $.CreatePanel('Panel', HeroContainerAbilities, "");
        ability_panel.AddClass('HeroInfoAbilty');
        ability_panel.AddClass('UseInnateIcon');
        SetShowInnateDesc(ability_panel, hero_name)
    }
    var ability_keys = Object.keys(abilities || {});
    for (var i = 0; i < ability_keys.length; i++)
    {
        abilities_pick++;
        var ability_name = abilities[ability_keys[i]];
        if (!ability_name) { continue; }
        var ability_panel = $.CreatePanel('DOTAAbilityImage', HeroContainerAbilities, 'ability_' + abilities_pick, { class: 'HeroInfoAbilty', abilityname: ability_name });
        ability_panel.abilityname = ability_name;
        SetShowAbDesc(ability_panel, ability_name);
    }
	$.Msg("[PICK] " + hero_name + " ability panels: " + abilities_pick)
	Refresh_Button()
	Refresh_Random_Button()
	Refresh_Ban_Button()
}

function change_random(params)
{
	ShowHeroPreview(params.hero)
}

function Refresh_Ban_Button() 
{
	var BanHero = $.GetContextPanel().FindChildTraverse("BanHero")
	if (!BanHero) return

	BanHero.SetPanelEvent("onactivate", function() {});
	BanHero.RemoveClass("BanHero_visible")
	BanHero.AddClass("BanHero_hidden")

	var active_player = Game.GetCustomTable("custom_pick", "active_player");
	if (!active_player || active_player.is_ban != 1) return
	if (active_player.id !== Game.GetLocalPlayerID()) return
	if (hero_selected === '') return

	// the selected hero is already banned or picked — nothing to ban
	var hero_list = Game.GetCustomTable("custom_pick", "player_list");
	if (hero_list)
	{
		if (hero_list.banned_heroes)
		{
			for (var i = 1; i <= Object.keys(hero_list.banned_heroes).length; i++)
			{
				if (hero_list.banned_heroes[i] == hero_selected) return
			}
		}
		if (hero_list.picked_heroes)
		{
			for (var j = 1; j <= Object.keys(hero_list.picked_heroes).length; j++)
			{
				if (hero_list.picked_heroes[j] == hero_selected) return
			}
		}
	}

	BanHero.RemoveClass("BanHero_hidden")
	BanHero.AddClass("BanHero_visible")
	BanHero.SetPanelEvent("onactivate", function() {
		Game.EmitSound("ui.pick_select")
		GameEvents.SendCustomGameEventToServer("select_ban_hero", {hero: hero_selected});
		Refresh_Ban_Button()
	});
}

function SetShowInnateDesc(panel, ability)
{
    panel.SetPanelEvent('onmouseover', function() {
        if (heroesId[ability] != null) {
            $.DispatchEvent('DOTAShowInnateTooltip', panel, heroesId[ability], 0);
        }
    });
        
    panel.SetPanelEvent('onmouseout', function() {
        $.DispatchEvent('DOTAHideInnateTooltip', panel);
    });       
}

function SetShowAbDesc(panel, ability)
{
    panel.SetPanelEvent('onmouseover', function() {
        $.DispatchEvent('DOTAShowAbilityTooltip', panel, ability); });
        
    panel.SetPanelEvent('onmouseout', function() {
        $.DispatchEvent('DOTAHideAbilityTooltip', panel);
    });       
}

function GetHeroAbility(hn) 
{
    var ab = Game.GetCustomTable("custom_pick", hn);
    if (ab)
    {
        return ab;
    } 
    return [];
}

function GetInnateAbility(hn) 
{
    var ab = Game.GetCustomTable("custom_pick", hn+"_innate");
    if (ab)
    {
        return ab;
    } 
    return null;
}

function GetHeroModel(hn) 
{
    var model = Game.GetCustomTable("custom_pick", hn+"_model");
    if (model)
    {
        return model;
    } 
    return null;
}

function MouseOver(panel, text) 
{
    panel.SetPanelEvent('onmouseover', function() {
        $.DispatchEvent('DOTAShowTextTooltip', panel, text)
    });
    panel.SetPanelEvent('onmouseout', function() {
        $.DispatchEvent('DOTAHideTextTooltip', panel);
    });
}

function HasHero()
{
	let table = Game.GetCustomTable("custom_pick", "player_current_hero"+Players.GetLocalPlayer())
	if (table && table.picked == 1)
	{
		return true
	}
	return false
}

function change_color_timer(data)
{
    let is_red_color = false
    if (data.is_ban)
    {
        is_red_color = true
    }
    $("#pick_timer_panel_main").SetHasClass("is_red_color", is_red_color)

	var PhaseLabel = $("#PhaseLabel")
	if (PhaseLabel)
	{
		PhaseLabel.visible = is_red_color
	}
	Refresh_Ban_Button()
}

MouseOver($("#SelectRandomHero"),$.Localize("#random_button"))

init()

// Safety net: render the grid as soon as the hero tables arrive, even if the
// initial Player_Loaded() ran before the custom tables were delivered.
if (Game.SubscribeCustomTableListener)
{
	Game.SubscribeCustomTableListener("custom_pick", "hero_list", function()
	{
		if (!HERO_LIST_INIT && ACTIVE_HERO_TAB == "default")
		{
			HERO_LIST_INIT = false
			pick_load_heroes()
			pick_start()
		}
	});
	Game.SubscribeCustomTableListener("custom_pick", "custom_hero_list", function()
	{
		if (!HERO_LIST_INIT && ACTIVE_HERO_TAB == "custom")
		{
			HERO_LIST_INIT = false
			pick_load_heroes()
		}
	});
}

Player_Loaded()
