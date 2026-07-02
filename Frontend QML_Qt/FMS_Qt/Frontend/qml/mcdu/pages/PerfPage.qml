import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0
import QtQuick.Layouts 1.15

// PERF T/O Page — V1/VR/V2, FLAPS, DERATE
Item {
    id: root
    property var fmsComputer
    property var adc

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        Rectangle { Layout.fillWidth: true; height: 18; color: "transparent"
            Text { anchors.centerIn: parent; text: "TAKEOFF"; color: Theme.cyan; font.pixelSize: 11; font.bold: true; font.family: Theme.fontFms } }

        Repeater {
            model: [
                { label: "V1",        value: () => adc ? adc.v1.toFixed(0)   : "140", col: Theme.cyan },
                { label: "VR",        value: () => adc ? adc.vr.toFixed(0)   : "145", col: Theme.cyan },
                { label: "V2",        value: () => adc ? adc.v2.toFixed(0)   : "150", col: Theme.cyan },
                { label: "FLAPS/THS", value: () => "1+F / -0.2", col: Theme.white },
                { label: "FLEX TO",   value: () => "62°C", col: Theme.amber },
                { label: "ENG OUT ACC", value: () => "1500 FT", col: Theme.mutedFg },
            ]
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                Text { anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 8
                       text: modelData.label; color: "#546e7a"; font.pixelSize: 8; font.family: Theme.fontFms }
                Text { anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 8
                       text: modelData.value(); color: modelData.col; font.pixelSize: 13; font.bold: true; font.family: Theme.fontFms }
                Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: "#1a2a1a" }
            }
        }
    }
}
