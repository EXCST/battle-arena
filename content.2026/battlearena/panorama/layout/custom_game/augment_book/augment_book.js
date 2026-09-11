const HUD = {
	CONTEXT: $.GetContextPanel(),
	AB_BUTTONS: $("#AB_List"),
	AB_LISTS: $("#AB_Buttons"),
	BOOK_LISTS: $("#AugBook_Lists"),
	BOOK_BUTTON: $("#AugBookBtn"),
	BOOK: $("#AugBook"),
};

let OVERRIDE_BUTTON;
let OVERRIDE_PLAYER_ID;
let UPDATE_POS_TOGGLER = false;

const TIER_NAMES = {
	1: "common",
	2: "rare",
	4: "epic",
};

function ToggleSingleClassInParent(parent, child_name, class_name) {
	parent.Children().forEach((augment) => {
		augment.RemoveClass(class_name);
	});
	const focus_panel = parent.FindChild(child_name);
	if (focus_panel) focus_panel.AddClass(class_name);
}

function ShowAbilityList(name) {
	ToggleSingleClassInParent(HUD.BOOK_LISTS, `AugList_${name}`, "Show");

	for (const l of HUD.AB_LISTS.Children()) for (const c of l.Children()) c.SetHasClass("Active", c.id == `AB_${name}`);
}

function LocalizeAugment(ability_name, augment_name, b_generic) {
	let loc_augment = CheckLocalizeArray(
		[
			`${augment_name}_augment`,
			`DOTA_Tooltip_ability_${ability_name}_${augment_name}`,
			`augment_DOTA_Tooltip_ability_${ability_name}_${augment_name}`,
			b_generic ? `DOTA_Tooltip_demo_aug_orb_${augment_name}` : undefined,
		],
		"",
	);

	if (b_generic) loc_augment = loc_augment.replace(/<b>.*<\/b>/, "");

	return loc_augment;
}

let b_abilities_filled = false;
let catalog_definition = CustomNetTables.GetTableValue("augment_store", "catalog");
let last_hero_id = -1;
let cached_augments = {};

function BuildBook() {
	let hero_ent_idx = Players.GetLocalPlayerPortraitUnit();
	let player_id = Entities.GetPlayerOwnerID(hero_ent_idx);

	if (OVERRIDE_PLAYER_ID != undefined) {
		player_id = OVERRIDE_PLAYER_ID;
		hero_ent_idx = Players.GetPlayerHeroEntityIndex(OVERRIDE_PLAYER_ID);
	}

	if (last_hero_id == hero_ent_idx) return;

	HUD.AB_LISTS.RemoveAndDeleteChildren();
	HUD.AB_LISTS.sub_lines = GenerateSublines(HUD.AB_LISTS, 7, 0, 0);

	HUD.BOOK_LISTS.RemoveAndDeleteChildren();
	let hero_name = Entities.GetUnitName(hero_ent_idx);

	HUD.BOOK.SwitchClass("hero", hero_name);

	const abilities_order = {};
	for (let i = 0; i < 32; i++) {
		const ability = Entities.GetAbility(hero_ent_idx, i);
		const ability_name = Abilities.GetAbilityName(ability);
		if (Entities.IsValidEntity(ability) && ability_name.search("special_bonus_") == -1) {
			abilities_order[ability_name] = i;
		}
	}

	let hero_defs = CustomNetTables.GetTableValue("augment_store", hero_name);
	if (!hero_defs) return;

	hero_defs.generic = catalog_definition;
	abilities_order.generic = 9999999;

	hero_defs = Object.entries(hero_defs);
	hero_defs = hero_defs.map(([k, v]) => {
		v.ability = k;
		v.order = abilities_order[k] != undefined ? abilities_order[k] : 10000;
		return v;
	});

	hero_defs = hero_defs.sort((a, b) => {
		return a.order - b.order;
	});

	hero_defs.forEach((ability_data, index) => {
		const ability_name = ability_data.ability;
		delete ability_data.order;
		delete ability_data.ability;
		let ability_augments = ability_data;
		cached_augments[ability_name] = {};

		const panel_button = $.CreatePanel("Button", HUD.AB_LISTS.sub_lines.line(), `AB_${ability_name}`);
		HUD.BOOK.SwitchClass("lines_applied", `LinesApplied_${HUD.AB_LISTS.Children().length}`);

		panel_button.BLoadLayoutSnippet("AugCard");

		const ability_image = panel_button.GetChild(0);
		ability_image.abilityname = ability_name;

		if (ability_name != "generic" && hero_ent_idx) {
			const ability_idx = Entities.GetAbilityByName(hero_ent_idx, ability_name);
			if (ability_idx >= 0 && Abilities.GetAbilityTextureName(ability_idx) !== "") {
				ability_image.SetAbilityImage(ability_idx);
			} else {
				// ability missing or without an icon: show a neutral placeholder
				ability_image.SetImage("file://{images}/custom_game/augment_picker/dice_icon_png.png");
				ability_image.SetScaling("stretch-to-fit-y-preserve-aspect");
			}
		}

		panel_button.SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("DOTAShowAbilityTooltipForEntityIndex", panel_button, ability_name, hero_ent_idx);
		});
		panel_button.SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("DOTAHideAbilityTooltip");
		});
		panel_button.SetPanelEvent("onactivate", () => {
			ShowAbilityList(ability_name);
		});

		const ability_list = $.CreatePanel("Panel", HUD.BOOK_LISTS, `AugList_${ability_name}`);
		ability_list.BLoadLayoutSnippet("AB_List");
		let lines_container = ability_list.FindChildTraverse("AugLines");

		const is_generic = ability_name == "generic";
		if (is_generic) {
			lines_container.tier_boxes = {};
			Object.entries(TIER_NAMES).forEach(([tier, tier_name]) => {
				const tier_root = $.CreatePanel("Panel", lines_container, `ATB_Tier_${tier}`);
				tier_root.BLoadLayoutSnippet("AugTierBox");

				tier_root.SetDialogVariableLocString("grc_header_rarity", `selected_augments_generic_${tier_name}`);

				tier_root.FindChildTraverse("ATB_Header").SetPanelEvent("onactivate", () => {
					tier_root.ToggleClass("BShowAll");
					$.Schedule(0.1, () => {
						SetBookMaxHeight(HUD.BOOK.BHasClass("BottomView"));
					});
				});

				lines_container.tier_boxes[tier] = tier_root.FindChildTraverse("ATB_List");
			});
		}

		ability_list.SetDialogVariable("ability_name", $.Localize(`DOTA_Tooltip_ability_${ability_name}`));
		ability_list.SetDialogVariableInt("total_u_count", 0);
		panel_button.SetDialogVariableInt("total_u_count", 0);

		Object.entries(ability_augments).forEach(([augment_name, augment_info], index) => {
			if (augment_info.off) return;

			let container_for_lines = lines_container;
			if (is_generic) container_for_lines = lines_container.tier_boxes[augment_info.floor];

			const basic_root = $.CreatePanel(
				"Panel",
				container_for_lines,
				`AugSelected_${ability_name}_${augment_name}`,
			);
			basic_root.BLoadLayoutSnippet("AugLinesBox");
			const main_lines = basic_root.FindChildTraverse("AL_Main");
			const linked_lines = basic_root.FindChildTraverse("AL_Linked");

			panel_button.AddClass("BAbilityHasAugs");
			cached_augments[ability_name][augment_name] = RenderAugments(
				augment_info,
				basic_root,
				linked_lines,
				true,
				true,
				last_hero_id,
				0,
				0,
				"AugLine",
				main_lines,
				is_generic ? "" : ":",
				true,
				is_generic,
			);

			if (GameUI.Augments.IsFavoriteAugment(ability_name, augment_name))
				basic_root.AddClass("BFavorite");

			basic_root.FindChildTraverse("FavBtn").SetPanelEvent("onactivate", () => {
				GameUI.Augments.ToggleFavoriteAugment(ability_name, augment_name);
			});

			const linked_length = linked_lines.Children().length;
			if (linked_length > 0) linked_lines.GetChild(linked_length - 1).AddClass("LastAugLine");
		});

		StringChildrenSort(lines_container, "first_localized_augment");

		if (index == 0) ShowAbilityList(ability_name);
	});
	b_abilities_filled = true;
	last_hero_id = hero_ent_idx;

	ApplyState(CustomNetTables.GetTableValue("augment_store", player_id.toString()));
}

function countDecimals(value) {
	if (Math.floor(value) === value) return 0;
	return value.toString().split(".")[1].length || 0;
}

function SetLineValues(line, base_value, record) {
	const picks = record.picks || 0;

	if (!line.b_linked || line.b_force_visible) line.set_value_by_count(picks, record);
	line.SetHasClass("BHasAugs", picks > 0);

	line.SetHasClass("BLinked", line.b_linked != undefined && !line.b_force_visible);
}

function _ApplyAbilityState(ability_name, data, b_generic) {
	let track_ability = ability_name;

	const au_button = $(`#AB_${track_ability}`);
	const list = $(`#AugList_${track_ability}`);
	if (!au_button || !list) return;

	let count = 0;
	Object.entries(data).forEach(([augment_name, record]) => {
		const cached = (cached_augments[ability_name || ""] || {})[augment_name];
		if (cached)
			cached.forEach((p) => {
				const is_generic = ability_name == "generic";
				if (!p.BHasClass("BLinked"))
					count += (record.picks || 0) / (is_generic ? 1 : record.floor || 1);
				p.set_value_by_count(record.picks || 0, record);
			});
	});

	if (track_ability != ability_name) return;
	au_button.SetDialogVariableInt("total_u_count", count);
	list.SetDialogVariableInt("total_u_count", count);
}

function ApplyBoonState(data) {
	if (!data) return;

	_ApplyAbilityState("generic", data, true);
}

function ApplyState(data) {
	if (!data) return;

	Object.entries(data).forEach(([ability_name, ability_augments], index) => {
		_ApplyAbilityState(ability_name, ability_augments, ability_name == "generic");
	});
}

function UpdateBookPos() {
	if (!b_abilities_filled) {
		$.Schedule(1, UpdateBookPos);
		return;
	}
	if (!UPDATE_POS_TOGGLER) return;

	UpdateBookPosOnce();

	$.Schedule(0, UpdateBookPos);
}

function SetBookMaxHeight(force_value) {
	const button = OVERRIDE_BUTTON || HUD.BOOK_BUTTON;
	const button_pos = button.GetPositionWithinWindow();
	const offset = 12; // Height offset from button that open menu

	let max_content_height = 0;
	for (panel of HUD.BOOK_LISTS.Children()) {
		if (panel.contentheight > max_content_height) {
			max_content_height = panel.contentheight;
		}
	}

	const content_height = HUD.AB_BUTTONS.contentheight + max_content_height + offset;
	const above_height = button_pos.y - offset;
	const below_height = Game.GetScreenHeight() - button_pos.y - offset;

	let bottom_view = !!force_value || (content_height > above_height && above_height < below_height);

	// Limit panel height if content too big
	if (content_height > above_height || content_height > below_height) {
		let max_height =
			(bottom_view ? below_height : above_height) - HUD.AB_BUTTONS.contentheight - offset - 20;
		max_height = max_height / HUD.BOOK.actualuiscale_y - 80;

		for (const panel of HUD.BOOK_LISTS.Children())
			panel.FindChild("AugLines").style.maxHeight = max_height.toFixed() + "px";
	} else {
		for (const panel of HUD.BOOK_LISTS.Children())
			panel.FindChild("AugLines").ClearPropertyFromCode("maxHeight");
	}
	return bottom_view;
}

function UpdateBookPosOnce() {
	const button = OVERRIDE_BUTTON || HUD.BOOK_BUTTON;
	const button_pos = button.GetPositionWithinWindow();
	const offset = 12; // Height offset from button that open menu

	let bottom_view = SetBookMaxHeight();

	let y_pos = 0;

	if (!bottom_view) {
		y_pos = button_pos.y - Game.GetScreenHeight() - offset;
		HUD.BOOK.RemoveClass("BottomView");
		HUD.BOOK.ClearPropertyFromCode("margin");
	} else {
		const filler_height = (button_pos.y + offset) / HUD.BOOK.actualuiscale_y;
		HUD.BOOK.AddClass("BottomView");
		HUD.BOOK.style.marginTop = filler_height.toFixed() + "px";
	}

	HUD.BOOK.SetPositionInPixels(
		Math.round(
			(button_pos.x - (HUD.BOOK.actuallayoutwidth / 2 - button.actuallayoutwidth / 2)) /
				HUD.BOOK.actualuiscale_x,
		),
		Math.round(y_pos / HUD.BOOK.actualuiscale_y) + (bottom_view ? 22 : 0),
		0,
	);
}

function ShowDefaultBook() {
	HUD.BOOK.SetParent(HUD.CONTEXT);
	OVERRIDE_BUTTON = undefined;
	OVERRIDE_PLAYER_ID = undefined;
	ToggleBook();
}

function ToggleBook(b_skip_position_update) {
	HUD.BOOK.ToggleClass("ShowAugBook");

	if (HUD.BOOK.BHasClass("ShowAugBook")) {
		BuildBook();

		if (!b_skip_position_update) {
			UPDATE_POS_TOGGLER = true;
			$.Schedule(0, UpdateBookPos);
		} else $.Schedule(0.07, UpdateBookPosOnce);
	} else UPDATE_POS_TOGGLER = false;
}

function CloseBook(check_is_default) {
	if (check_is_default && !OVERRIDE_BUTTON) return;

	HUD.BOOK.RemoveClass("ShowAugBook");
}

function OnPortraitChanged() {
	if (OVERRIDE_PLAYER_ID) return;

	const unit = Players.GetLocalPlayerPortraitUnit();
	const local_team = Players.GetTeam(Game.GetLocalPlayerID());

	let is_hero = Entities.IsHero(unit) && Entities.GetUnitLabel(unit) != "spirit_bear";
	let allied_team =
		local_team == 1 ||
		local_team == Entities.GetTeamNumber(unit) ||
		Game.GetMapInfo().map_display_name == "ot3_demo";

	if (HUD.BOOK_BUTTON) HUD.BOOK_BUTTON.SetHasClass("Visible", is_hero && allied_team);

	CloseBook();
}

function OnStoreChanged(table_name, key, value) {
	if (Entities.GetPlayerOwnerID(last_hero_id) == key) ApplyState(value);
}

function OpenForPlayer(player_id, button, parent = HUD.CONTEXT) {
	HUD.BOOK.SetParent(HUD.CONTEXT);

	if (button != OVERRIDE_BUTTON || player_id != OVERRIDE_PLAYER_ID) {
		OVERRIDE_BUTTON = button;
		OVERRIDE_PLAYER_ID = player_id;

		CloseBook();
	}

	ToggleBook(true);
	HUD.BOOK.SetParent(parent);
}

GameUI.AugmentBook = {};
GameUI.AugmentBook.CloseBook = CloseBook;
GameUI.AugmentBook.OpenForPlayer = OpenForPlayer;

(() => {
	const abilities_block = FindDotaHudElement("AbilitiesAndStatBranch").GetChild(0);
	let upgrades_button = abilities_block.FindChildTraverse("AugBookBtn");
	if (upgrades_button) upgrades_button.DeleteAsync(0);

	HUD.BOOK_BUTTON.SetParent(abilities_block);

	GameEvents.Subscribe("dota_player_update_query_unit", OnPortraitChanged);
	GameEvents.Subscribe("dota_player_update_selected_unit", OnPortraitChanged);

	CustomNetTables.SubscribeNetTableListener("augment_store", OnStoreChanged);

	$.RegisterForUnhandledEvent("Cancelled", () => {
		CloseBook();
	});

	GameUI.SetMouseCallback((event_name, arg) => {
		if (event_name == "pressed" && arg == 0) CloseBook();
	});

	OnPortraitChanged();
	BuildBook();
})();
