"use strict";

const Root = $("#RepickItemRoot");
const Grid = $("#RepickItemGrid");
const PickButton = $("#RepickItemButton");
const PickButtonLabel = $("#RepickItemButtonLabel");

let g_hero_data = undefined;
let g_selected = undefined;

function HeroPortraitUrl(hero, isCustom)
{
	if (isCustom == 1)
		return 'url("s2r://panorama/images/heroes/' + hero + '_png.vtex")';
	return 'url("s2r://panorama/images/custom_game/heroes/' + hero + '_png.vtex")';
}

function OnClose()
{
	Root.hittest = false;
	Root.visible = false;
	Root.enabled = false;
	Root.style.visibility = "collapse";

	GameEvents.SendCustomGameEventToServer("aa_repick_item_cancel", {});
}

function UpdatePickButton()
{
	if (g_selected !== undefined && g_hero_data[g_selected] && g_hero_data[g_selected]["picked"] == 0)
	{
		PickButton.AddClass("CanPick");
		PickButton.RemoveClass("CantPick");
		PickButtonLabel.text = $.Localize("#AA_REPICK_ITEM_PICK");
	}
	else
	{
		PickButton.AddClass("CantPick");
		PickButton.RemoveClass("CanPick");
		PickButtonLabel.text = $.Localize("#AA_REPICK_ITEM_PICK_DISABLED");
	}
}

function SelectHero(hero)
{
	if (!g_hero_data[hero] || g_hero_data[hero]["picked"] == 1) return;

	if (g_selected !== undefined)
	{
		const prev = Grid.FindChildTraverse("repick_cell_" + g_selected);
		if (prev) prev.RemoveClass("HeroCellSelected");
	}

	g_selected = hero;

	const cur = Grid.FindChildTraverse("repick_cell_" + hero);
	if (cur) cur.AddClass("HeroCellSelected");

	UpdatePickButton();
	Game.EmitSound("ui_select_md");
}

function CreateHeroCell(hero)
{
	const hero_info = g_hero_data[hero];

	const cell = $.CreatePanel("Panel", Grid, "repick_cell_" + hero);
	cell.AddClass("HeroCell");
	cell.hittest = true;
	cell.enabled = true;
	cell.SetPanelEvent("onactivate", function() { SelectHero(hero); });

	const port = $.CreatePanel("Panel", cell, "");
	port.AddClass("HeroCellPortrait");
	port.style.backgroundImage = HeroPortraitUrl(hero, hero_info["custom"]);
	port.style.backgroundSize = "cover";
	port.style.backgroundPosition = "50% 50%";

	if (hero_info["picked"] == 1)
	{
		cell.AddClass("HeroCellPicked");
	}
}

function RenderHeroes()
{
	Grid.RemoveAndDeleteChildren();
	g_selected = undefined;

	const hero_names = Object.keys(g_hero_data).sort();
	for (const hero of hero_names)
	{
		CreateHeroCell(hero);
	}

	let first_free = hero_names.find((hero) => g_hero_data[hero]["picked"] == 0);
	if (first_free !== undefined) SelectHero(first_free);

	UpdatePickButton();
}

function OnOpen()
{
	if (!g_hero_data) return;
	RenderHeroes();
	Root.hittest = true;
	Root.visible = true;
	Root.enabled = true;
	Root.style.visibility = "visible";
}

function PickHero()
{
	if (g_selected === undefined) return;
	if (!g_hero_data[g_selected] || g_hero_data[g_selected]["picked"] == 1) return;

	GameEvents.SendCustomGameEventToServer("aa_repick_item_start_repick", {
		hero_name: g_selected,
	});
}

(function ()
{
	OnClose();

	GameEvents.Subscribe("aa_repick_item_set_data", function (data)
	{
		g_hero_data = data;
		if (Root.visible) RenderHeroes();
	});

	GameEvents.Subscribe("aa_repick_item_open", function (data) { OnOpen(); });

	GameEvents.Subscribe("aa_repick_item_close", function (data) { OnClose(); });

	GameEvents.Subscribe("aa_repick_item_set_hero_picked", function (data)
	{
		if (!g_hero_data || !g_hero_data[data["hero_name"]]) return;
		g_hero_data[data["hero_name"]]["picked"] = data["picked"];
		if (Root.visible) UpdatePickButton();
	});
})();