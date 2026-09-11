// ============================================================
// Battle Arena — topbar_custom_icons.js
// Кастомные иконки кастомных героев (stegius/saber/arthas):
//   1) верхняя панель (топбар) — подмена картинки в слотах игроков;
//   2) миникарта — оверлей своих иконок поверх ванильной.
//
// Проблема: ванильный HUD резолвит иконку героя через клиентский реестр;
// кастомные имена (IsCustom без override_hero) реестром не распознаются →
// в топбаре пусто, на миникарте белый круг.
//
// Топбар: слоты имеют id "RadiantPlayer<pid>"/"DirePlayer<pid>", внутри —
// панель "HeroImage" (DOTAHeroImage без атрибутов). Героя узнаём через
// Game.GetPlayerInfo(pid).player_selected_hero (паттерн Valve
// shared_scoreboard_updater.js). Для кастомных героев переустанавливаем
// картинку: SetImage("s2r://panorama/images/heroes/<hero>_png.vtex") —
// проверенный рабочий путь для кастомных героев (custom_pick.js).
// Тикер: движок может перезаписывать картинку — переустанавливаем.
//
// Миникарта: контейнер-оверлей ре-парентится в ванильный minimap_block
// (паттерн BS dynamic_minimap). Позиции: Game.GetMapInfo() (границы мира)
// → проценты UI (Y инвертирован). Иконки только кастомных героев.
// ============================================================

(function () {
	"use strict";

	var CUSTOM_HEROES = ["npc_dota_hero_stegius", "npc_dota_hero_saber", "npc_dota_hero_arthas", "npc_dota_hero_stargazer"];

	var topbar = null;
	var minimapBlock = null;
	var dmRoot = null;
	var overlayRoot = null;
	var overlayIcons = {}; // pid -> {panel, hero}
	var lastReplaced = {}; // {heroName: time} — троттлинг Msg
	var mapInfo = null;
	var logTime = 0;
	var minimapLogTime = 0;
	var syncDiagTime = 0;

	// Своя реализация FindDotaHudElement: подъём до КОРНЯ панорамы, оттуда
	// FindChildTraverse (панель может лежать вне поддерева CustomUIContainer_Hud,
	// напр. движковая DynamicMinimapRoot — проверено 2026-08-12).
	function findHudElement(id) {
		var root = $.GetContextPanel();
		while (root && root.GetParent) {
			var parent = root.GetParent();
			if (!parent) break;
			root = parent;
		}
		if (root && root.FindChildTraverse) {
			return root.FindChildTraverse(id);
		}
		return null;
	}

	function isCustomHero(name) {
		return CUSTOM_HEROES.indexOf(name) !== -1;
	}

	// Миникарта: 32x32 мини-иконка из icons/ (движковый размер миникарта-иконок,
	// как ванильные minimap_heroicon_*). Топбар: портрет из heroes/.
	function heroIconUrl(heroName) {
		return "s2r://panorama/images/heroes/icons/" + heroName + "_png.vtex";
	}

	function heroPortraitUrl(heroName) {
		return "s2r://panorama/images/heroes/" + heroName + "_png.vtex";
	}

	function logOnce(msg) {
		var t = Game.GetGameTime ? Game.GetGameTime() : 0;
		if (!logTime || t - logTime > 15) {
			logTime = t;
			$.Msg("[TopBarCustomIcons] " + msg);
		}
	}

	function logMinimap(msg) {
		var t = Game.GetGameTime ? Game.GetGameTime() : 0;
		if (!minimapLogTime || t - minimapLogTime > 15) {
			minimapLogTime = t;
			$.Msg("[TopBarCustomIcons] " + msg);
		}
	}

	// ==================== ТОПБАР ====================

	function applyTopbar() {
		if (!topbar || !topbar.FindChildTraverse) return;

		var players = [];
		try {
			players = Game.GetAllPlayerIDs();
		} catch (e) {
			return;
		}

		for (var i = 0; i < players.length; i++) {
			var pid = players[i];
			var info = null;
			try {
				info = Game.GetPlayerInfo(pid);
			} catch (e) {
				continue;
			}
			if (!info || !info.player_selected_hero) continue;

			var heroName = info.player_selected_hero;
			if (!isCustomHero(heroName)) continue;

			var slot = topbar.FindChildTraverse("RadiantPlayer" + pid) ||
				topbar.FindChildTraverse("DirePlayer" + pid);
			if (!slot) continue;

			var heroImage = slot.FindChildTraverse("HeroImage");
			if (!heroImage || !heroImage.SetImage) continue;

			heroImage.SetImage(heroPortraitUrl(heroName));
			logOnce("topbar: icon set for " + heroName + " (pid " + pid + ")");
		}
	}

	// ==================== МИНИКАРТА ====================

	// Проценты миникарты считает СЕРВЕР (lib/hero_minimap_icons.lua:
	// GetWorldMinBound/GetWorldMaxBound; фолбэк MAP_LENGTH=8192, паттерн BS
	// WorldPosToMinimap — карта 5v5 симметричная ±8192, проверено 2026-08-12) —
	// клиентский Game.GetMapInfo() в этой сборке пуст.
	//
	// Родитель оверлея — ДВИЖКОВАЯ панель #DynamicMinimapRoot (создаётся
	// клиентом Dota поверх миникарты специально для кастомных точек, паттерн
	// BS dynamic_minimap): проценты от неё = точная позиция на карте.
	// Оверлей в minimap_block/minimap НЕ работает: панели ложились не туда
	// (иконка "в центре" при 93%,93% — диагностировано 2026-08-12).

	function setupOverlay() {
		if (overlayRoot) return true;
		if (!dmRoot) {
			dmRoot = findHudElement("DynamicMinimapRoot");
			if (dmRoot) logMinimap("minimap: DynamicMinimapRoot found");
		}
		if (!minimapBlock) {
			minimapBlock = findHudElement("minimap_block");
			if (minimapBlock) logMinimap("minimap: minimap_block found");
		}
		var overlayParent = dmRoot || minimapBlock;
		if (!overlayParent) {
			logMinimap("minimap: DynamicMinimapRoot AND minimap_block NOT found");
			return false;
		}
		try {
			overlayRoot = $.CreatePanel("Panel", overlayParent, "TopBarCustomIcons_Overlay");
			overlayRoot.style.width = "100%";
			overlayRoot.style.height = "100%";
			overlayRoot.hittest = false;
			overlayRoot.SetAcceptsFocus(false);
			diagLayout("minimap: overlay parent", overlayParent);
			if (overlayParent.FindChildTraverse) {
				var mp = overlayParent.FindChildTraverse("minimap");
				if (mp) diagLayout("minimap: inner minimap panel", mp);
			}
		} catch (e) {
			logMinimap("minimap: overlay create failed: " + e);
			return false;
		}
		return true;
	}

	function diagLayout(label, panel) {
		try {
			var info = " id=" + panel.id + " class=" + (panel.class || "") + " B=" + panel.BHasClass;
			if (panel.actuallayoutwidth !== undefined) {
				info += " actualW=" + panel.actuallayoutwidth + " actualH=" + panel.actuallayoutheight
					+ " contentW=" + panel.contentwidth + " contentH=" + panel.contentheight;
			}
			// первые дети (id/class)
			if (panel.GetChildCount) {
				var n = panel.GetChildCount();
				info += " children=" + n + ":";
				for (var ci = 0; ci < Math.min(n, 6); ci++) {
					try {
						var ch = panel.GetChild(ci);
						info += " [" + (ch.id || "?") + "/" + (ch.class || "") + "]";
					} catch (e) { break; }
				}
			}
			$.Msg("[TopBarCustomIcons] " + label + info);
		} catch (e) {
			$.Msg("[TopBarCustomIcons] " + label + " diag failed: " + e);
		}
	}

	function applyMinimap() {
		if (!setupOverlay()) return;

		var players = [];
		try {
			players = Game.GetAllPlayerIDs();
		} catch (e) {
			return;
		}

		var seen = {};

		for (var i = 0; i < players.length; i++) {
			var pid = players[i];
			// Позиции кастомных героев шлёт сервер (lib/hero_minimap_icons.lua) —
			// клиентский Entities.GetEntityByIndex в этой сборке отсутствует
			var data = CustomNetTables.GetTableValue("hero_minimap_icons", String(pid));
			if (!data || !data.hero || data.x === undefined || data.y === undefined) continue;
			var heroName = data.hero;
			if (!isCustomHero(heroName)) continue;
			seen[pid] = true;

			var icon = overlayIcons[pid];
			if (!icon || icon.hero !== heroName) {
				if (icon && icon.panel) icon.panel.DeleteAsync(0);
				var panel = $.CreatePanel("Image", overlayRoot, "TBCI_Icon_" + pid);
				panel.SetImage(heroIconUrl(heroName));
				panel.style.width = "32px";
				panel.style.height = "32px";
				panel.style.transform = "translateX(-50%) translateY(-50%)";
				panel.hittest = false;
				overlayIcons[pid] = { panel: panel, hero: heroName };
				icon = overlayIcons[pid];
				// разовый лог при создании (не троттлится — это событие)
				$.Msg("[TopBarCustomIcons] minimap: ICON CREATED for " + heroName + " pid " + pid
					+ " in " + (overlayRoot.id || overlayRoot.class || "?"));
			}

			// ⚠️ style.position в этой сборке НЕ работает для runtime-панелей
			// (панель оставалась в (0,0) — диагностировано 2026-08-12 через
			// px-тест "120px 120px 0"). Рабочий способ — marginLeft/marginTop
			// (проценты от родителя minimap_block).
			// DIAG: для pid 0 — px-тест марджинов (120px,120px).
			var mx = (pid === 0) ? "120px" : (data.x + "%");
			var my = (pid === 0) ? "120px" : (data.y + "%");
			icon.panel.style.marginLeft = mx;
			icon.panel.style.marginTop = my;
			if (!icon.diaged) {
				icon.diaged = true;
				$.Msg("[TopBarCustomIcons] minimap: margin " + mx + " " + my + " for pid " + pid);
				diagLayout("minimap: icon panel", icon.panel);
			}
		}

		for (var pidKey in overlayIcons) {
			if (!seen[pidKey]) {
				overlayIcons[pidKey].panel.DeleteAsync(0);
				delete overlayIcons[pidKey];
			}
		}
	}

	// ==================== ТИКЕР ====================

	function tick() {
		// try/catch: одна ошибка не должна убивать тикер (иначе всё молча
		// отключается до рестарта — диагностировано 2026-08-12)
		try {
			if (!topbar) {
				topbar = findHudElement("topbar");
			}
			if (topbar) applyTopbar();
			// applyMinimap() ОТКЛЮЧЁН 2026-08-12: движковая иконка кастомного
			// героя теперь рисуется штатно (mod_textures.txt + перекрытый лист
			// minimap_hero_sheet_psd_3529892a.vtex_c, см. AGENTS.md), оверлей
			// давал дубль-иконку в (0,0). Код оставлен для отката.
			// applyMinimap();
		} catch (e) {
			$.Msg("[TopBarCustomIcons] tick error: " + e);
		}
		$.Schedule(0.25, tick);
	}

	$.Schedule(0.5, tick);
})();
