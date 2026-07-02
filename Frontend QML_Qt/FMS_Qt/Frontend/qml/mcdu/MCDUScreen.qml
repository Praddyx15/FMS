import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// MCDUScreen — CRT-style display area with active page loader + scratchpad
Rectangle {
    id: root
    property var fmsComputer
    property var adc
    color: "#060a08"
    radius: 4
    border.color: "#1a2418"
    border.width: 1
    clip: true

    // ── Page Loader ───────────────────────────────────────────────────────
    Loader {
        id: pageLoader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: scratchpad.top
        anchors.margins: 4

        source: {
            if (!root.fmsComputer) return ""
            var page = root.fmsComputer.currentPage
            var map = {
                "init":        "pages/InitPage.qml",
                "init_b":      "pages/InitBPage.qml",
                "fpln":        "pages/FplnPage.qml",
                "perf":        "pages/PerfPage.qml",
                "perf_crz":    "pages/PerfCrzPage.qml",
                "perf_appr":   "pages/PerfApprPage.qml",
                "prog":        "pages/ProgPage.qml",
                "radnav":      "pages/RadNavPage.qml",
                "data":        "pages/DataPage.qml",
                "data_index":  "pages/DataIndexPage.qml",
                "fuel_pred":   "pages/FuelPredPage.qml",
                "sys_status":  "pages/SysStatusPage.qml",
                "weather":     "pages/WeatherPage.qml",
                "weather_req": "pages/WeatherReqPage.qml",
                "atc_comm":    "pages/ATCCommPage.qml",
                "menu":        "pages/MCDUMenuPage.qml",
                "dir_to":      "pages/DirectToPage.qml",
                "departure":   "pages/DeparturePage.qml",
                "arrival":     "pages/ArrivalPage.qml",
                "pos_init":    "pages/PosInitPage.qml",
                "irs_init":    "pages/IrsInitPage.qml",
                "rte_sel":     "pages/RteSelPage.qml",
                "alternate":   "pages/AlternatePage.qml",
                "sec_fpln":    "pages/SecFplnPage.qml",
                "fmgc":        "pages/FmgcPage.qml",
                "aoc":         "pages/AocPage.qml",
                "atsu":        "pages/AtsuPage.qml",
                "flt_init":    "pages/FltInitPage.qml",
                "wind":        "pages/WindPage.qml",
                "gnd_temp":    "pages/GndTempPage.qml",
                "tropo":       "pages/TropoPage.qml",
            }
            return map[page] || "pages/InitPage.qml"
        }
        onLoaded: {
            if (item) {
                item.fmsComputer = Qt.binding(function() { return root.fmsComputer })
                item.adc = Qt.binding(function() { return root.adc })
            }
        }
        Connections {
            target: root.fmsComputer
            function onPageChanged() { pageLoader.source = pageLoader.source }
        }
    }

    // ── Scratchpad ────────────────────────────────────────────────────────
    Rectangle {
        id: scratchpad
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 4
        height: 22
        color: "#0a100a"
        border.color: root.fmsComputer && root.fmsComputer.scratchpadError
                      ? Theme.red : "#1e3020"
        border.width: 1
        radius: 2
        Behavior on border.color { ColorAnimation { duration: 200 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 4

            // Box arrow
            Text {
                text: "□"
                color: Theme.green
                font.pixelSize: 13
                font.family: Theme.fontFms
            }

            Text {
                Layout.fillWidth: true
                text: root.fmsComputer
                      ? (root.fmsComputer.scratchpadError ? "NOT ALLOWED" : root.fmsComputer.scratchpad)
                      : ""
                color: root.fmsComputer && root.fmsComputer.scratchpadError
                       ? Theme.red : Theme.white
                font.pixelSize: 12
                font.family: Theme.fontFms
                font.bold: true
                elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }
}
