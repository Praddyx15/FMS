import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ND — Navigation Display with ROSE / ARC / PLAN mode switching
Rectangle {
    id: root
    property var adc
    color: "#0a0c10"
    radius: 4
    border.color: "#2a2d35"
    border.width: 1
    clip: true

    // One-way reflection of the shared EFIS state. FlightDataManager.ndMode is
    // the single source of truth; the mode buttons write to it directly.
    // (Binding here AND writing back on change caused an unbounded binding loop.)
    readonly property string ndMode: FlightDataManager ? FlightDataManager.ndMode : "ARC"

    // Overlay toggles — WXR/TERR/TCAS/WPT mirror the shared EFIS state on
    // FlightDataManager so the EFIS panel and the ND's own toggle bar stay in
    // sync. ARPT/CSTR have no backend field yet → local.
    readonly property bool showWxr:  FlightDataManager ? FlightDataManager.wxrOverlay  : false
    readonly property bool showTerr: FlightDataManager ? FlightDataManager.terrOverlay : false
    readonly property bool showTcas: FlightDataManager ? FlightDataManager.tcasOverlay : false
    readonly property bool showWpt:  FlightDataManager ? FlightDataManager.wptOverlay  : true
    property bool showArpt:  false
    property bool showCstr:  false

    readonly property int rng: FlightDataManager ? FlightDataManager.ndRange : 80
    readonly property bool showVor: FlightDataManager ? FlightDataManager.vorOverlay : true

    // ── ND overlay mock data — ported 1:1 from React src/lib/ndMocks.ts ───────
    property var weatherCells: []
    property var trafficTargets: []
    property var terrainPatches: []

    function mulberry32(seed) {
        var s = seed | 0;
        return function () {
            s = (s + 0x6D2B79F5) | 0;
            var t = Math.imul(s ^ (s >>> 15), s | 1);
            t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
            return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
        };
    }
    function genWeather(range) {
        var rng = mulberry32(12345), cells = [], n = 8 + Math.floor(rng() * 5);
        for (var i = 0; i < n; i++)
            cells.push({ angle: rng() * 360, distance: (rng() * 0.7 + 0.2) * range,
                         intensity: rng() * 0.7 + 0.2, drift: (rng() - 0.5) * 0.5 });
        return cells;
    }
    function genTraffic(range) {
        var rng = mulberry32(54321), arr = [], n = 3 + Math.floor(rng() * 3);
        for (var i = 0; i < n; i++) {
            var ang = rng() * 360, dist = (rng() * 0.6 + 0.15) * range, alt = Math.floor((rng() - 0.5) * 40) * 100, threat = "none";
            if (Math.abs(alt) < 1000) { if (dist < range * 0.15) threat = "resolution"; else if (dist < range * 0.25) threat = "traffic"; else if (dist < range * 0.4) threat = "proximate"; }
            arr.push({ angle: ang, distance: dist, altitude: alt / 100, threat: threat });
        }
        return arr;
    }
    function genTerrain(range, acAlt) {
        var rng = mulberry32(98765), patches = [], n = 20, nc = 3 + Math.floor(rng() * 3), cc = [];
        for (var c = 0; c < nc; c++) cc.push({ angle: rng() * 360, distance: (rng() * 0.6 + 0.2) * range, elevation: (rng() - 0.3) * 3000 });
        for (var i = 0; i < n; i++) {
            var angle = rng() * 360, distance = (rng() * 0.8 + 0.1) * range, minD = Infinity, elev = 0;
            for (var k = 0; k < cc.length; k++) {
                var ad = Math.min(Math.abs(cc[k].angle - angle), 360 - Math.abs(cc[k].angle - angle));
                var d = Math.sqrt(Math.pow(ad * distance / 360, 2) + Math.pow(cc[k].distance - distance, 2));
                if (d < minD) { minD = d; elev = cc[k].elevation * Math.exp(-d / (range * 0.3)); }
            }
            patches.push({ angle: angle, distance: distance, elevation: elev - acAlt, size: 8 + rng() * 12 });
        }
        return patches;
    }
    // organic filled blob (for weather radar paint) — irregular closed shape
    function ndBlob(ctx, x, y, r, seed) {
        ctx.beginPath();
        var pts = 12;
        for (var i = 0; i <= pts; i++) {
            var ang = (i / pts) * 2 * Math.PI;
            var rr = r * (0.74 + 0.26 * Math.abs(Math.sin(ang * 3 + seed) * Math.cos(ang * 2 + seed * 1.7)));
            var px = x + rr * Math.cos(ang), py = y + rr * Math.sin(ang);
            if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
        }
        ctx.closePath(); ctx.fill();
    }
    // 4-point navaid star (magenta off-route waypoints / VOR)
    function ndStar(ctx, x, y, s, col) {
        ctx.strokeStyle = col; ctx.lineWidth = 1.5;
        ctx.beginPath(); ctx.moveTo(x - s, y); ctx.lineTo(x + s, y); ctx.moveTo(x, y - s); ctx.lineTo(x, y + s);
        var h = s * 0.7;
        ctx.moveTo(x - h, y - h); ctx.lineTo(x + h, y + h); ctx.moveTo(x - h, y + h); ctx.lineTo(x + h, y - h);
        ctx.stroke();
    }

    function regenOverlays() {
        weatherCells   = genWeather(rng);
        trafficTargets = genTraffic(rng);
        terrainPatches = genTerrain(rng, adc ? adc.altitude : 32000);
        ndDraw.requestPaint();
    }
    Component.onCompleted: regenOverlays()
    onRngChanged: regenOverlays()

    // ── Mode selector bar ──────────────────────────────────────────────────
    RowLayout {
        id: modeBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 4
        height: 24
        spacing: 2
        z: 10

        Repeater {
            // A320 EFIS modes (per spec): ROSE LS, ROSE VOR, ROSE NAV, ARC, PLAN
            model: [
                { l: "LS",   v: "ROSE_LS"  },
                { l: "VOR",  v: "ROSE_VOR" },
                { l: "NAV",  v: "ROSE_NAV" },
                { l: "ARC",  v: "ARC"      },
                { l: "PLAN", v: "PLAN"     },
            ]
            Rectangle {
                Layout.fillWidth: true
                height: 20
                radius: 3
                property bool active: root.ndMode === modelData.v
                color:  active ? Qt.rgba(0, 0.82, 1.0, 0.18) : "#12141a"
                border.color: active ? Theme.cyan : "#2a2d35"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.l
                    color: parent.active ? Theme.cyan : "#546e7a"
                    font.pixelSize: 8; font.bold: parent.active; font.family: "Consolas"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (FlightDataManager) FlightDataManager.ndMode = modelData.v
                }
            }
        }

        // Range selector
        Rectangle {
            width: 46; height: 20; radius: 3; color: "#12141a"; border.color: "#2a2d35"
            Text {
                anchors.centerIn: parent
                text: FlightDataManager ? FlightDataManager.ndRange + " nm" : "80 nm"
                color: "#78909c"; font.pixelSize: 8; font.family: "Consolas"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!FlightDataManager) return
                    var ranges = [10, 20, 40, 80, 160, 320]
                    var idx = ranges.indexOf(FlightDataManager.ndRange)
                    FlightDataManager.ndRange = ranges[(idx + 1) % ranges.length]
                }
            }
        }
    }

    // ── Heading strip at bottom ────────────────────────────────────────────
    Rectangle {
        id: headingStrip
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 22
        color: "#0d1017"
        border.width: 1; border.color: "#2a2d35"
        z: 10

        RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 8

            // True heading
            Text {
                text: "TRK " + (root.adc ? Math.round(root.adc.heading).toString().padStart(3, "0") + "°" : "---°")
                color: Theme.cyan; font.pixelSize: 10; font.bold: true; font.family: "Consolas"
            }

            Item { Layout.fillWidth: true }

            // Wind vector
            Text {
                text: root.adc
                      ? Math.round(FlightDataManager ? FlightDataManager.windHeading : 270).toString().padStart(3,"0")
                        + "°/" + Math.round(FlightDataManager ? FlightDataManager.windSpeed : 10) + "kt"
                      : "270°/10kt"
                color: Theme.mutedFg; font.pixelSize: 9; font.family: "Consolas"
            }

            Item { Layout.fillWidth: true }

            // DTG / ETA placeholder
            Text {
                text: "GS " + (root.adc ? Math.round(root.adc.groundSpeed) : "---") + "kt"
                color: Theme.mutedFg; font.pixelSize: 9; font.family: "Consolas"
            }
        }
    }

    // ── Overlay toggle bar ─────────────────────────────────────────────────
    RowLayout {
        id: overlayBar
        anchors.bottom: headingStrip.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 4
        height: 20
        spacing: 3
        z: 10

        Repeater {
            model: [
                { label: "WXR",  fdm: "wxrOverlay"  },
                { label: "TERR", fdm: "terrOverlay" },
                { label: "TCAS", fdm: "tcasOverlay" },
                { label: "WPT",  fdm: "wptOverlay"  },
                { label: "ARPT", local: "showArpt" },
                { label: "CSTR", local: "showCstr" },
            ]
            Rectangle {
                Layout.preferredWidth: 36; height: 16; radius: 3
                property bool active: modelData.fdm ? (FlightDataManager ? FlightDataManager[modelData.fdm] : false)
                                                    : root[modelData.local]
                color:  active ? Qt.rgba(0, 0.9, 1, 0.15) : "#12141a"
                border.color: active ? Theme.cyan : "#2a2d35"
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: parent.active ? Theme.cyan : "#455a6c"
                    font.pixelSize: 7; font.bold: parent.active; font.family: "Consolas"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (modelData.fdm) { if (FlightDataManager) FlightDataManager[modelData.fdm] = !FlightDataManager[modelData.fdm] }
                        else root[modelData.local] = !root[modelData.local]
                    }
                }
            }
        }
    }

    // ── Main ND Canvas — single coherent render (ported from React ND modes) ─
    Item {
        id: ndCanvas
        anchors.top: modeBar.bottom
        anchors.bottom: overlayBar.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 4
        clip: true

        Rectangle { anchors.fill: parent; color: "#000000" }   // ND background is pure black

        Canvas {
            id: ndDraw
            anchors.fill: parent
            renderTarget: Canvas.Image
            renderStrategy: Canvas.Immediate
            // Repaint at ~10 Hz (compass/overlays change slowly). Avoids the
            // per-repaint Canvas memory cost of running at the full 30 Hz, and
            // we never call ctx.reset() (that was leaking native memory here).
            Timer { interval: 100; running: true; repeat: true; onTriggered: ndDraw.requestPaint() }

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = "#000000"; ctx.fillRect(0, 0, width, height);

                var s = Math.min(width, height) / 500;
                ctx.save();
                ctx.translate((width - 500 * s) / 2, (height - 500 * s) / 2); ctx.scale(s, s);

                var mode  = root.ndMode;
                var hdg   = root.adc ? root.adc.heading : 0;
                var range = root.rng;
                var isArc  = (mode === "ARC");
                var isPlan = (mode === "PLAN");
                var cx = 250, cy = isArc ? 350 : 250;
                var Rpx = isArc ? 250 : 200;       // full-range radius

                // distance(NM) + true bearing(deg) -> screen point
                function pt(distNM, brg) {
                    var rel = (isPlan ? brg : brg - hdg) * Math.PI / 180;
                    var rpx = (distNM / range) * Rpx;
                    return [cx + rpx * Math.sin(rel), cy - rpx * Math.cos(rel)];
                }

                // ── Range rings (green) ──────────────────────────────────────
                ctx.strokeStyle = "#b8c0cc"; ctx.lineWidth = 1;
                var rings = [range / 4, range / 2, range * 3 / 4, range];
                var topA = -Math.PI / 2;
                var halfSpan = isArc ? (62 * Math.PI / 180) : Math.PI;   // ARC: ±62°, ROSE: full
                for (var ri = 0; ri < rings.length; ri++) {
                    var rad = (rings[ri] / range) * Rpx;
                    for (var ang = -halfSpan; ang < halfSpan - 0.001; ang += 0.17) {
                        ctx.beginPath();
                        ctx.arc(cx, cy, rad, topA + ang, topA + Math.min(ang + 0.10, halfSpan));
                        ctx.stroke();
                    }
                    // half/full range labels (cyan) on the left
                    if (ri === 1 || ri === 3) {
                        ctx.fillStyle = "#00ffff"; ctx.font = "11px monospace"; ctx.textAlign = "center"; ctx.textBaseline = "middle";
                        ctx.fillText(Math.round(rings[ri]).toString(), cx - rad * 0.71, cy - rad * 0.71 + (isArc ? rad * 0.71 : 0));
                    }
                }

                // ── Compass scale (white) ────────────────────────────────────
                ctx.textAlign = "center"; ctx.textBaseline = "middle";
                var tickOuter = isArc ? 250 : 200;
                for (var b = 0; b < 360; b += 5) {
                    var rel = isPlan ? b : b - hdg;
                    while (rel > 180) rel -= 360; while (rel < -180) rel += 360;
                    if (isArc && Math.abs(rel) > 62) continue;
                    var a = rel * Math.PI / 180;
                    var major = (b % 10 === 0), card = (b % 90 === 0);
                    var inner = tickOuter - (card ? 16 : major ? 12 : 7);
                    ctx.strokeStyle = "#ffffff"; ctx.lineWidth = card ? 2 : major ? 1.4 : 0.8;
                    ctx.beginPath();
                    ctx.moveTo(cx + inner * Math.sin(a), cy - inner * Math.cos(a));
                    ctx.lineTo(cx + tickOuter * Math.sin(a), cy - tickOuter * Math.cos(a));
                    ctx.stroke();
                    if (b % 30 === 0) {
                        var lbl = card ? (b === 0 ? "N" : b === 90 ? "E" : b === 180 ? "S" : "W") : (b / 10).toString();
                        var lr = tickOuter - 28;
                        ctx.fillStyle = "#ffffff"; ctx.font = (card ? "bold 18px monospace" : "13px monospace");
                        ctx.fillText(lbl, cx + lr * Math.sin(a), cy - lr * Math.cos(a));
                    }
                }

                // ── Heading/track line (green) ───────────────────────────────
                ctx.strokeStyle = "#00ff00"; ctx.lineWidth = 2; ctx.globalAlpha = 0.8;
                ctx.beginPath(); ctx.moveTo(cx, cy);
                if (isPlan) { var tr = (hdg - 90) * Math.PI / 180; ctx.lineTo(cx + Rpx * Math.cos(tr), cy + Rpx * Math.sin(tr)); }
                else        { ctx.lineTo(cx, cy - (isArc ? 250 : 200)); }
                ctx.stroke(); ctx.globalAlpha = 1.0;

                // ── Selected-heading bug (cyan) ──────────────────────────────
                if (root.adc && !isPlan) {
                    var bug = (root.adc.selectedHeading - hdg);
                    while (bug > 180) bug -= 360; while (bug < -180) bug += 360;
                    if (!(isArc && Math.abs(bug) > 62)) {
                        var ba = bug * Math.PI / 180, br = isArc ? 250 : 200;
                        ctx.fillStyle = "#00ffff";
                        ctx.beginPath();
                        ctx.moveTo(cx + br * Math.sin(ba), cy - br * Math.cos(ba));
                        ctx.lineTo(cx + (br + 12) * Math.sin(ba - 0.035), cy - (br + 12) * Math.cos(ba - 0.035));
                        ctx.lineTo(cx + (br + 12) * Math.sin(ba + 0.035), cy - (br + 12) * Math.cos(ba + 0.035));
                        ctx.closePath(); ctx.fill();
                    }
                }

                function fwd(rel) { while (rel > 180) rel -= 360; while (rel < -180) rel += 360; return !isArc || Math.abs(rel) < 90; }

                // ── Terrain — EGPWS stippled dot pattern (red/amber/cyan) ────
                if (root.showTerr) for (var ti = 0; ti < root.terrainPatches.length; ti++) {
                    var tp = root.terrainPatches[ti]; if (!fwd(tp.angle - hdg)) continue;
                    var p = pt(tp.distance, tp.angle);
                    ctx.fillStyle = tp.elevation > 1000 ? "#ff2020" : tp.elevation > -250 ? "#d2a000" : "#10c0c0";
                    var prad = tp.size * 1.3;
                    for (var gx = -prad; gx <= prad; gx += 5) {
                        for (var gy = -prad; gy <= prad; gy += 5) {
                            if (gx * gx + gy * gy > prad * prad) continue;
                            if (((Math.round(gx) + Math.round(gy) + ti) % 2) === 0) continue; // checker = density
                            ctx.fillRect(p[0] + gx, p[1] + gy, 1.8, 1.8);
                        }
                    }
                }

                // ── Weather — filled radar paint, green→amber→red→magenta ────
                if (root.showWxr) for (var wi = 0; wi < root.weatherCells.length; wi++) {
                    var wc = root.weatherCells[wi]; if (!fwd(wc.angle - hdg)) continue;
                    var wp = pt(wc.distance, wc.angle);
                    var baseR = 16 + wc.intensity * 26;
                    ctx.globalAlpha = 0.9;
                    ctx.fillStyle = "#00b800"; root.ndBlob(ctx, wp[0], wp[1], baseR, wi);                          // green
                    if (wc.intensity > 0.4)  { ctx.fillStyle = "#d8c800"; root.ndBlob(ctx, wp[0], wp[1], baseR * 0.64, wi + 7); }  // yellow
                    if (wc.intensity > 0.6)  { ctx.fillStyle = "#e01010"; root.ndBlob(ctx, wp[0], wp[1], baseR * 0.4,  wi + 13); } // red
                    if (wc.intensity > 0.85) { ctx.fillStyle = "#e000e0"; root.ndBlob(ctx, wp[0], wp[1], baseR * 0.2,  wi + 19); } // magenta core
                }
                ctx.globalAlpha = 1.0;

                // ── Active flight plan — green line + green waypoints (A320) ──
                var wps = FlightDataManager ? FlightDataManager.waypoints : [];
                var n = Math.min(wps.length, 5);
                if (n > 1) {
                    ctx.strokeStyle = "#00e000"; ctx.lineWidth = 2.5;
                    ctx.beginPath();
                    for (var li = 0; li < n; li++) {
                        var ld = (li + 1) * 50, la = (li * 12 - 15) * Math.PI / 180;
                        var lx = cx + ld * Math.sin(la), ly = cy - ld * Math.cos(la);
                        if (li === 0) ctx.moveTo(lx, ly); else ctx.lineTo(lx, ly);
                    }
                    ctx.stroke();
                }
                if (root.showWpt) for (var i = 0; i < n; i++) {
                    var wd = (i + 1) * 50, wa = (i * 12 - 15) * Math.PI / 180;
                    var x = cx + wd * Math.sin(wa), y = cy - wd * Math.cos(wa);
                    ctx.strokeStyle = "#00e000"; ctx.lineWidth = 1.5;   // green diamond
                    ctx.beginPath(); ctx.moveTo(x, y - 5); ctx.lineTo(x + 5, y); ctx.lineTo(x, y + 5); ctx.lineTo(x - 5, y); ctx.closePath(); ctx.stroke();
                    ctx.fillStyle = "#00e000"; ctx.font = "12px monospace"; ctx.textAlign = "left"; ctx.textBaseline = "middle";
                    ctx.fillText(wps[i].name !== undefined ? wps[i].name : "WPT", x + 9, y - 7);
                    if (root.showCstr && i === 0) { ctx.fillStyle = "#ff00ff"; ctx.font = "9px monospace"; ctx.fillText("250/+", x + 9, y + 7); }
                }

                // ── Off-route waypoints / VOR (magenta stars, A320) ──────────
                if (root.showVor) {
                    var navs = [ { d: range * 0.55, b: hdg + 42, name: "FRA" }, { d: range * 0.72, b: hdg - 58, name: "RID" },
                                 { d: range * 0.45, b: hdg + 80, name: "DKB" }, { d: range * 0.62, b: hdg - 88, name: "KRH" } ];
                    for (var ni = 0; ni < navs.length; ni++) {
                        if (!fwd(navs[ni].b - hdg)) continue;
                        var np = pt(navs[ni].d, navs[ni].b);
                        root.ndStar(ctx, np[0], np[1], 5, "#ff40ff");
                        ctx.fillStyle = "#ff40ff"; ctx.font = "11px monospace"; ctx.textAlign = "left"; ctx.textBaseline = "middle";
                        ctx.fillText(navs[ni].name, np[0] + 8, np[1]);
                    }
                }

                // ── Traffic — TCAS symbology (other / proximate / TA / RA) ───
                if (root.showTcas) for (var tri = 0; tri < root.trafficTargets.length; tri++) {
                    var tt = root.trafficTargets[tri]; if (!fwd(tt.angle - hdg)) continue;
                    var tpp = pt(tt.distance, tt.angle); var X = tpp[0], Y = tpp[1];
                    var thr = tt.threat;
                    if (thr === "resolution") {            // RA — filled red square
                        ctx.fillStyle = "#ff0000"; ctx.fillRect(X - 5, Y - 5, 10, 10);
                    } else if (thr === "traffic") {        // TA — filled amber circle
                        ctx.fillStyle = "#ffaa00"; ctx.beginPath(); ctx.arc(X, Y, 6, 0, 2 * Math.PI); ctx.fill();
                    } else if (thr === "proximate") {      // proximate — filled cyan diamond
                        ctx.fillStyle = "#00ffff"; ctx.beginPath(); ctx.moveTo(X, Y - 6); ctx.lineTo(X + 6, Y); ctx.lineTo(X, Y + 6); ctx.lineTo(X - 6, Y); ctx.closePath(); ctx.fill();
                    } else {                               // other — hollow white diamond
                        ctx.strokeStyle = "#ffffff"; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.moveTo(X, Y - 6); ctx.lineTo(X + 6, Y); ctx.lineTo(X, Y + 6); ctx.lineTo(X - 6, Y); ctx.closePath(); ctx.stroke();
                    }
                    var above = tt.altitude >= 0;
                    var lcol = thr === "resolution" ? "#ff0000" : thr === "traffic" ? "#ffaa00" : "#ffffff";
                    ctx.fillStyle = lcol; ctx.font = "10px monospace"; ctx.textAlign = "center"; ctx.textBaseline = "middle";
                    ctx.fillText((above ? "+" : "−") + Math.abs(tt.altitude), X, above ? Y - 13 : Y + 13);
                    // vertical-trend arrow
                    ctx.strokeStyle = lcol; ctx.lineWidth = 1;
                    ctx.beginPath(); ctx.moveTo(X + 10, Y - 5); ctx.lineTo(X + 10, Y + 5); ctx.stroke();
                    if (above) { ctx.beginPath(); ctx.moveTo(X + 10, Y - 5); ctx.lineTo(X + 8, Y - 2); ctx.moveTo(X + 10, Y - 5); ctx.lineTo(X + 12, Y - 2); ctx.stroke(); }
                    else       { ctx.beginPath(); ctx.moveTo(X + 10, Y + 5); ctx.lineTo(X + 8, Y + 2); ctx.moveTo(X + 10, Y + 5); ctx.lineTo(X + 12, Y + 2); ctx.stroke(); }
                }

                // ── Own aircraft symbol (amber) ──────────────────────────────
                ctx.save(); ctx.translate(cx, cy);
                if (isPlan) ctx.rotate(hdg * Math.PI / 180);
                ctx.fillStyle = "#ffaa00"; ctx.strokeStyle = "#000000"; ctx.lineWidth = 1.5;
                ctx.beginPath(); ctx.moveTo(0, -15); ctx.lineTo(-12, 12); ctx.lineTo(0, 6); ctx.lineTo(12, 12); ctx.closePath();
                ctx.fill(); ctx.stroke();
                ctx.restore();

                ctx.restore();
            }
        }

        // PLAN mode fixed-north label
        Text {
            visible: root.ndMode === "PLAN"
            anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 4
            text: "↑ N"
            color: "#ff0000"; font.pixelSize: 12; font.bold: true; font.family: "monospace"
        }
    }
}
