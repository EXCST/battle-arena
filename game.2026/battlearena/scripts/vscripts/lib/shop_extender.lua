ShopExtender = ShopExtender or class({})

-- Р Р°СЃРєР»Р°РґРєР° РјР°РіР°Р·РёРЅР° РІ СЃС‚РёР»Рµ РєР»Р°СЃСЃРёС‡РµСЃРєРѕРіРѕ РјР°РіР°Р·РёРЅР° Dota 2:
--   РћСЃРЅРѕРІРЅС‹Рµ:    Р Р°СЃС…РѕРґРЅРёРєРё / РЎРЅР°СЂСЏР¶РµРЅРёРµ / РђС‚СЂРёР±СѓС‚С‹ / Р Р°Р·РЅРѕРµ  (РїРѕС‚Р°Р№РЅРѕР№ Р»Р°РІРєРё РЅРµС‚ вЂ” РµС‘ РїСЂРµРґРјРµС‚С‹ СЂР°СЃРєРёРґР°РЅС‹)
--   РЈР»СѓС‡С€РµРЅРёСЏ:   РђРєСЃРµСЃСЃСѓР°СЂС‹ / РњР°РіРёСЏ / РћСЂСѓР¶РёРµ / РџРѕРґРґРµСЂР¶РєР° / Р‘СЂРѕРЅСЏ / Р’РѕРѕСЂСѓР¶РµРЅРёРµ
--   РљР°СЃС‚РѕРјРЅС‹Рµ:   РђРєСЃРµСЃСЃСѓР°СЂС‹ / РњР°РіРёСЏ / РћСЂСѓР¶РёРµ / РџРѕРґРґРµСЂР¶РєР° / Р‘СЂРѕРЅСЏ / РџСЂРѕС‡РµРµ
--   Р‘РѕСЃСЃС‹:       РЎС‚СЂР°Р¶ Рё РјРѕРЅР°С…Рё / РђРЅРіРµР»С‹ / РЎР°С‚Р°РЅР° / Р‘РµР·СѓРјРЅС‹Р№

SHOP_TABS = {
	MainItemsTab = {
		category_order = { "Consumables", "Equipment", "Attributes", "Misc" },
		categories = {
			Consumables = {
				"item_tango", "item_tango_single", "item_tpscroll", "item_clarity", "item_flask", "item_faerie_fire",
				"item_enchanted_mango", "item_moon_shard", "item_dust", "item_smoke_of_deceit",
				"item_ward_observer", "item_ward_sentry", "item_blood_grenade", "item_infused_raindrop", "item_bottle",
			},
			Equipment = {
				"item_quelling_blade", "item_ring_of_protection", "item_blades_of_attack", "item_gloves",
				"item_chainmail", "item_broadsword", "item_blight_stone", "item_blitz_knuckles",
				"item_orb_of_venom", "item_helm_of_iron_will",
				"item_stout_shield", "item_quarterstaff",
				-- РёР· РїРѕС‚Р°Р№РЅРѕР№ Р»Р°РІРєРё
				"item_platemail", "item_talisman_of_evasion", "item_point_booster", "item_energy_booster", "item_vitality_booster",
			},
			Attributes = {
				"item_branches", "item_gauntlets", "item_slippers", "item_mantle", "item_circlet",
				"item_belt_of_strength", "item_boots_of_elves", "item_robe", "item_crown", "item_ogre_axe",
				"item_blade_of_alacrity", "item_staff_of_wizardry",
				-- РёР· РїРѕС‚Р°Р№РЅРѕР№ Р»Р°РІРєРё
				"item_ultimate_orb", "item_mystic_staff", "item_reaver", "item_eagle", "item_demon_edge",
				"item_relic", "item_hyperstone",
			},
			Misc = {
				"item_ring_of_regen", "item_sobi_mask", "item_wind_lace", "item_magic_stick", "item_fluffy_hat",
				"item_boots", "item_gem", "item_cloak", "item_voodoo_mask", "item_lifesteal",
				"item_shadow_amulet", "item_blink", "item_ghost",
				-- РёР· РїРѕС‚Р°Р№РЅРѕР№ Р»Р°РІРєРё
				"item_ring_of_health", "item_ring_of_tarrasque", "item_void_stone", "item_tiara_of_selemene",
			},
		},
	},
	UpgradesItemsTab = {
		category_order = { "Accessories", "Magic", "Weapons", "Support", "Armor", "Armaments" },
		categories = {
			Accessories = {
				"item_magic_wand", "item_bracer", "item_wraith_band", "item_null_talisman", "item_power_treads",
				"item_phase_boots", "item_travel_boots", "item_travel_boots_2", "item_soul_ring", "item_urn_of_shadows",
				"item_tranquil_boots", "item_arcane_boots", "item_hand_of_midas", "item_phylactery",
				"item_falcon_blade", "item_orb_of_corrosion",
			},
			Magic = {
				"item_dagon", "item_dagon_2", "item_dagon_3", "item_dagon_4", "item_dagon_5",
				"item_sheepstick", "item_orchid", "item_cyclone",
				"item_bloodthorn", "item_gungir", "item_octarine_core", "item_refresher", "item_wind_waker",
				"item_rod_of_atos", "item_aether_lens", "item_meteor_hammer", "item_veil_of_discord",
				"item_force_staff", "item_ultimate_scepter", "item_witch_blade", "item_bloodstone",
			},
			Weapons = {
				"item_bfury", "item_monkey_king_bar", "item_desolator", "item_basher",
				"item_abyssal_blade", "item_mjollnir", "item_rapier", "item_butterfly", "item_satanic",
				"item_greater_crit", "item_lesser_crit", "item_mage_slayer", "item_heavens_halberd",
				"item_maelstrom", "item_invis_sword", "item_silver_edge", "item_nullifier",
				"item_revenants_brooch", "item_mask_of_madness", "item_harpoon", "item_hurricane_pike",
			},
			Support = {
				"item_mekansm", "item_pipe", "item_guardian_greaves", "item_solar_crest", "item_glimmer_cape",
				"item_spirit_vessel", "item_pavise", "item_holy_locket", "item_vladmir", "item_ring_of_basilius",
				"item_headdress", "item_buckler", "item_ancient_janggo", "item_boots_of_bearing", "item_wraith_pact",
			},
			Armor = {
				"item_vanguard", "item_blade_mail", "item_hood_of_defiance", "item_crimson_guard", "item_assault",
				"item_shivas_guard", "item_heart", "item_lotus_orb", "item_aeon_disk", "item_eternal_shroud",
				"item_sphere", "item_armlet", "item_black_king_bar", "item_helm_of_the_dominator", "item_helm_of_the_overlord",
			},
			Armaments = {
				"item_sange_and_yasha", "item_yasha_and_kaya", "item_kaya_and_sange", "item_manta", "item_skadi",
				"item_diffusal_blade", "item_disperser", "item_echo_sabre",
				"item_overwhelming_blink", "item_swift_blink", "item_arcane_blink",
			},
		},
	},
	CustomUpgrades = {
		category_order = { "Accessories", "Magic", "Weapons", "Support", "Armor", "Other" },
		categories = {
			Accessories = {
				"item_advanced_midas", "item_chest_of_midas", "item_edible_gem",
				"item_knight_talisman", "item_phase_boots_2", "item_phase_boots_3",
				"item_pipe_2", "item_pipe_3", "item_power_amulet", "item_power_treads_2",
				"item_power_treads_3", "item_talisman_of_mastery",
			},
			Magic = {
				"item_cursed_orb", "item_damned_eye", "item_dimensional_accelerator",
				"item_dimensional_predictor", "item_doombolt",
				"item_mystic_amulet", "item_plague_staff", "item_rubick_dagon", "item_slice_amulet",
				"item_soul_stone", "item_soul_vessel", "item_strange_amulet",
				"item_veil_of_discord_2", "item_veil_of_discord_3",
			},
			Weapons = {
				"item_abyssal_blade_2", "item_angels_desolators", "item_bandoline_blade",
				"item_bfury_2", "item_charon",
				"item_diffusal_blade_2", "item_diffusal_blade_3", "item_harpoon_2",
				"item_harpoon_3", "item_heavy_crossbow", "item_heavens_halberd_2",
				"item_manta_2", "item_manta_3", "item_mjollnir_2", "item_polar_spear",
				"item_radiance_3", "item_rapier_2", "item_sacred_butterfly",
				"item_storm_edge", "item_vampire_claw",
			},
			Support = {
				"item_health_gel", "item_holy_book", "item_holy_book_2", "item_life_catcher",
				"item_potion_immune", "item_soul_merchant",
				"item_tome_agi_3", "item_tome_agi_6", "item_tome_int_3", "item_tome_int_6",
				"item_tome_str_3", "item_tome_str_6", "item_tome_un_3", "item_tome_un_6",
				"item_tome_lvlup", "item_tome_med", "item_repick",
			},
			Armor = {
				"item_amaliels_cuirass", "item_armlet_2", "item_armlet_3", "item_crimson_guard_2",
				"item_death_shield", "item_devour_helm", "item_fury_shield", "item_heart_2",
				"item_hood_of_rage", "item_shivas_guard_2", "item_sphere_2", "item_steel_frame",
			},
			Other = {
				"item_pet_hulk", "item_pet_mage", "item_pet_wolf",
			},
		},
	},
	BossItemsTab = {
		category_order = { "GuardianMonks", "Angels", "Satan", "Crazy" },
		categories = {
			GuardianMonks = {
				-- РґСЂРѕРї СЃС‚СЂР°Р¶Р° Рё РјРѕРЅР°С…РѕРІ
				"item_cursed_sange", "item_saint_yasha", "item_dead_boots",
				"item_angels_blood", "item_angels_sword", "item_blessed_essence",
				-- СЃРѕР±СЂР°РЅРЅС‹Рµ РёР· Р±РѕСЃСЃРѕРІС‹С… РєРѕРјРїРѕРЅРµРЅС‚РѕРІ
				"item_angels_greaves", "item_angels_shard", "item_azrael_crossbow",
				"item_burning_blades", "item_burning_book", "item_burning_butterfly",
				"item_damned_swords", "item_demons_fury", "item_ethereal_blade_4",
				"item_lightning_flash", "item_magic_amplifier", "item_material_projector",
				"item_mozaius_blade", "item_octarine_core_2", "item_pipe_4",
				"item_rebels_sword", "item_rebels_sword_2", "item_recovery_orb",
				"item_reverse", "item_snake_boots", "item_soul_collector",
				"item_static_amulet", "item_veil_of_discord_4",
			},
			Angels = {
				-- РґСЂРѕРї Р°РЅРіРµР»РѕРІ
				"item_tome_agi_60", "item_tome_int_60", "item_tome_str_60", "item_tome_un_60",
				"item_icarus", "item_angels_armor", "item_awful_mask",
				-- СЃРѕР±СЂР°РЅРЅС‹Рµ РёР· Р±РѕСЃСЃРѕРІС‹С… РєРѕРјРїРѕРЅРµРЅС‚РѕРІ
				"item_deaths_mask", "item_double_crit", "item_spiked_armor",
			},
			Satan = {
				-- РґСЂРѕРї СЃР°С‚Р°РЅС‹
				"item_possessed_sword", "item_eclipse_amphora",
				-- СЃРѕР±СЂР°РЅРЅС‹Рµ РёР· Р±РѕСЃСЃРѕРІС‹С… РєРѕРјРїРѕРЅРµРЅС‚РѕРІ
				"item_kings_bar",
			},
			Crazy = {
				-- РґСЂРѕРї Р±РµР·СѓРјРЅРѕРіРѕ
				"item_skadi_2", "item_aegis_aa",
				-- СЃРѕР±СЂР°РЅРЅС‹Рµ РёР· Р±РѕСЃСЃРѕРІС‹С… РєРѕРјРїРѕРЅРµРЅС‚РѕРІ
				"item_dark_edge",
			},
		},
	},
}

SHOP_TAB_ORDER = { "MainItemsTab", "UpgradesItemsTab", "CustomUpgrades", "BossItemsTab" }

-- РїСЂРµРґРјРµС‚С‹, РєРѕС‚РѕСЂС‹Рµ РЅРµР»СЊР·СЏ РїСЂРѕРґР°РІР°С‚СЊ РІ РјР°РіР°Р·РёРЅРµ
SHOP_EXCLUDED_ITEMS = {
	-- СЂРµС†РµРїС‚С‹
	["item_recipe"] = true,
	-- СЃР»СѓР¶РµР±РЅС‹Рµ
	["item_dummy"] = true,
	["item_pr_cour"] = true,
	["item_pets"] = true,
	["item_lua"] = true,
	["item_datadriven"] = true,
	["item_change_team"] = true,
	["item_team_changer"] = true,
	["item_consumption_orb"] = true,
	-- СѓРґР°Р»С‘РЅРЅС‹Рµ
	["item_talisman_of_ambition"] = true,
	["item_magician_ring"] = true,
	["item_aghanims_shard"] = true,
	["item_kings_bar_old"] = true,
	["item_boss_soul"] = true,
	["item_enigmatic_fire"] = true,
	["item_shard_hola"] = true,
	["item_shard_huntress"] = true,
	["item_shard_joe_black"] = true,
	["item_shard_satan"] = true,
	-- СЃРєСЂС‹С‚С‹Рµ: РѕСЃС‚Р°С‘С‚СЃСЏ С‚РѕР»СЊРєРѕ РјР°РєСЃРёРјР°Р»СЊРЅС‹Р№ СѓСЂРѕРІРµРЅСЊ С†РµРїРѕС‡РєРё
	["item_radiance"] = true,
	["item_radiance_2"] = true,
	["item_ethereal_blade"] = true,
	["item_ethereal_blade_2"] = true,
	["item_ethereal_blade_3"] = true,
	-- РЅРµР№С‚СЂР°Р»СЊРЅС‹Рµ РїСЂРµРґРјРµС‚С‹ (РЅРµ РїСЂРѕРґР°СЋС‚СЃСЏ РІ РјР°РіР°Р·РёРЅРµ)
	["item_ancient_guardian"] = true,
	["item_apex"] = true,
	["item_arcane_ring"] = true,
	["item_ascetic_cap"] = true,
	["item_avianas_feather"] = true,
	["item_ballista"] = true,
	["item_black_powder_bag"] = true,
	["item_book_of_shadows"] = true,
	["item_broom_handle"] = true,
	["item_bullwhip"] = true,
	["item_ceremonial_robe"] = true,
	["item_chipped_vest"] = true,
	["item_cloak_of_flames"] = true,
	["item_craggy_coat"] = true,
	["item_dagger_of_ristul"] = true,
	["item_dandelion_amulet"] = true,
	["item_defiant_shell"] = true,
	["item_demonicon"] = true,
	["item_doubloon"] = true,
	["item_dragon_scale"] = true,
	["item_duelist_gloves"] = true,
	["item_elven_tunic"] = true,
	["item_enchanted_quiver"] = true,
	["item_essence_ring"] = true,
	["item_ex_machina"] = true,
	["item_eye_of_the_vizier"] = true,
	["item_faded_broach"] = true,
	["item_fallen_sky"] = true,
	["item_flicker"] = true,
	["item_force_boots"] = true,
	["item_force_field"] = true,
	["item_giants_ring"] = true,
	["item_gossamer_cape"] = true,
	["item_grove_bow"] = true,
	["item_havoc_hammer"] = true,
	["item_heavy_blade"] = true,
	["item_illusionsts_cape"] = true,
	["item_imp_claw"] = true,
	["item_ironwood_tree"] = true,
	["item_keen_optic"] = true,
	["item_lance_of_pursuit"] = true,
	["item_light_collector"] = true,
	["item_martyrs_plate"] = true,
	["item_medallion_of_courage"] = true,
	["item_mind_breaker"] = true,
	["item_minotaur_horn"] = true,
	["item_mirror_shield"] = true,
	["item_misericorde"] = true,
	["item_mysterious_hat"] = true,
	["item_nemesis_curse"] = true,
	["item_nether_shawl"] = true,
	["item_ninja_gear"] = true,
	["item_occult_bracelet"] = true,
	["item_ocean_heart"] = true,
	["item_ogre_seal_totem"] = true,
	["item_orb_of_destruction"] = true,
	["item_paintball"] = true,
	["item_paladin_sword"] = true,
	["item_penta_edged_sword"] = true,
	["item_philosophers_stone"] = true,
	["item_pirate_hat"] = true,
	["item_pogo_stick"] = true,
	["item_possessed_mask"] = true,
	["item_princes_knife"] = true,
	["item_psychic_headband"] = true,
	["item_pupils_gift"] = true,
	["item_quickening_charm"] = true,
	["item_quicksilver_amulet"] = true,
	["item_rattlecage"] = true,
	["item_ring_of_aquila"] = true,
	["item_royal_jelly"] = true,
	["item_safety_bubble"] = true,
	["item_seeds_of_serenity"] = true,
	["item_seer_stone"] = true,
	["item_spark_of_courage"] = true,
	["item_spell_prism"] = true,
	["item_spider_legs"] = true,
	["item_spy_gadget"] = true,
	["item_stormcrafter"] = true,
	["item_the_leveller"] = true,
	["item_timeless_relic"] = true,
	["item_titan_sliver"] = true,
	["item_trickster_cloak"] = true,
	["item_trusty_shovel"] = true,
	["item_unstable_wand"] = true,
	["item_unwavering_condition"] = true,
	["item_vambrace"] = true,
	["item_vampire_fangs"] = true,
	["item_vindicators_axe"] = true,
	["item_whisper_of_the_dread"] = true,
}

local function is_shop_excluded(item_name)
	if SHOP_EXCLUDED_ITEMS[item_name] then return true end
	if item_name:starts("item_recipe_") then return true end
	if item_name:starts("item_rune_") then return true end
	if item_name:starts("ITEM_") then return true end
	if item_name:ends("_dummy") then return true end
	return false
end


function ShopExtender:Init()
	self.shop_layout_client_data = {}

	local custom_items = LoadKeyValues("scripts/npc/npc_items_custom.txt") or {}
	local custom_root = custom_items.DOTAAbilities or custom_items

	-- РєР°СЃС‚РѕРјРЅС‹Рµ РїСЂРµРґРјРµС‚С‹ Р°РґРґРѕРЅР° (СЃ ID РІ KV)
	local custom_set = {}
	local items_kv = {}
	for name, kv in pairs(custom_root) do
		if type(kv) == "table" then
			items_kv[name] = kv
			if kv.ID then custom_set[name] = true end
		end
	end

	local function get_item_kv(item_name)
		local kv = items_kv[item_name]
		if kv then return kv end
		local by_name = GetAbilityKeyValuesByName(item_name)
		if type(by_name) == "table" then return by_name end
		return nil
	end

	local function get_item_id(item_name)
		local kv = get_item_kv(item_name)
		if kv and kv.ID then return kv.ID end
		local by_name = GetAbilityKeyValuesByName(item_name)
		if type(by_name) == "table" and by_name.ID then return by_name.ID end
		return nil
	end

	local function get_item_cost(item_name)
		local kv = get_item_kv(item_name)
		if kv and kv.ItemCost then return tonumber(kv.ItemCost) or 0 end
		return 0
	end

	local function make_client_tab(tab_name)
		local tab_cfg = SHOP_TABS[tab_name]
		local client_tab = { sort_weight = 0, categories = {} }

		for cat_weight, cat_name in ipairs(tab_cfg.category_order) do
			local item_names = tab_cfg.categories[cat_name] or {}
			local category = { items = {}, sort_weight = cat_weight }

			local entries = {}
			for _, item_name in ipairs(item_names) do
				if not is_shop_excluded(item_name) then
					local id = get_item_id(item_name)
					if id then
						local cost = get_item_cost(item_name)
						table.insert(entries, { name = item_name, id = id, cost = cost })
					end
				end
			end
			table.sort(entries, function(a, b)
				if a.cost ~= b.cost then return a.cost < b.cost end
				return a.name < b.name
			end)

			for idx, entry in ipairs(entries) do
				category.items[entry.name] = { id = entry.id, cost = entry.cost, sort_weight = idx }
			end
			client_tab.categories[cat_name] = category
		end

		return client_tab
	end

	-- РљР°СЃС‚РѕРјРЅС‹Рµ РїСЂРµРґРјРµС‚С‹: РІСЃС‘ РёР· custom_set, С‡РµРіРѕ РЅРµС‚ РІ РІР°РЅРёР»СЊРЅС‹С… РІРєР»Р°РґРєР°С…,
	-- РЅРµ РІС‹РїР°РґР°РµС‚ СЃ Р±РѕСЃСЃРѕРІ Рё РЅРµ РёСЃРєР»СЋС‡РµРЅРѕ РёР· РјР°РіР°Р·РёРЅР°.
	local classified_vanilla = {}
	for _, tab_name in ipairs({ "MainItemsTab", "UpgradesItemsTab" }) do
		for _, cat_list in pairs(SHOP_TABS[tab_name].categories) do
			for _, item_name in ipairs(cat_list) do
				classified_vanilla[item_name] = true
			end
		end
	end
	local classified_custom = {}
	for _, cat_list in pairs(SHOP_TABS.CustomUpgrades.categories) do
		for _, item_name in ipairs(cat_list) do
			classified_custom[item_name] = true
		end
	end
	local custom_other = {}
	for item_name in pairs(custom_set) do
		if not is_shop_excluded(item_name)
			and not classified_vanilla[item_name]
			and not classified_custom[item_name]
			and not self:IsBossItem(item_name) then
			custom_other[item_name] = true
		end
	end
	if next(custom_other) then
		local names = {}
		for n in pairs(custom_other) do table.insert(names, n) end
		table.sort(names)
		print("[ShopExtender] unclassified custom items -> Other: " .. table.concat(names, ", "))
		for _, item_name in ipairs(names) do
			table.insert(SHOP_TABS.CustomUpgrades.categories.Other, item_name)
		end
	end

	for tab_weight, tab_name in ipairs(SHOP_TAB_ORDER) do
		local client_tab = make_client_tab(tab_name)
		client_tab.sort_weight = tab_weight
		self.shop_layout_client_data[tab_name] = client_tab
	end

	CustomGameEventManager:RegisterListener("ShopExtender:get", function(player_id, event)
		print("[ShopExtender] get received player=" .. tostring(player_id))
		ShopExtender:UpdateClient(player_id)
	end)

	for name, client_tab in pairs(self.shop_layout_client_data) do
		local total = 0
		local cats = {}
		for cat, category in pairs(client_tab.categories) do
			total = total + table.count(category.items)
			table.insert(cats, cat .. ":" .. table.count(category.items))
		end
		table.sort(cats)
		print("[ShopExtender] tab " .. name .. " = " .. total .. " [" .. table.concat(cats, ", ") .. "]")
	end
end


function ShopExtender:IsBossItem(item_name)
	for _, cat_list in pairs(SHOP_TABS.BossItemsTab.categories) do
		for _, name in ipairs(cat_list) do
			if name == item_name then return true end
		end
	end
	return false
end


function ShopExtender:UpdateClient(player_id)
	print("[ShopExtender] broadcast to all clients")
	CustomGameEventManager:Send_ServerToAllClients("ShopExtender:update", self.shop_layout_client_data)
end


ShopExtender:Init()