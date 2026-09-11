const HUD = {
	CONTEXT: $.GetContextPanel(),
	GAUGES_ROOT: $("#OG"),
	GAUGES_BARS: $("#OG_Bars"),
	KL_TEXT: $("#KillLimit_Text"),
};

function PingKillLimit() {
	if (!GameUI.IsAltDown()) return;

	PerformWithCooldown(HUD.CONTEXT, 1, () => {
		GameEvents.SendCustomGameEventToServer("GameLoop:ping_kill_limit", {});
	});
}

class OrbGauge {
	constructor(type) {
		const gauge = $.CreatePanel("Panel", HUD.GAUGES_BARS, `OrbGauge_${type}`);
		gauge.BLoadLayoutSnippet("OrbGauge");
		this.gauge = gauge;
		this.fill = gauge.FindChildTraverse("OG_Fill");

		gauge.SetPanelEvent("onmouseover", () => {
			$.DispatchEvent("DOTAShowTextTooltip", gauge, `#augments_bar_hint_${type}`);
		});

		gauge.SetPanelEvent("onmouseout", () => {
			$.DispatchEvent("DOTAHideTextTooltip");
		});

		this.value = 0;
		this.max_value = 100;
		$.Schedule(0.04, () => {
			this.UpdateValue();
		});
	}
	SetValue(value) {
		this.value = value;
		this.UpdateValue();
	}
	SetMaxValue(max_value) {
		this.max_value = max_value;
		this.UpdateValue();
	}
	UpdateValue() {
		this.gauge.SetDialogVariable("current", Math.rd(this.value, 2));
		this.gauge.SetDialogVariable("maximum", Math.rd(this.max_value, 2));
		this.fill.style.width = `${(this.value / this.max_value) * 100}%;`;
	}
}

const CACHED_GAUGES = {};
function CreateGauges() {
	HUD.GAUGES_BARS.RemoveAndDeleteChildren();

	CACHED_GAUGES[1] = new OrbGauge("Common");
	CACHED_GAUGES[2] = new OrbGauge("Rare");
	CACHED_GAUGES[4] = new OrbGauge("Epic");
}

function MoveGauges() {
	const topbar = FindDotaHudElement("topbar");
	if (!topbar) return void $.Schedule(0.1, MoveGauges);

	const ex_panel = topbar.FindChildTraverse("OG");
	if (ex_panel) ex_panel.DeleteAsync(0);

	$.Schedule(1, () => {
		HUD.GAUGES_ROOT.SetParent(topbar);
	});
}

function OnOrbsUpdate(event) {
	const update_values = (value_type, function_name) => {
		for (const [tier, progress_value] of Object.entries(event[value_type])) {
			const gauge = CACHED_GAUGES[tier];
			if (!gauge) continue;

			gauge[function_name](progress_value);
		}
	};

	update_values("filled", "SetValue");
	update_values("needed", "SetMaxValue");
}

function CheckDeadHeroes() {
	let any_dead = false;
	for (let player_id = 0; player_id < 10; player_id++) {
		const player_info = Game.GetPlayerInfo(player_id);
		if (!player_info) continue;

		if (player_info.player_respawn_seconds != undefined && player_info.player_respawn_seconds > 0) {
			any_dead = true;
		}
	}

	HUD.GAUGES_ROOT.SetHasClass("AnyHeroDead", any_dead);

	$.Schedule(0.5, CheckDeadHeroes);
}

(() => {
	CreateGauges();
	MoveGauges();
	CheckDeadHeroes();
	HUD.KL_TEXT.GetParent().SetDialogVariable("kill_limit", 100);

	GameEvents.Subscribe("Augments:update_orbs", OnOrbsUpdate);

	GameEvents.SendCustomGameEventToServer("Augments:get_orbs", {});
})();
