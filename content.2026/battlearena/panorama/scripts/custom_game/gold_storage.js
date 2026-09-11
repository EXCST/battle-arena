var GOLD_LABEL = null;
var ORIG_LABEL = null;
var GOLD_CONTAINER = null;

function formatGold(n) {
    if (n < 100000) return String(n);
    if (n < 1000000) return Math.floor(n / 1000) + "К";
    var millions = Math.floor(n / 1000000);
    var thousands = Math.floor((n % 1000000) / 1000);
    if (thousands > 0) return millions + "М" + thousands + "К";
    return millions + "М";
}

function centerGoldLabel() {
    try {
        if (!GOLD_CONTAINER || !GOLD_LABEL) return;
        // вертикальный отступ: половина разницы высоты контейнера и текста.
        // Если замеры недоступны — фикс 12px (прямоугольник 45px, шрифт ~16px).
        var ch = GOLD_CONTAINER.actualLayoutHeight;
        var lh = GOLD_LABEL.actualLayoutHeight;
        var off = 6;
        if (ch && lh) {
            off = Math.max(0, Math.round((ch - lh) / 2) - 6);
        }
        GOLD_LABEL.style.marginTop = off + "px";
        // горизонталь центрируется через width:100% + text-align:center,
        // обнуляем случайный marginLeft от старых версий
        GOLD_LABEL.style.marginLeft = "0px";
    } catch (e) {}
}

(function () {
    try {
        var panel = $.GetContextPanel();
        if (!panel) return;
        panel = panel.GetParent();
        while (panel) {
            var qb = panel.FindChildTraverse("quickbuy");
            if (qb) {
                var orig = qb.FindChildTraverse("GoldLabel");
                if (orig) {
                    var c = orig.GetParent();
                    GOLD_LABEL = c.FindChild("CustomGoldLabel");
                    if (!GOLD_LABEL) {
                        GOLD_LABEL = $.CreatePanel("Label", c, "CustomGoldLabel");
                    }
                    if (GOLD_LABEL) {
                        ORIG_LABEL = orig;
                        // 1) прячем оригинальный лейбл самым первым действием,
                        //    каждое присваивание в своём try/catch
                        try { orig.visible = false; } catch (e) {}
                        try { orig.style.opacity = "0"; } catch (e) {}

                        // 2) копируем вид оригинального лейбла (жёлтый цвет, шрифт, тень).
                        //    Каждое свойство отдельно, чтобы одно неудачное не ломало остальные
                        try { GOLD_LABEL.style.fontFamily = orig.style.fontFamily; } catch (e) {}
                        try { GOLD_LABEL.style.fontSize = "20px"; } catch (e) {}
                        try { GOLD_LABEL.style.fontWeight = orig.style.fontWeight; } catch (e) {}
                        try { GOLD_LABEL.style.color = orig.style.color || "#E8C44D"; } catch (e) {}
                        try { GOLD_LABEL.style.textShadow = orig.style.textShadow; } catch (e) {}
                        try { GOLD_LABEL.style.letterSpacing = orig.style.letterSpacing; } catch (e) {}

                        // 3) выравнивание по центру прямоугольника:
                        //    ширина 100% + text-align центрирует по горизонтали,
                        //    по вертикали лейбл опускается через marginTop из замеров
                        //    (centerGoldLabel) — vertical-align здесь не работает
                        try { GOLD_LABEL.style.horizontalAlign = "center"; } catch (e) {}
                        try { GOLD_LABEL.style.textAlign = "center"; } catch (e) {}
                        try { GOLD_LABEL.style.width = "100%"; } catch (e) {}
                        GOLD_CONTAINER = c;

                        try { GOLD_LABEL.text = "0"; } catch (e) {}
                        try { GOLD_LABEL.title = "0"; } catch (e) {}
                        try { GOLD_LABEL.style.opacity = "1"; } catch (e) {}
                        try { c.MoveChildBefore(GOLD_LABEL, orig); } catch (e) {}
                        try { $.Schedule(0.1, centerGoldLabel); } catch (e) {}
                    }
                }
                break;
            }
            panel = panel.GetParent();
        }
    } catch (e) {}

    if (!GOLD_LABEL) return;

    function poll() {
        try {
            if (ORIG_LABEL && ORIG_LABEL.visible) ORIG_LABEL.visible = false;
            var local = Game.GetLocalPlayerID();
            if (local !== undefined) {
                var data = CustomNetTables.GetTableValue("gold_storage", String(local));
                if (data && data.total !== undefined) {
                    GOLD_LABEL.text = formatGold(data.total);
                    GOLD_LABEL.title = String(data.total);
                    centerGoldLabel();
                }
            }
        } catch (e) {}
        $.Schedule(0.25, poll);
    }
    $.Schedule(0.25, poll);
})();
