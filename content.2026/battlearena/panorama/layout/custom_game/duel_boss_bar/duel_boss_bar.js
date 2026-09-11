const DBB = {
	BAR: $("#DBBBar"),
	NAME: $("#DBB_Name"),
	HP_FILL: $("#DBB_HpFill"),
	HP_GHOST: $("#DBB_HpGhost"),
	CAST_TRACK: $("#DBB_CastTrack"),
	CAST_FILL: $("#DBB_CastFill"),
	CAST_ZONE: $("#DBB_CastZone"),
	POST_TRACK: $("#DBB_PostTrack"),
	POST_FILL: $("#DBB_PostFill"),
	BROKEN: $("#DBB_Broken"),
};

function dlog(msg) {
	$.Msg("[DBB] " + msg);
}

dlog("script loaded; panels: BAR=" + !!DBB.BAR + " NAME=" + !!DBB.NAME + " HP=" + !!DBB.HP_FILL + " CAST=" + !!DBB.CAST_TRACK + " POST=" + !!DBB.POST_TRACK + " BROKEN=" + !!DBB.BROKEN);

let ghost = -1;
let dumped = false;

function clamp01(v) {
	if (!v || v < 0) return 0;
	if (v > 1) return 1;
	return v;
}

function dumpPanel(p, tag) {
	try {
		dlog(tag + " layout: x=" + p.actualLayoutX + " y=" + p.actualLayoutY + " w=" + p.actualLayoutWidth + " h=" + p.actualLayoutHeight + " visible=" + p.visible + " opacity=" + p.style.opacity);
	} catch (e2) {
		dlog(tag + " dump error: " + e2);
	}
}

// Видимость — только инлайн-стиль opacity (паттерн китайцев):
// пишется КАЖДЫЙ апдейт в обеих ветках, без классов/visibility.
function ApplyState(s) {
	try {
		const active = !!(s && s.active);

		DBB.BAR.style.opacity = active ? "1" : "0";

		if (!active) {
			ghost = -1;
			return;
		}

		if (!dumped) {
			dumped = true;
			dumpPanel($.GetContextPanel(), "CTX");
			dumpPanel(DBB.BAR, "BAR");
			dumpPanel(DBB.NAME, "NAME");
		}

		if (s.name && DBB.NAME) {
			const loc = $.Localize(s.name);
			DBB.NAME.text = (loc && loc.length > 0) ? loc : s.name.replace("#", "");
			dlog("state active name=" + s.name + " loc=" + loc + " text=" + DBB.NAME.text);
		} else {
			dlog("state active but no name (name=" + s.name + ", NAME panel=" + !!DBB.NAME + ")");
		}

		const hpmax = s.hpmax > 0 ? s.hpmax : 1;
		const frac = clamp01(s.hp / hpmax);

		if (frac > ghost) ghost = frac;
		else if (ghost >= 0) ghost = Math.max(frac, ghost - 0.012);

		DBB.HP_FILL.style.width = `${frac * 100}%`;
		DBB.HP_GHOST.style.width = `${Math.max(0, ghost) * 100}%`;

		// кастбар: заполняется по мере стойки; красная зона = окно контр-брейка
		if (s.cast_total > 0 && s.cast_remain > 0) {
			DBB.CAST_TRACK.style.opacity = "1";

			const progress = clamp01(1 - s.cast_remain / s.cast_total);
			DBB.CAST_FILL.style.width = `${progress * 100}%`;

			const winFrac = clamp01(s.cast_window / s.cast_total);
			DBB.CAST_ZONE.style.width = `${winFrac * 100}%`;

			DBB.CAST_FILL.SetHasClass("InWindow", s.cast_remain <= s.cast_window);
		} else {
			DBB.CAST_TRACK.style.opacity = "0";
			DBB.CAST_FILL.SetHasClass("InWindow", false);
		}

		// поствура: полоса видна ВСЕГДА (как у китайцев), заполняется от урона,
		// мигает перед сломом, «тает» во время стаггера
		const postmax = s.posture_max > 0 ? s.posture_max : 100;
		const postFrac = clamp01(s.posture / postmax);
		DBB.POST_TRACK.style.opacity = "1";
		DBB.POST_FILL.style.width = `${postFrac * 100}%`;
		DBB.POST_FILL.SetHasClass("NearBreak", postFrac >= 0.7);

		DBB.BROKEN.style.opacity = (s.stagger > 0.05) ? "1" : "0";
	} catch (e) {
		dlog("ApplyState ERROR: " + e);
	}
}

CustomNetTables.SubscribeNetTableListener("duel_boss_hud", function (_table, _key, value) {
	dlog("nettable update key=" + _key + " active=" + (value && value.active));
	ApplyState(value);
});

dlog("initial state: " + (function() {
	const v = CustomNetTables.GetTableValue("duel_boss_hud", "state");
	return v ? ("active=" + v.active + " name=" + v.name) : "null";
})());

ApplyState(CustomNetTables.GetTableValue("duel_boss_hud", "state"));