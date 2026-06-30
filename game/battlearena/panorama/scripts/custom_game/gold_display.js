"use strict";

function UpdateGoldDisplay(event) {
    var goldLabel = $("#gold_amount");
    if (goldLabel && event.new_gold !== undefined) {
        goldLabel.text = FormatGold(event.new_gold);
    }
}

function FormatGold(gold) {
    if (gold >= 1000000) {
        return (gold / 1000000).toFixed(1) + "M";
    } else if (gold >= 10000) {
        return (gold / 1000).toFixed(1) + "K";
    }
    return Math.floor(gold).toString();
}

(function () {
    GameEvents.Subscribe("GoldStorage:gold_changed", UpdateGoldDisplay);
})();
