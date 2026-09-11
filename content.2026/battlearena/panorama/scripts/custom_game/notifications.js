const KILLSTREAK_ROOT = FindDotaHudElement("KillStreak") || FindDotaHudElement("DotaHud");
const NOTIFICATIONS_POOL = [];

function InitNotificationsPool() {
	if (!KILLSTREAK_ROOT) return;

	for (let index = 0; index < 5; index++) {
		const notification = $.CreatePanel("Label", KILLSTREAK_ROOT, "", {
			html: true,
			text: "{s:text}",
		});
		notification.style.fontSize = "22px";
		notification.style.fontWeight = "bold";
		notification.style.color = "#ffd900";
		notification.style.textShadow = "0px 0px 4px 2.0 #000000cc";
		notification.style.horizontalAlign = "center";
		notification.style.verticalAlign = "top";
		notification.style.marginTop = "95px";
		notification.style.flowChildren = "down";
		notification.visible = false;
		KILLSTREAK_ROOT.MoveChildBefore(notification, KILLSTREAK_ROOT.GetChild(0));
		NOTIFICATIONS_POOL.push(notification);
	}
	KILLSTREAK_ROOT.style.marginTop = "95px";
}

function ShowNotification(token, values, time, style) {
	for (const notification of NOTIFICATIONS_POOL) {
		if (notification.visible) continue;

		for (const [k, v] of Object.entries(style || {})) notification.style[k] = v;

		for (const [k, v] of Object.entries(values || {})) notification.SetDialogVariable(k, v);
		notification.SetDialogVariable("text", $.Localize(token, notification));

		notification.visible = true;
		$.Schedule(time - 0.49, () => {
			notification.style.opacity = "0";
		});
		$.Schedule(time, () => {
			notification.visible = false;
			notification.style.opacity = "1";
		});
		break;
	}
}

function AddNotification(event) {
	ShowNotification(event.token, event.values || {}, event.time || 5, event.style || {});
}

GameUI.AddNotification = AddNotification;

(function () {
	InitNotificationsPool();
	GameEvents.Subscribe("notifications:add", AddNotification);
})();
