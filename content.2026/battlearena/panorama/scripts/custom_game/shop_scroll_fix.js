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

let SHOP_SCROLL_DEBUG_LOGED = false;
let SHOP_SCROLL_LAST_HEIGHT = 0;

function ApplyShopScrollFix() {
    const contents = FindDotaHudElement("GridMainShopContents");

    if (contents) {
        const custom_tabs = contents.Children().filter((child) => child.b_custom_content);

        if (custom_tabs.length) {
            // ограниченная область прокрутки: высота HeightLimiter минус сдвиг контента внутри него
            let height = 570;
            let computed = false;
            const limiter = FindDotaHudElement("HeightLimiter");
            if (limiter) {
                let offset = 0;
                let p = contents;
                while (p && p !== limiter && p.IsValid()) {
                    offset += (p.actualLayoutOffsets && p.actualLayoutOffsets.top) || 0;
                    p = p.GetParent();
                }
                const limH = limiter.actualLayoutOffsets && limiter.actualLayoutOffsets.height;
                if (p === limiter && Number.isFinite(limH) && limH > 0) {
                    height = Math.max(300, Math.floor(limH - offset - 4));
                    computed = true;
                }
            }

            for (const tab of custom_tabs) {
                if (!tab.IsValid()) continue;
                tab.style.height = height + "px";

                const rows = tab.FindChildTraverse("GridUpgradeItems");
                if (rows) {
                    rows.style.height = "100%";
                    rows.style.overflow = "squish scroll";
                }
            }

            if (!SHOP_SCROLL_DEBUG_LOGED) {
                SHOP_SCROLL_DEBUG_LOGED = true;
                $.Msg(`[ShopScrollFix] first apply height=${height} computed=${computed} tabs=${custom_tabs.length}`);
            } else if (height !== SHOP_SCROLL_LAST_HEIGHT) {
                $.Msg(`[ShopScrollFix] height changed to ${height} computed=${computed}`);
            }
            SHOP_SCROLL_LAST_HEIGHT = height;
        }
    }

    $.Schedule(2.0, ApplyShopScrollFix);
}

(function () {
    GameEvents.Subscribe("DOTAShopOpen", () => $.Schedule(0.15, ApplyShopScrollFix));
    ApplyShopScrollFix();
})();
