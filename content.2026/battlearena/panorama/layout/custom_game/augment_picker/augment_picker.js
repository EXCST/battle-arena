const HUD = {
	CONTEXT: $.GetContextPanel(),
	CARDS: $("#Augments_Cards"),
	REROLL: $("#AugReroll"),
	AP_TOGGLE: $("#AP_Toggle"),
	AP_TIMER: $("#AP_Timer"),
};
let current_reroll_count = 0;
let current_tier = 0;
let auto_pick_step = 1;
let auto_pick_time = 2;
let auto_pick_schedule;

function SetTierContext(tier) {
	HUD.CONTEXT.SetDialogVariableLocString("upgrades_header", `augments_header_${tier}`);
	HUD.CONTEXT.SwitchClass("augment_tier", `AugTier_${tier}`);
}

function AttachAbilityTooltip(ability_panel) {
	ability_panel.SetPanelEvent("onmouseover", () => {
		$.DispatchEvent("DOTAShowAbilityTooltip", ability_panel, ability_panel.abilityname);
	});
	ability_panel.SetPanelEvent("onmouseout", () => {
		$.DispatchEvent("DOTAHideAbilityTooltip");
	});
}

let current_pending_count = 0;
function ShowHand(event) {
	const hand = event.hand;
	if (!hand) return;

	const selection_tier = hand.tier || TIER.COMMON;
	const hero_idx = Players.GetPlayerHeroEntityIndex(LOCAL_PLAYER_ID);
	current_pending_count = event.queued || 1;
	HUD.CONTEXT.SetDialogVariableInt("upgrades_pending_count", current_pending_count);
	HUD.CONTEXT.SetHasClass("Show", true);
	HUD.CONTEXT.SetHasClass("BRerollRequestSent", false);

	SetTierContext(selection_tier);
	HUD.CARDS.RemoveAndDeleteChildren();

	current_tier = selection_tier;

	let delay = 0;
	for (const choice of Object.values(hand.cards)) {
		const is_generic = choice.kind == AUGMENT_KIND.GENERIC;
		const min_tier = choice.floor || choice.rarity || TIER.COMMON;
		const current_picks = (choice.picks || 0) / min_tier;

		const card = $.CreatePanel(
			"Button",
			HUD.CARDS,
			`AugCard_${choice.ability}_${choice.name}`,
		);
		card.BLoadLayoutSnippet("AugCard");
		card.SetHasClass("BoonCard", is_generic);

		const image = card.FindChildTraverse("AugIcon");
		const additional_root = card.FindChildTraverse("AugSubValues");

		if (is_generic) {
			image.SetImage(
				`file://{images}/custom_game/augments/generics/${choice.name.replace("aug_", "")}.png`,
			);
			image.SetScaling("stretch-to-fit-y-preserve-aspect");
		} else {
			const ability_idx = Entities.GetAbilityByName(hero_idx, choice.ability);
			const has_texture = ability_idx >= 0 && Abilities.GetAbilityTextureName(ability_idx) !== "";

			if (has_texture) {
				image.SetAbilityImageToLocalHero(choice.ability);
			} else {
				// ability missing or without an icon: show a neutral placeholder
				image.SetImage("file://{images}/custom_game/augment_picker/dice_icon_png.png");
				image.SetScaling("stretch-to-fit-y-preserve-aspect");
			}
			AttachAbilityTooltip(image);
		}

		if (choice.step) {
			card.AddClass("BHasStep");
			card.SetDialogVariable("upgrade_increment", Math.rd(choice.step, 1));
		}

		if (GameUI.Augments.IsFavoriteAugment(choice.ability, choice.name))
			card.AddClass("BFavorite");

		card.IsFavorite = () => {
			return card.BHasClass("BFavorite");
		};

		if (choice.cap) {
			const cap = Number(choice.cap / min_tier);

			const levels_root = card.FindChildTraverse("AugLevelsRoot");
			const levels_from_aug = current_picks + selection_tier / min_tier;

			for (let level = 0; level < cap; level++) {
				const level_panel = $.CreatePanel("Panel", levels_root, "", {
					class: "AugLevelDot",
				});
				if (level < current_picks) level_panel.AddClass("BLevelOwned");
				else if (level < levels_from_aug) level_panel.AddClass("BLevelFromAug");
			}
		}

		RenderAugments(
			choice,
			card,
			additional_root,
			true,
			true,
			hero_idx,
			current_picks,
			current_picks + selection_tier,
			"AugSubValue",
			null,
			null,
			true,
			false,
		);

		card.SetDialogVariable(
			"main_ability_name",
			$.Localize(`#DOTA_Tooltip_ability_${choice.ability}`).replace(":", ""),
		);

		if (is_generic) {
			card.SetDialogVariable("base_value_desc", $.Localize(`#${choice.name}`, card));
		}

		card.SetDialogVariableInt("current_count", current_picks);
		card.SetDialogVariableInt("new_upgrade_level", current_picks + selection_tier / min_tier);

		const pick = () => {
			GameEvents.SendCustomGameEventToServer("Augments:pick_card", {
				ability: choice.ability,
				name: choice.name,
			});
			if (current_pending_count == 1) HUD.CONTEXT.SetHasClass("Show", false);
		};
		card.SetPanelEvent("onactivate", pick);
		card.pick = pick;

		card.FindChildTraverse("AugFavBtn").SetPanelEvent("onactivate", () => {
			GameUI.Augments.ToggleFavoriteAugment(choice.ability, choice.name);
		});

		card.style.transitionDuration = delay + "s";
		card.style.transform = "translateX(0px)";
		delay += 0.15;
	}

	AutoPickFavorite();

	if (hand.reroll) Game.EmitSound("custom.reroll");

	UpdateRerollBtn();
}

function ToggleVisibility() {
	HUD.CONTEXT.ToggleClass("BHideAugs");
}

function ResetPicker() {
	HUD.CONTEXT.SetDialogVariableInt("upgrades_pending_count", 0);
	HUD.CONTEXT.SetDialogVariable("reroll_count", 0);
	HUD.CONTEXT.RemoveClass("BHideAugs");
	HUD.CONTEXT.SetHasClass("Show", false);
	HUD.CONTEXT.SetDialogVariable("auto_pick_step", auto_pick_step);
	HUD.CONTEXT.SetDialogVariable("auto_pick_current_time", auto_pick_time);
	SetTierContext(TIER.COMMON);
}

function UpdateRerollBtn() {
	const no_rerolls = current_reroll_count < current_tier;

	HUD.CONTEXT.SetHasClass("IsUsingConsumablesRerolls", false);

	let tooltip_key = "augments_reroll_hint";
	if (no_rerolls) tooltip_key = "augments_no_rerolls_hint";

	HUD.REROLL.SetDialogVariableLocString("tooltip", tooltip_key);
}

function RequestReroll() {
	if (current_reroll_count >= current_tier) {
		if (!HUD.CONTEXT.BHasClass("BRerollRequestSent")) {
			HUD.CONTEXT.SetHasClass("BRerollRequestSent", true);
			GameEvents.SendCustomGameEventToServer("Augments:reroll_hand", {});
		}
	}
}

function UpdateQueueBadge(event) {
	HUD.CONTEXT.SetDialogVariableInt("upgrades_pending_count", event.queued);
	current_pending_count = event.queued;
	if (event.queued == 0) HUD.CONTEXT.SetHasClass("Show", false);
}

function UpdateAutoPickTime(operation) {
	if (operation == "+") auto_pick_time += auto_pick_step;
	else if (operation == "-") auto_pick_time -= auto_pick_step;

	auto_pick_time = Math.clamp(auto_pick_time, 0, 120);
	HUD.CONTEXT.SetDialogVariable("auto_pick_current_time", auto_pick_time);
}

function ToggleAutoPickFavs() {
	const state = HUD.AP_TOGGLE.IsSelected();
	HUD.CONTEXT.SetHasClass("BAutoPickFavs", state);
	AutoPickFavorite(!state);
}

function AutoPickFavorite(skip_re_animation) {
	if (auto_pick_schedule != undefined) auto_pick_schedule = $.CancelScheduled(auto_pick_schedule);
	if (!HUD.CONTEXT.BHasClass("BAutoPickFavs")) return;

	const has_favorite = HUD.CARDS.Children().find((card) => card.IsFavorite());

	if (has_favorite) {
		if (!skip_re_animation) HUD.AP_TIMER.style.animationDuration = `${-1}s`;
		HUD.AP_TIMER.style.animationDuration = `${auto_pick_time}s`;
	} else HUD.AP_TIMER.style.animationDuration = `${-1}s`;

	auto_pick_schedule = $.Schedule(auto_pick_time, () => {
		auto_pick_schedule = undefined;

		for (const card of HUD.CARDS.Children()) {
			if (card.IsFavorite()) {
				card.pick();
				break;
			}
		}
	});
}

function ClickBehaviorTick() {
	$.Schedule(0.03, ClickBehaviorTick);
	const in_target_mode =
		GameUI.GetClickBehaviors() != CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_NONE &&
		GameUI.GetClickBehaviors() != CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_LEARN_ABILITY;

	HUD.CONTEXT.SetHasClass("AbilityCast", in_target_mode);
	HUD.CONTEXT.hittestchildren = !in_target_mode;
}

(() => {
	ResetPicker();
	GameEvents.Subscribe("Augments:show_hand", ShowHand);
	GameEvents.Subscribe("Augments:update_queue", UpdateQueueBadge);
	GameEvents.SendCustomGameEventToServer("Augments:get_hand", {});

	SubscribeToNetTableKey("reroll_bank", LOCAL_PLAYER_ID.toString(), function (rerolls) {
		HUD.CONTEXT.SetDialogVariable("reroll_count", rerolls.count);
		current_reroll_count = rerolls.count;
		UpdateRerollBtn();
	});

	ClickBehaviorTick();
})();
