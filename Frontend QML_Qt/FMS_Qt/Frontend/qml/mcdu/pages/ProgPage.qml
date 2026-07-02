import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0
import QtQuick.Layouts 1.15

// PROG Page — Progress: dist/time/fuel to destination, GNSS
Item {
    id: root
    property var fmsComputer
    property var adc

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        Rectangle { Layout.fillWidth: true; height: 18; color: "transparent"
            Text { anchors.centerIn: parent; text: "PROGRESS"; color: Theme.cyan; font.pixelSize: 11; font.bold: true; font.family: Theme.fontFms } }

        Repeater {
            model: [
                { label: "TO DEST",       value: () => FlightDataManager ? FlightDataManager.destination : "----",  col: Theme.cyan },
                { label: "DIST",          value: () => "483 NM",    col: Theme.white },
                { label: "ETA",           value: () => "14:22Z",    col: Theme.white },
                { label: "FUEL PRED",     value: () => "6.8 T",     col: Theme.amber },
                { label: "GNSS",          value: () => FlightDataManager && FlightDataManager.gnssActive ? "ACTIVE" : "DEGRADED", col: () => FlightDataManager && FlightDataManager.gnssActive ? Theme.green : Theme.red },
                { label: "BRG / DIST",    value: () => "284° / 483", col: Theme.mutedFg },
            ]
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                Text { anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 8
                       text: modelData.label; color: "#546e7a"; font.pixelSize: 8; font.family: Theme.fontFms }
                Text { anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 8
                       text: modelData.value()
                       color: typeof modelData.col === "function" ? modelData.col() : modelData.col
                       font.pixelSize: 13; font.bold: true; font.family: Theme.fontFms }
                Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: "#1a2a1a" }
            }
        }
    }
}
