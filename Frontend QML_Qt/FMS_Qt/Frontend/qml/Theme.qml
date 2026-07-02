pragma Singleton
import QtQuick

/*
 * Theme — single source of truth for colours, fonts and dimensions.
 *
 * Ported 1:1 from the React reference design tokens:
 *   - src/index.css   (:root  --cockpit-*, --display-*, --pfd-*, --mcdu-*, --fcu-*)
 *   - tailwind.config.ts
 *
 * Colours are declared with Qt.hsla() using the EXACT same H/S/L fractions the
 * CSS uses, so QML renders them channel-for-channel identically to the browser.
 * (hex comments mirror the values noted in index.css)
 */
QtObject {
    id: theme

    // ── Cockpit chrome ────────────────────────────────────────────────────────
    readonly property color cockpitPrimary:    Qt.hsla(207/360, 0.90, 0.54, 1.0) // #1e90ff Airbus blue
    readonly property color cockpitBackground:  Qt.hsla(0,       0.00, 0.04, 1.0) // #0a0a0a
    readonly property color cockpitPanel:       Qt.hsla(0,       0.00, 0.06, 1.0) // #0f0f0f
    readonly property color cockpitDark:        Qt.hsla(0,       0.00, 0.02, 1.0) // #050505
    readonly property color cockpitBezel:       Qt.hsla(0,       0.00, 0.15, 1.0) // #262626
    readonly property color cockpitBorder:      Qt.hsla(0,       0.00, 0.20, 1.0) // #333333

    // ── Display colours (exact Airbus standards) ──────────────────────────────
    readonly property color green:    Qt.hsla(142/360, 0.71, 0.45, 1.0) // #22c55e FMS green
    readonly property color cyan:     Qt.hsla(186/360, 1.00, 0.50, 1.0) // #00bfff managed/active cyan
    readonly property color magenta:  Qt.hsla(300/360, 1.00, 0.70, 1.0) // #ff66ff selected/pilot magenta
    readonly property color amber:    Qt.hsla(38/360,  0.92, 0.50, 1.0) // #f59e0b caution amber
    readonly property color red:      Qt.hsla(0,       0.84, 0.60, 1.0) // #ef4444 warning red
    readonly property color white:    Qt.hsla(0,       0.00, 0.95, 1.0) // #f2f2f2 standard white

    // ── PFD / ND ──────────────────────────────────────────────────────────────
    readonly property color pfdBackground: Qt.hsla(0,        0.00, 0.02, 1.0) // #050505
    readonly property color pfdSky:         Qt.hsla(210/360, 1.00, 0.40, 1.0) // #0066cc
    readonly property color pfdGround:      Qt.hsla(30/360,  0.60, 0.25, 1.0) // #664422

    // ── MCDU ──────────────────────────────────────────────────────────────────
    readonly property color mcduBackground: Qt.hsla(0,        0.00, 0.00, 1.0) // #000000
    readonly property color mcduText:        Qt.hsla(142/360, 0.71, 0.45, 1.0) // #22c55e
    readonly property color mcduBezel:       Qt.hsla(0,        0.00, 0.08, 1.0) // #141414

    // MCDU on-screen palette — exact mcdu.css values (pure CRT colours).
    // Note: mcduCyan/mcduMagenta/mcduWhite differ from the PFD/ND display tokens.
    readonly property color mcduGreen:   "#22C55E"
    readonly property color mcduCyan:    "#00FFFF"
    readonly property color mcduMagenta: "#FF00FF"
    readonly property color mcduAmber:   "#F59E0B"
    readonly property color mcduRed:     "#EF4444"
    readonly property color mcduWhite:   "#FFFFFF"

    // ── FCU ───────────────────────────────────────────────────────────────────
    readonly property color fcuBackground: Qt.hsla(0,        0.00, 0.10, 1.0) // #1a1a1a
    readonly property color fcuDisplay:     Qt.hsla(0,        0.00, 0.05, 1.0) // #0d0d0d
    readonly property color fcuText:         Qt.hsla(42/360,  1.00, 0.70, 1.0) // #ffcc33 amber display
    readonly property color fcuButton:       Qt.hsla(0,        0.00, 0.15, 1.0) // #262626
    readonly property color fcuActive:       Qt.hsla(186/360, 1.00, 0.50, 1.0) // #00bfff

    // ── Dimmed text / muted (dark theme) ──────────────────────────────────────
    readonly property color foreground:   Qt.hsla(0, 0.00, 0.98, 1.0) // #fafafa
    readonly property color mutedFg:       Qt.hsla(0, 0.00, 0.65, 1.0) // #a6a6a6

    // ── Glow / shadow effect colours ──────────────────────────────────────────
    readonly property color glowGreen: Qt.rgba(34/255,  197/255, 94/255, 0.30)
    readonly property color glowCyan:  Qt.rgba(0,       191/255, 255/255, 0.40)
    readonly property color glowAmber: Qt.rgba(245/255, 158/255, 11/255, 0.40)

    // ── Radii (var(--radius) = 0.5rem = 8px) ──────────────────────────────────
    readonly property int radiusLg: 8
    readonly property int radiusMd: 6
    readonly property int radiusSm: 4

    // ── Fonts ─────────────────────────────────────────────────────────────────
    property FontLoader _honeywell:      FontLoader { source: "qrc:/qt/qml/FmsTrainer/fonts/HoneywellMCDU.ttf" }
    property FontLoader _honeywellSmall: FontLoader { source: "qrc:/qt/qml/FmsTrainer/fonts/HoneywellMCDUSmall.ttf" }
    property FontLoader _ecam:           FontLoader { source: "qrc:/qt/qml/FmsTrainer/fonts/ECAMFontRegular.ttf" }
    property FontLoader _fcu:            FontLoader { source: "qrc:/qt/qml/FmsTrainer/fonts/AirbusFCU.ttf" }

    // Resolved family names (fall back to monospace until the loader is Ready)
    readonly property string fontFms:      _honeywell.status      === FontLoader.Ready ? _honeywell.name      : "monospace" // .fms-display / .mcdu-text
    readonly property string fontMcduSmall: _honeywellSmall.status === FontLoader.Ready ? _honeywellSmall.name : "monospace"
    readonly property string fontPfd:      _ecam.status           === FontLoader.Ready ? _ecam.name           : "monospace" // .pfd-text (ECAMFontRegular)
    readonly property string fontFcu:      _fcu.status            === FontLoader.Ready ? _fcu.name            : "monospace" // .font-fcu (AirbusFCU)
}
