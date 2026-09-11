const DOTA_SHOP = {
	TABS: "GridMainTabs",
	MAIN: "GridMainShop",
	CONTENTS: "GridMainShopContents",
	HEIGHT: "HeightLimiter",
};
$.Msg("[ShopExtender] script loaded");
const CACHED_TABS = {};
let SHOP_TABS_CONFIG;

let colors = {
	tab_bottom: "#0b2e3a",
	tab_top: "#3fd9c9",
	tab_inactive_border: "#6fd4c8",
	tab_active_border: "#ff6e11",
};

class ShopTab {
	constructor(name) {
		this.name = name;
		this.active = false;
		this.items = [];

		this.CreateContent();

		let style = {
			"margin-top": "2px",
			"background-color": `gradient(linear, 0% 100%, 0% 0%, from(${colors.tab_bottom}), to(${colors.tab_top}))`,
			width: "120px",
			border: `1px solid ${colors.tab_inactive_border}`,
		};

		const tab = $.CreatePanel("TabButton", DOTA_SHOP.TABS, `CustomShopTab_${name}`, {
			class: "ShopItemsTab",
			group: "ShopGridTab",
			style: StyleObjectToCSSLine(style),
		});

		tab.SetPanelEvent("onactivate", () => {
			DOTA_SHOP.MAIN.SwitchClass("selected_shop_tab", `Show${name}ItemsTab`);
			if (!this.active) this.UpdateItems();
			this.active = true;
		});

		let header_style = StyleObjectToCSSLine({
			height: "15px",
		});

		$.CreatePanel("Label", tab, "", {
			text: $.Localize(`shop_tab_${name}`),
			style: header_style,
		});

		tab.b_custom_tab = true;
		this.tab = tab;
	}
	CreateContent() {
		const content = $.CreatePanel("TabContents", DOTA_SHOP.CONTENTS, `Grid${this.name}Category`, {
			class: "ShopItemsCategory",
			tabid: `CustomShopTab_${this.name}`,
			group: "ShopGridTab",
		});

		content.b_custom_content = true;
		this.content = content;

		this.categories = $.CreatePanel("Panel", content, `GridUpgradeItems`, {
			class: "ShopItemsRows",
		});

		this.FillContent();
	}
	FillContent() {
		for (const [category, category_data] of Object.entries(SHOP_TABS_CONFIG[this.name].categories)) {
			const container = $.CreatePanel("Panel", this.categories, `ShopExtender_${this.name}_${category}`);
			container.BLoadLayoutSnippet("ShopItemsLayout");
			container.sort_weight = category_data.sort_weight;

			let items_container = container.FindChildTraverse("ShopItemsContainer");

			container.SetDialogVariable("shop_row_title", $.Localize(`shop_tab_category_${category}`, container));

			for (const [item_name, item_info] of Object.entries(category_data.items).sort(
				([, a], [, b]) => (a.sort_weight ?? 0) - (b.sort_weight ?? 0),
			)) {
				const item = $.CreatePanel(
					"DOTAShopItem",
					items_container,
					`ShopExtenderItem_${this.name}_${category}_${item_name}`,
					{
						itemname: item_name,
						style: "width:42px;height:width-percentage(72.7%);margin:1px 3px 1px 2px;",
						abilityid: item_info.id,
					},
				);
				GameUI.CustomShopItemForDispatchEvent = item;

				item.SetPanelEvent("oncontextmenu", () => {
					if (!item.BHasClass("CanPurchase") || item.BHasClass("OutOfStock") || Game.IsGamePaused()) return;
					$.DispatchEvent("DOTAShopPurchaseItem", item, item_info.id);
				});
				item.SetDraggable(true);

				item.cost = item_info.cost;
				item.sort_weight = item_info.sort_weight;
				item.item_name = item_name;
				item.echo_container = $.CreatePanel("Panel", item, "");
				item.is_stock = item.BHasClass("OutOfStock") || item.BHasClass("ShowStockAmount");
				item.stock = item.FindChildTraverse("StockAmount");
				item.FindChildTraverse("OutOfStockOverlay").DeleteAsync(0);

				this.items.push(item);
			}
		}
		DefaultChildrenSort(this.categories, "sort_weight", true);

		this.categories.Children().forEach((child, index) => {
			child.SetHasClass("LeftRow", index % 2);
		});
	}
	UpdateItems() {
		if (!DOTA_SHOP.MAIN.BHasClass(`Show${this.name}ItemsTab`)) {
			this.tab.style.border = `1px solid ${colors.tab_inactive_border}`;
			this.active = false;
			return;
		}

		if (this.active) this.tab.style.border = `1px solid ${colors.tab_active_border}`;

		const gold = Players.GetGold(LOCAL_PLAYER_ID);

		for (const item of this.items) {
			item.SetHasClass("CanPurchase", gold >= item.cost);

			if (item.is_stock) {
				const echo_item = $.CreatePanel("DOTAShopItem", item.echo_container, "", {
					itemname: item.item_name,
					style: "visibility:collapse;",
				});

				item.SetHasClass("OutOfStock", echo_item.BHasClass("OutOfStock"));
				item.SetHasClass("CanPurchase", echo_item.BHasClass("CanPurchase"));
				item.SetHasClass("ShowStockAmount", echo_item.BHasClass("ShowStockAmount"));
				item.stock.text = echo_item.FindChild("StockAmount").text;

				const stock_overlay = echo_item.FindChildTraverse("OutOfStockOverlay");
				stock_overlay.SetParent(item);
				item.MoveChildAfter(stock_overlay, item.stock);
				stock_overlay.DeleteAsync(0);

				echo_item.DeleteAsync(0);
			}
		}

		$.Schedule(0, () => {
			this.UpdateItems();
		});
	}
}

function ActivateCustomShopTab(name) {
	const cached_tab = CACHED_TABS[name];
	if (!cached_tab || !cached_tab.tab.IsValid()) return;
	$.DispatchEvent("Activated", cached_tab.tab, "mouse");
}
GameUI.ActivateCustomShopTab = ActivateCustomShopTab;

function CacheDotaShopPanels() {
	for (const [id, cached_entry] of Object.entries(DOTA_SHOP)) {
		if (typeof cached_entry == "string") {
			const panel = FindDotaHudElement(cached_entry);
			if (panel) DOTA_SHOP[id] = panel;
			else {
				$.Msg(`[ShopExtender] missing panel: ${cached_entry}`);
				return false;
			}
		}
	}
	$.Msg("[ShopExtender] all shop panels found");
	return true;
}
function UpdateTabsButtonsStyle() {
	for (const tab_button of DOTA_SHOP.TABS.FindChildrenWithClassTraverse("ShopItemsTab")) {
		tab_button.ClearPropertyFromCode("border-radius");
		tab_button.style.height = "29px";
		tab_button.style.border = "1px";
		tab_button.style.paddingBottom = `${tab_button.b_custom_tab ? 0 : -1}px`;
		tab_button.style.borderRadius = "5px";
	}
	DOTA_SHOP.TABS.style.flowChildren = "right-wrap;";
	DOTA_SHOP.TABS.style.height = "65px";
	DOTA_SHOP.TABS.style.paddingLeft = "1px";

	DOTA_SHOP.CONTENTS.style.marginTop = "0px";
}
function HideDefaultTabs() {
	for (const tab of DOTA_SHOP.TABS.Children()) {
		if (!tab.b_custom_tab) tab.visible = false;
	}
}
function DeleteOldTabs() {
	for (const tab of DOTA_SHOP.TABS.Children()) if (tab.b_custom_tab) tab.DeleteAsync(0);
}
function DeleteOldContents() {
	for (const content of DOTA_SHOP.CONTENTS.Children()) if (content.b_custom_content) content.DeleteAsync(0);
}
function CreateNewTabs() {
	const sorted_tabs = Object.keys(SHOP_TABS_CONFIG).sort((a, b) => {
		return SHOP_TABS_CONFIG[a].sort_weight - SHOP_TABS_CONFIG[b].sort_weight;
	});

	for (const name of sorted_tabs) CACHED_TABS[name] = new ShopTab(name);
}
function SetupCustomTabs() {
	$.Msg("[ShopExtender] setup retry");
	if (Players.GetPlayerHeroEntityIndex(LOCAL_PLAYER_ID) < 0) return void $.Schedule(0, SetupCustomTabs);
	if (!CacheDotaShopPanels()) return void $.Schedule(0, SetupCustomTabs);

	DeleteOldTabs();
	DeleteOldContents();
	CreateNewTabs();
	const first_tab = DOTA_SHOP.TABS.Children()[0];
	for (const tab_name of Object.keys(CACHED_TABS)) {
		DOTA_SHOP.TABS.MoveChildBefore(CACHED_TABS[tab_name].tab, first_tab);
	}
	HideDefaultTabs();
	UpdateTabsButtonsStyle();
	$.Msg(`[ShopExtender] tabs created: ${Object.keys(CACHED_TABS).join(",")}`);

	const tab_list = [];
	for (const tab of DOTA_SHOP.TABS.Children()) {
		tab_list.push(`${tab.actualid || tab.id}${tab.b_custom_tab ? "(custom)" : ""}=${tab.visible ? "vis" : "hid"}`);
	}
	$.Msg(`[ShopExtender] on-screen tabs: ${tab_list.join(" | ")}`);
}

function UpdateShopExtender(shop_layout) {
	$.Msg(`[ShopExtender] config received, tabs: ${Object.keys(shop_layout).join(",")}`);
	SHOP_TABS_CONFIG = shop_layout;
	$.Schedule(0.1, SetupCustomTabs);
}

function DumpTabsState(tag) {
	if (!DOTA_SHOP.TABS || typeof DOTA_SHOP.TABS == "string") return;
	const offs = DOTA_SHOP.TABS.actualLayoutOffsets || {};
	$.Msg(`[ShopExtender] tabs@${tag}: container x=${offs.left} w=${offs.width} h=${offs.height}`);
	const tab_list = [];
	for (const tab of DOTA_SHOP.TABS.Children()) {
		const o = tab.actualLayoutOffsets || {};
		tab_list.push(`${tab.actualid || tab.id}${tab.b_custom_tab ? "(c)" : ""}:x=${o.left},y=${o.top},w=${o.width},h=${o.height}${tab.visible ? "" : "(hid)"}`);
	}
	tab_list.forEach((line) => $.Msg(`[ShopExtender]   ${line}`));
}

function RefreshCustomTabs() {
	if (!SHOP_TABS_CONFIG) return;
	DumpTabsState("refresh");
	DeleteOldTabs();
	DeleteOldContents();
	CreateNewTabs();
	HideDefaultTabs();
	UpdateTabsButtonsStyle();
}

function PeriodicCheck() {
	if (SHOP_TABS_CONFIG && DOTA_SHOP.MAIN && typeof DOTA_SHOP.MAIN != "string") {
		const any_custom = DOTA_SHOP.TABS.Children().some((t) => t.b_custom_tab);
		if (DOTA_SHOP.MAIN.visible) {
			DumpTabsState("open-check");
			if (!any_custom) RefreshCustomTabs();
		}
	}
	$.Schedule(3, PeriodicCheck);
}

(function () {
	$.Msg("[ShopExtender] init, sending get");
	GameEvents.Subscribe("ShopExtender:update", UpdateShopExtender);
	GameEvents.Subscribe("DOTAShopOpen", RefreshCustomTabs);
	GameEvents.Subscribe("DOTAShopClose", () => DumpTabsState("close"));
	$.Schedule(3, PeriodicCheck);
	GameEvents.SendCustomGameEventToServer("ShopExtender:get", {});
})();
