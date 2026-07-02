import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// F-PLN Page — scrollable waypoint list
Item {
    id: root
    property var fmsComputer
    property var adc

    property int scrollOff: fmsComputer ? fmsComputer.scrollOffset : 0
    property var waypoints: FlightDataManager ? FlightDataManager.waypoints : []

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Page title
        Rectangle {
            Layout.fillWidth: true; height: 18; color: "transparent"
            RowLayout {
                anchors.fill: parent; anchors.margins: 6
                Text { text: "F-PLN"; color: Theme.cyan; font.pixelSize: 11; font.bold: true; font.family: Theme.fontFms }
                Item { Layout.fillWidth: true }
                Text { text: (root.scrollOff + 1) + "/" + root.waypoints.length; color: "#546e7a"; font.pixelSize: 9; font.family: Theme.fontFms }
            }
        }

        // Header row
        Rectangle {
            Layout.fillWidth: true; height: 14; color: "#0a100a"
            RowLayout {
                anchors.fill: parent; anchors.margins: 6; spacing: 0
                Text { text: "FROM"; Layout.preferredWidth: 60; color: "#546e7a"; font.pixelSize: 8; font.family: Theme.fontFms }
                Text { text: "TIME"; Layout.preferredWidth: 40; color: "#546e7a"; font.pixelSize: 8; font.family: Theme.fontFms }
                Text { text: "SPD/ALT"; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; color: "#546e7a"; font.pixelSize: 8; font.family: Theme.fontFms }
            }
        }

        // Waypoint rows (4 visible)
        Repeater {
            model: 5
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                property int wpIdx: root.scrollOff + index
                property var wp: wpIdx < root.waypoints.length ? root.waypoints[wpIdx] : null

                RowLayout {
                    anchors.fill: parent; anchors.margins: 6; spacing: 4

                    Text {
                        text: parent.parent.wp ? parent.parent.wp.name : "----"
                        color: parent.parent.wp ? Theme.green : "#2a3a2a"
                        font.pixelSize: 12; font.bold: true; font.family: Theme.fontFms
                        Layout.preferredWidth: 60
                    }
                    Text {
                        text: "----"
                        color: "#546e7a"; font.pixelSize: 10; font.family: Theme.fontFms
                        Layout.preferredWidth: 40
                    }
                    Text {
                        text: parent.parent.wp && parent.parent.wp.altitude > 0
                              ? parent.parent.wp.speed + "/" + "FL" + Math.round(parent.parent.wp.altitude/100)
                              : "---/---"
                        color: Theme.amber
                        font.pixelSize: 10; font.family: Theme.fontFms
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left; anchors.right: parent.right
                    height: 1; color: "#1a2a1a"
                }
            }
        }

        // Scroll buttons
        RowLayout {
            Layout.fillWidth: true; Layout.preferredHeight: 22; spacing: 4
            Button {
                text: "▲ PREV"; Layout.fillWidth: true
                font.pixelSize: 8; font.family: Theme.fontFms
                background: Rectangle { color: "#1a2018"; radius: 3; border.color: "#2a3a28" }
                contentItem: Text { text: parent.text; color: Theme.green; font: parent.font; horizontalAlignment: Text.AlignHCenter }
                onClicked: { if (root.fmsComputer) root.fmsComputer.scrollUp() }
            }
            Button {
                text: "NEXT ▼"; Layout.fillWidth: true
                font.pixelSize: 8; font.family: Theme.fontFms
                background: Rectangle { color: "#1a2018"; radius: 3; border.color: "#2a3a28" }
                contentItem: Text { text: parent.text; color: Theme.green; font: parent.font; horizontalAlignment: Text.AlignHCenter }
                onClicked: { if (root.fmsComputer) root.fmsComputer.scrollDown() }
            }
        }
    }
}
