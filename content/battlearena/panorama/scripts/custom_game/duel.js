"use strict";


let g_tick = undefined;

const colorWhite = "#FFFFFF";
const colorYellow = "#FFFF00"
const colorRed = "#FF0000"

let FormatSecondsToTime = (sec) => {
	return Math.floor(sec / 60) + ":" + ('0' + Math.floor(sec % 60)).slice(-2);
}

function UpdateDuelText()
{
	$.Msg("Update Duel Text");
	
	let data = CustomNetTables.GetTableValue( "duel", "info" )
	
	let isDuel = data.is_duel
	let countdown = data.countdown
	let lastDuelTime = data.last_duel_time

	let textBlock = $("#DuelTextBlock")
	textBlock.style.color = colorWhite
	
	function Tick() {
		var timerTime = Math.round(countdown + lastDuelTime - Game.GetGameTime())
		
		if (timerTime <= 15) {
			textBlock.style.color = colorYellow
		}
		if (timerTime <= 5) {
			textBlock.style.color = colorRed
		}
		
		if (!isDuel) {
			// textBlock.text = $.Localize(baseText, textBlock)	
			textBlock.text = "Time before duel: "
		} else {
			textBlock.text = "Duel timer: "
		}
		textBlock.text += FormatSecondsToTime(timerTime);
		
		if (timerTime <= 0) {
			g_tick = undefined;
			textBlock.text = "Waiting..."
			return;
		}

		g_tick = $.Schedule(1.0, () => Tick())
	}
	
	Tick()
	
	// for( let attrName in formatters )
		// textBlock.SetDialogVariable(attrName, formatters[attrName] )
		
	// textBlock.text = $.Localize(baseText, textBlock)	
	// textBlock.style.color = color
}

function CancelTick() {
    if (g_tick != undefined) {
		$.Msg("Cancel Tick Called")
        $.CancelScheduled(g_tick, {});
        g_tick = undefined;
    }
}

(function()
{
	CustomNetTables.SubscribeNetTableListener( "duel", function()
	{
		CancelTick()
		UpdateDuelText()
	})
})();