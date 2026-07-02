import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0
import QtQuick.Layouts 1.15

// RAD NAV Page — VOR1/VOR2/ILS frequency and course
Item {
    id: root
    property var fmsComputer
    property var adc

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        Rectangle { Layout.fillWidth: true; height: 18; color: "transparent"
            Text { anchors.centerIn: parent; text: "RADIO NAV"; color: Theme.cyan; font.pixelSize: 11; font.bold: true; font.family: Theme.fontFms } }

        Repeater {
            model: [
                { label: "VOR1",    value: "115.90 / FFM",  col: Theme.cyan },
                { label: "CRS",     value: "287°",          col: Theme.white },
                { label: "VOR2",    value: "117.30 / COL",  col: Theme.cyan },
                { label: "CRS",     value: "---",           col: "#546e7a" },
                { label: "ILS/FRQ", value: "108.90 / I-FPG", col: Theme.amber },
                { label: "CRS",     value: "260°",          col: Theme.white },
            ]
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                Text { anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 8
                       text: modelData.label; color: "#546e7a"; font.pixelSize: 8; font.family: Theme.fontFms }
                Text { anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 8
                       text: modelData.value; color: modelData.col; font.pixelSize: 12; font.bold: true; font.family: Theme.fontFms }
                Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: "#1a2a1a" }
            }
        }
    }
}
