import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// INIT B (FUEL PRED) — 1:1 port of React InitBPage.tsx (two-column weights/fuel)
Item {
    id: root
    property var fmsComputer
    property var adc

    readonly property real zfw: FlightDataManager ? FlightDataManager.zeroFuelWeight : 0
    readonly property real trip: FlightDataManager ? FlightDataManager.tripFuel : 0
    readonly property real reserve: FlightDataManager ? FlightDataManager.reserveFuel : 0
    readonly property real altn: FlightDataManager ? FlightDataManager.alternateFuel : 0
    readonly property real final: FlightDataManager ? FlightDataManager.finalReserve : 0
    readonly property real blockKg: trip + reserve + altn + final
    readonly property bool zfwSet: zfw > 1000
    readonly property bool blockSet: blockKg > 1000
    function t(v) { return (v / 1000).toFixed(1) }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        // Title: INIT | FUEL PRED
        RowLayout {
            Layout.fillWidth: true
            Text { text: "INIT"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 13; font.bold: true }
            Item { Layout.fillWidth: true }
            Text { text: "FUEL PRED"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 11 }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(0.4,0.4,0.4,0.5) }

        // 6 two-column rows
        Repeater {
            model: [
                { ll:"TAXI",        lv:"0.2",                   lc: Theme.mcduCyan,  rl:"ZFW/ZFWCG",   rv: root.zfwSet ? (root.t(root.zfw)+" / 25.0") : "___._ / __._", rc: root.zfwSet ? Theme.mcduCyan : Theme.mcduAmber },
                { ll:"TRIP/TIME",   lv: root.t(root.trip)+" / ----", lc: Theme.mcduGreen, rl:"BLOCK", rv: root.blockSet ? root.t(root.blockKg) : "-----", rc: root.blockSet ? Theme.mcduCyan : Theme.mcduAmber },
                { ll:"RTE RSV/%",   lv: root.t(root.reserve)+" / 5.0", lc: Theme.mcduGreen, rl:"", rv:"", rc: Theme.mcduGreen },
                { ll:"ALTN/TIME",   lv: root.t(root.altn)+" / ----", lc: Theme.mcduGreen, rl:"TOW / LW", rv: root.t(root.zfw+root.blockKg)+" / "+root.t(root.zfw+root.final+root.altn), rc: Theme.mcduGreen },
                { ll:"FINAL/TIME",  lv: root.t(root.final)+" / 0030", lc: Theme.mcduGreen, rl:"TRIP WIND", rv:"HD000", rc: Theme.mcduCyan },
                { ll:"MIN DEST FOB",lv:"--.-",                  lc: Theme.mcduCyan,  rl:"EXTRA / TIME", rv:"0.0 / ----", rc: Theme.mcduGreen },
            ]
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                // left block
                ColumnLayout {
                    spacing: 1
                    Text { text: modelData.ll; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10 }
                    Text { text: modelData.lv; color: modelData.lc; font.family: Theme.fontFms; font.pixelSize: 13 }
                }
                Item { Layout.fillWidth: true }
                // right block
                ColumnLayout {
                    spacing: 1
                    visible: modelData.rl !== ""
                    Text { text: modelData.rl; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10; Layout.alignment: Qt.AlignRight }
                    Text { text: modelData.rv; color: modelData.rc; font.family: Theme.fontFms; font.pixelSize: 13; Layout.alignment: Qt.AlignRight }
                }
            }
        }
        // Footer nav
        RowLayout {
            Layout.fillWidth: true
            Text { text: "< INIT A"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 11
                MouseArea { anchors.fill: parent; onClicked: if (root.fmsComputer) root.fmsComputer.navigateTo("init") } }
            Item { Layout.fillWidth: true }
        }
    }
}
