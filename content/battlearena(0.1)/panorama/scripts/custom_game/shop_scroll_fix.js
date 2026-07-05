function GetDotaHud() {
    var panel = $.GetContextPanel();
    while (panel && panel.id !== 'Hud') {
        panel = panel.GetParent();
    }

    if (!panel) {
        throw new Error('Could not find Hud root from panel with id: ' + $.GetContextPanel().id);
    }

    return panel;
}

function FindDotaHudElement(id) {
    return GetDotaHud().FindChildTraverse(id);
}
function FixShopToolsUI(){
    if (!Game.GameStateIsAfter(DOTA_GameState.DOTA_GAMERULES_STATE_STRATEGY_TIME)) {
        $.Schedule(1.0, FixShopToolsUI)
    }
    else {
        let shop = FindDotaHudElement("GridUpgradesCategory")
        let items = shop.FindChildrenWithClassTraverse("ShopItemsRows")[0];
        if (items.style == undefined) {
            items.style = {};
        }
        items.style.overflow = "squish scroll"

        FindDotaHudElement("ItemsContainer").style.overflow = "scroll squish"
    }
}

(function() {
    FixShopToolsUI();  
})();