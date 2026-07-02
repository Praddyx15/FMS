import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0
import QtQuick.Layouts 1.15

// DATA Page — Aircraft identification and database info
Item {
    id: root
    property var fmsComputer
    property var adc

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        Rectangle { Layout.fillWidth: true; height: 18; color: "transparent"
            Text { anchors.centerIn: parent; text: "A/C STATUS"; color: Theme.cyan; font.pixelSize: 11; font.bold: true; font.family: Theme.fontFms } }

        Repeater {
            model: [
                { label: "FMGC",     value: "CFM / IA5", col: Theme.white },
                { label: "ENGINE",   value: "CFM56-5B4P", col: Theme.white },
                { label: "IDLE/PERF", value: "NORM/CONF", col: Theme.cyan },
                { label: "NAVDB",    value: "AIRAC 2601", col: Theme.mutedFg },
                { label: "PERF DB",  value: "A320-001",   col: Theme.mutedFg },
                { label: "VERSION",  value: "H1CF7A",     col: "#546e7a" },
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
