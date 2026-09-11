const hidden_augments = {
	morphling_morph: ["bonus_attributes"],
	nevermore_shadowraze2: [
		"shadowraze_damage",
		"stack_bonus_damage",
		"shadowraze_radius",
		"duration",
		"shadowraze_radius",
		"cd_mana",
	],
	nevermore_shadowraze3: [
		"shadowraze_damage",
		"stack_bonus_damage",
		"shadowraze_radius",
		"duration",
		"shadowraze_radius",
		"cd_mana",
	],
	nevermore_necromastery: ["necromastery_max_souls_scepter"],
};
let favorites_store = {};
const CONTEXT = $.GetContextPanel();

GameUI.Augments = {};

GameUI.Augments.IsHiddenAugment = (ability_name, augment_name) => {
	return hidden_augments[ability_name] != undefined && hidden_augments[ability_name].indexOf(augment_name) > -1;
};

GameUI.Augments.ToggleFavoriteAugment = (ability_name, augment_name) => {
	if (CONTEXT.BHasClass("FavSetCooldown")) return;
	CONTEXT.AddClass("FavSetCooldown");
	$.Schedule(0.1, () => {
		CONTEXT.RemoveClass("FavSetCooldown");
	});

	const state = !(favorites_store[ability_name] && favorites_store[ability_name][augment_name]);

	const card = FindDotaHudElement(`AugCard_${ability_name}_${augment_name}`);
	if (card) card.SetHasClass("BFavorite", state);
	const book_line = FindDotaHudElement(`AugSelected_${ability_name}_${augment_name}`);
	if (book_line) book_line.SetHasClass("BFavorite", state);

	if (state) {
		favorites_store[ability_name] = favorites_store[ability_name] || {};
		favorites_store[ability_name][augment_name] = true;
	} else if (favorites_store[ability_name] && favorites_store[ability_name][augment_name]) {
		delete favorites_store[ability_name][augment_name];
		if (Object.keys(favorites_store[ability_name]).length == 0) delete favorites_store[ability_name];
	}

	GameEvents.SendCustomGameEventToServer("Augments:set_favs", { favs: favorites_store });
};

GameUI.Augments.IsFavoriteAugment = (ability_name, augment_name) => {
	return favorites_store[ability_name] && favorites_store[ability_name][augment_name];
};

function _ApplyFavorites(_favorites_store) {
	favorites_store = _favorites_store;
}

(() => {
	GameEvents.Subscribe("Augments:sync_favs", _ApplyFavorites);

	GameEvents.SendCustomGameEventToServer("Augments:get_favs", {});
})();
