const reverse_increment = {
	any: ["cd_mana"],
	skywrath_mage_ancient_seal: ["resist_debuff"],
};

function Capitalize(line) {
	line = line.toLowerCase();
	line = line.charAt(0).toUpperCase() + line.substring(1);
	return line;
}

function MultDiff(record, hero_idx, value, max, count_for_diff) {
	const calc = (count) => {
		return ComputeBonus(hero_idx, value, count, record);
	};
	return Math.rd(calc(max) - calc(count_for_diff), 1);
}

function RenderAugments(
	augment_info,
	basic_root,
	additional_root,
	b_check_hidden,
	b_check_repeat_localization_lines,
	hero_idx,
	count_for_diff,
	max_count,
	value_snippet,
	root_for_basic_line,
	loc_prefix,
	check_multiplier_for_min_tier,
	b_force_generic_localization,
) {
	let lines = [];

	const is_generic = augment_info.kind == AUGMENT_KIND.GENERIC;

	let default_definition = {
		ability: augment_info.ability,
		name: augment_info.name,
		mode: augment_info.mode,
		base: augment_info.base,
		limit: augment_info.limit !== undefined ? augment_info.limit : DEFAULT_MULT_LIMIT,
		limit_base: augment_info.limit_base || undefined,
		perks: augment_info.perks || undefined,
		current_picks: augment_info.picks || undefined,
		step: augment_info.step || undefined,
		add_sum: augment_info.add_sum,
		mult_product: augment_info.mult_product,
	};

	if (is_generic) {
		default_definition.generic_stats = {};
		Object.entries(augment_info.stats || {}).forEach(([stat_name, stat_value]) => {
			if (!default_definition || stat_name.search("flat_") < 0) default_definition.base = stat_value;

			default_definition.generic_stats[stat_name] = stat_value;

			let result_stat_value;
			const stat_delta = (augment_info.stats_delta || {})[stat_name];
			if (stat_delta !== undefined) {
				result_stat_value = Math.rd(stat_delta, 1);
			} else {
				result_stat_value = MultDiff(
					augment_info,
					hero_idx,
					stat_value,
					max_count,
					count_for_diff,
				);

				if (stat_name.includes("flat_")) result_stat_value /= max_count - count_for_diff;
			}

			basic_root.SetDialogVariable(stat_name, result_stat_value);
		});
	}

	lines.push(default_definition);

	const create_definition = (values, _ability_name) => {
		Object.entries(values).forEach(([linked_name, linked_entry]) => {
			let linked_definition = {
				ability: _ability_name,
				name: linked_name,
				mode: AUGMENT_MODE.ADD,
				base: linked_entry,
				picks: augment_info.picks,
				current_picks: augment_info.picks,
			};
			if (typeof linked_entry == "object") {
				linked_definition.base = linked_entry.base;
				if (linked_entry.mode) linked_definition.mode = linked_entry.mode;
				if (linked_entry.step) linked_definition.step = linked_entry.step;

				if (linked_entry.limit !== undefined) linked_definition.limit = linked_entry.limit;

				if (linked_entry.limit_base !== undefined) linked_definition.limit_base = linked_entry.limit_base;
			}
			lines.push(linked_definition);
		});
	};

	if (augment_info.bundle) {
		create_definition(augment_info.bundle, augment_info.ability);
	}
	if (augment_info.bundle_abilities) {
		Object.entries(augment_info.bundle_abilities).forEach(([linked_ability, linked_definition]) => {
			create_definition(linked_definition, linked_ability);
		});
	}

	let b_first_line_check = false;
	let localized_lines = {};
	const common_ability = augment_info.ability;

	let aug_lines = [];

	lines.forEach((definition) => {
		let value = definition.base;
		const ability = definition.ability;
		const mode = definition.mode;
		const augment_name = definition.name;

		let loc_augment = "";
		let multiply_value;
		const pick_delta = augment_info.delta;
		if (mode == AUGMENT_MODE.ADD) {
			value = pick_delta !== undefined ? pick_delta : ComputeBonus(
				hero_idx,
				value,
				max_count - count_for_diff,
				definition,
			);
		} else if (mode == AUGMENT_MODE.MULTIPLY) {
			multiply_value = pick_delta !== undefined ? pick_delta : MultDiff(
				definition,
				hero_idx,
				value,
				max_count,
				count_for_diff,
			);
		}
		if (b_check_hidden && GameUI.Augments.IsHiddenAugment(ability, augment_name)) return;

		localized_lines[ability] = localized_lines[ability] || {};

		const localize_augment = (_ability_name, _augment_name, b_check_orb_generic_localize) => {
			loc_augment = CheckLocalizeArray(
				[
					`${_augment_name}_augment`,
					`DOTA_Tooltip_ability_${_ability_name}_${_augment_name}`,
					`augment_DOTA_Tooltip_ability_${_ability_name}_${_augment_name}`,
					`DOTA_Tooltip_ability_${_ability_name.replace("_lua", "")}_${_augment_name}`,
					`augment_DOTA_Tooltip_ability_${_ability_name.replace("_lua", "")}_${_augment_name}`,
					b_check_orb_generic_localize ? _augment_name : undefined,
					!b_check_hidden ? `DOTA_Tooltip_demo_aug_orb_${_augment_name}` : undefined,
				],
				"",
			);

			if (b_check_orb_generic_localize && !b_check_hidden) loc_augment = loc_augment.replace(/<b>.*<\/b>/, "");
		};

		localize_augment(ability, augment_name);
		if (loc_augment == "") localize_augment(common_ability, augment_name);
		if (loc_augment == "" && is_generic) localize_augment(common_ability, augment_name, true);
		if (!b_check_hidden && loc_augment == "") loc_augment = augment_name;
		if (loc_augment == "") {
			// fallback: human-readable name from the raw stat name
			loc_augment = augment_name.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
		}

		const is_pct = loc_augment.charAt(0) == "%";

		loc_augment = loc_augment.replace(/%|:/g, "").trim();
		if (loc_prefix && !new RegExp(`/${loc_prefix}:\\$/`).test(loc_augment)) loc_augment += loc_prefix;

		let effect = value > 0 ? "inc" : "dec";
		if (reverse_increment.any.includes(augment_name) || reverse_increment[ability]?.includes(augment_name))
			effect = effect === "inc" ? "dec" : "inc";

		let base_line_localized = $.Localize(`#augment_description_${effect}`);
		const line = `<b>${Capitalize(loc_augment)}</b> ${base_line_localized} <b>${Math.abs(
			Math.rd(multiply_value, 1) || Math.rd(value, 1),
		)}${is_pct ? "%" : ""}</b>`;

		const fill_line = (line_label) => {
			const min_tier = augment_info.floor || 1;

			aug_lines.push(line_label);
			line_label.SetDialogVariable("special_name", loc_augment);
			if (b_force_generic_localization)
				line_label.SetDialogVariable("special_name", $.Localize(augment_info.name, line_label));

			line_label.SetDialogVariable(
				"base_value",
				ComputeBonus(hero_idx, definition.base, 1, definition),
			);
			line_label.set_value_by_count = (count, record) => {
				line_label.SetDialogVariableInt("augments_count", count / (!b_check_hidden ? 1 : min_tier));
				if (b_force_generic_localization) {
					Object.entries(definition.generic_stats || {}).forEach(([stat_name, stat_value]) => {
						const stat_delta = (augment_info.stats_delta || {})[stat_name];

						let _value;
						if (stat_delta !== undefined) {
							_value = stat_delta;
						} else {
							let count_tooltip = count;
							if (stat_name.search("flat_") > -1) count_tooltip = 1;

							_value = ComputeBonus(hero_idx, stat_value, count_tooltip, definition);

							if (record && record.rolled_factor) _value = Math.rd(_value * record.rolled_factor, 1);
						}

						line_label.SetDialogVariable(stat_name, _value);

						if (b_force_generic_localization)
							line_label.SetDialogVariable(
								"special_name",
								$.Localize(augment_info.name, line_label),
							);
					});
				} else {
					let total_value;
					if (record && !line_label.BHasClass("BLinked")) {
						// the state record carries the actual accumulated values
						const rec_def = { ...definition, ...record };
						total_value = ComputeBonus(hero_idx, rec_def.base, count, rec_def);
					} else if (mode == AUGMENT_MODE.ADD) {
						total_value = ComputeBonus(
							hero_idx,
							definition.base,
							count,
							definition,
						);
					} else if (mode == AUGMENT_MODE.MULTIPLY) {
						total_value = MultDiff(
							{ ...augment_info, mode: definition.mode || augment_info.mode },
							hero_idx,
							value,
							count,
							0,
						);
					}

					line_label.SetDialogVariable("increment", "");

					const step = definition.step;
					if (step) {
						line_label.AddClass("BHasStep");
						line_label.SetDialogVariable(
							"increment",
							`(<a class='AugStepTag'>${step > 0 ? "+" : ""}${Math.rd(step, 1)}</a>) `,
						);
					}

					line_label.AddClass(`SpecialMinTier_${min_tier}`);
					line_label.SetDialogVariable("total_value", `${total_value}${is_pct ? "%" : ""}`);
				}
				basic_root.SetHasClass("BHasAugs", count > 0);
				if (augment_info.cap) basic_root.SetHasClass("BFullAug", count >= augment_info.cap);
			};
			line_label.set_value_by_count(is_generic ? max_count - count_for_diff : 0);
			basic_root.AddClass(`MinTier_${min_tier}`);

			if (is_generic) {
				const generic_image = line_label.FindChildTraverse("AugIconImg");
				if (generic_image)
					generic_image.SetImage(
						`file://{images}/custom_game/augments/generics/${augment_name.replace("aug_", "")}.png`,
					);
			}
			basic_root.min_tier = min_tier;

			if (augment_info.cap) {
				line_label.AddClass("BMaxed");
				let cap = augment_info.cap;

				if (check_multiplier_for_min_tier) {
					cap = Number(augment_info.cap / min_tier);
				}
				line_label.SetDialogVariable("u_max_count", cap);
			}
		};

		let line_for_edit = basic_root;

		const create_line_for_edit = (root) => {
			line_for_edit = $.CreatePanel("Panel", root, augment_name);
			line_for_edit.BLoadLayoutSnippet(value_snippet);
			line_for_edit.SetDialogVariable("value", line);
			line_for_edit.localized_text = line;

			if (!basic_root.first_localized_augment) basic_root.first_localized_augment = line;

			fill_line(line_for_edit);
		};
		if (root_for_basic_line && !b_first_line_check) create_line_for_edit(root_for_basic_line);

		if (b_first_line_check) {
			if (b_check_repeat_localization_lines && !!localized_lines[ability][loc_augment]) return;
			create_line_for_edit(additional_root);

			basic_root.AddClass("BHasSubValues");
			if (common_ability != ability) {
				line_for_edit.AddClass("BLinkedAbility");

				line_for_edit.FindChildTraverse("LinkedAbilityIcon").SetAbilityImageToLocalHero(ability);
			}

			line_for_edit.AddClass("BLinked");

			let ability_name_for_sort = ability;
			if (common_ability == ability) ability_name_for_sort = "!!!!!";

			line_for_edit.localized_text = `${ability_name_for_sort}_${line}`;
		} else {
			b_first_line_check = true;
			if (!root_for_basic_line) fill_line(line_for_edit);
			if (is_generic) {
				const generic_localized_text = $.Localize(`#${augment_name}`, line_for_edit);
				if (!basic_root.first_localized_augment) basic_root.first_localized_augment = generic_localized_text;
				line_for_edit.SetDialogVariable("base_value_desc", generic_localized_text);
			} else {
				if (!basic_root.first_localized_augment) basic_root.first_localized_augment = line;
				line_for_edit.SetDialogVariable("base_value_desc", line);
			}
		}
		localized_lines[ability][loc_augment] = true;
	});

	StringChildrenSort(additional_root, "localized_text");

	let linked_chd_counter = 0;
	for (const linked_line of additional_root.Children())
		linked_line.AddClass(`LinkedChd_${linked_chd_counter++}`);

	return aug_lines;
}
