// ============================================================
// Battle Arena — mana_pool.js
// Отображение реального манапула героя (обход капа 65535).
//
// Сервер публикует в nettable "mana_pool" (ключ player_id):
//   { cur, max, oc } — cur/max с учётом резерва, oc = резерв-макс.
//
// Ванильная цифра маны (id=ManaLabel) живёт в корне HUD-контекста
// (в дереве несколько экземпляров из шаблонов — ищем ВИДИМЫЙ).
// Когда резерв активен: прячем ванильные цифры (color: transparent) и
// показываем СВОЙ лейбл ВНУТРИ ванильной панели — он наследует её бокс
// 1-в-1 (позиция/центр гарантированы), шрифт MonoNumbersFont.
// ============================================================

(function () {
	"use strict";

	var PANEL_IDS = ["ManaLabel", "ManaNumber", "ManaText", "ManaValue", "HudMana"];

	var label = null;
	var vanillaPanel = null;

	// Рекурсивный сбор ВСЕХ панелей с заданным id (шаблоны порождают дубли)
	function collectPanels(root, id, depth, maxDepth, out) {
		if (!root || depth > maxDepth) return;
		if (root.id === id) out.push(root);
		var count = root.GetChildCount ? root.GetChildCount() : 0;
		for (var i = 0; i < count; i++) {
			var child = root.GetChild(i);
			if (child) collectPanels(child, id, depth + 1, maxDepth, out);
		}
	}

	// Выбираем видимый экземпляр: visible != false и не спрятан предками
	function isEffectivelyVisible(panel) {
		var p = panel;
		var depth = 0;
		while (p && depth < 10) {
			if (p.visible === false) return false;
			var vis = p.style && p.style.visibility;
			if (vis === "collapse" || vis === "hidden") return false;
			p = p.GetParent ? p.GetParent() : null;
			depth++;
		}
		return true;
	}

	function findVanillaManaPanel(root) {
		if (!root || !root.FindChildTraverse) return null;
		for (var i = 0; i < PANEL_IDS.length; i++) {
			var all = [];
			// FindChildTraverse не ограничен глубиной — пробуем его первым
			var direct = root.FindChildTraverse(PANEL_IDS[i]);
			if (direct) all.push(direct);
			collectPanels(root, PANEL_IDS[i], 0, 40, all);
			// Сначала кандидаты, чей родитель называется ManaContainer (живой HUD)
			for (var j = 0; j < all.length; j++) {
				var parent = all[j].GetParent ? all[j].GetParent() : null;
				if (parent && parent.id === "ManaContainer" && isEffectivelyVisible(all[j])) {
					return all[j];
				}
			}
			for (var k = 0; k < all.length; k++) {
				if (isEffectivelyVisible(all[k])) return all[k];
			}
			if (all.length > 0) return all[0];
		}
		return null;
	}

	function setup() {
		var myRoot = $.GetContextPanel();
		if (!myRoot) return;

		// Поднимаемся по цепочке родителей до корня HUD (ванильные панели
		// живут ВЫШЕ CustomUIContainer_Hud, на уровне #Hud).
		var hudRoot = myRoot;
		while (hudRoot && hudRoot.GetParent) {
			hudRoot = hudRoot.GetParent();
			if (!hudRoot) break;
			var found = findVanillaManaPanel(hudRoot);
			if (found) {
				vanillaPanel = found;
				break;
			}
		}

		$.Msg("[ManaPool] vanillaPanel=" + (vanillaPanel ? ("'" + vanillaPanel.id + "'") : "NULL"));

		if (vanillaPanel) {
			try {
				// Свой лейбл ВНУТРИ ванильной панели: наследует её бокс 1-в-1
				label = $.CreatePanel("Label", vanillaPanel, "ManaOvercapLabel");
				label.style.width = "100%";
				label.style.height = "100%";
				label.style.textAlign = "center";
				label.style.verticalAlign = "center";
				label.style.fontFamily = "MonoNumbersFont";
				var st = vanillaPanel.style;
				if (st.fontSize) label.style.fontSize = st.fontSize;
				label.style.letterSpacing = st.letterSpacing || "2px";
				if (st.textShadow) label.style.textShadow = st.textShadow;
				label.style.color = "#ffffff";
				label.text = "--";
				label.hittest = false;
				label.visible = false;
				$.Msg("[ManaPool] inner label created");
			} catch (e) {
				$.Msg("[ManaPool] create inner label failed: " + e);
				label = null;
			}
		}

		if (!label) {
			label = myRoot.FindChildTraverse("ManaOvercapLabel");
			$.Msg("[ManaPool] using own fallback label: " + (label ? "OK" : "MISSING"));
		}
	}

	function format(v) {
		if (v >= 1000000) return Math.floor(v / 1000) + "k";
		return String(Math.floor(v));
	}

	function update(data) {
		var active = !!(data && data.oc > 0);

		if (vanillaPanel) {
			// Скрываем ванильные цифры inline-стилем (перекрывает CSS-правило),
			// возврат — пустая строка (снова действует CSS).
			// ВАЖНО: вместе с цветом гасим и text-shadow — иначе остаётся
			// «тень старого 65536».
			if (active) {
				vanillaPanel.style.color = "transparent";
				vanillaPanel.style.textShadow = "0px 0px 0px #00000000";
			} else {
				// ⚠️ Фикс 2026-08-12: пустая строка цвета НЕ парсится панорамой
				// («Failed to parse style value for color» → JS-исключение при
				// каждом обновлении маны). Возврат — явным валидным значением.
				vanillaPanel.style.color = "#ffffff";
				vanillaPanel.style.textShadow = "0px 0px 6px rgba(0, 0, 0, 0.75)";
			}
		}

		if (!label) return;
		label.visible = active;
		if (active) {
			// пробелы вокруг "/" + letter-spacing дают двойной зазор у разделителя
			label.text = format(data.cur) + " / " + format(data.max);
		}
	}

	CustomNetTables.SubscribeNetTableListener("mana_pool", function (table, key, data) {
		var myPid = Game.GetLocalPlayerID();
		if (String(myPid) !== key) return;
		update(data);
	});

	setup();
})();
