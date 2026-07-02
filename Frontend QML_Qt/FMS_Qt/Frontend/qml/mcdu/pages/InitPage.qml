import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0
import QtQuick.Layouts 1.15

// INIT A Page — FROM/TO, ALTN, FLT NBR, CRZ FL/CI
Item {
    id: root
    property var fmsComputer
    property var adc

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Page title
        Rectangle {
            Layout.fillWidth: true; height: 18; color: "transparent"
            Text {
                anchors.centerIn: parent
                text: "INIT  A"; color: Theme.cyan
                font.pixelSize: 11; font.bold: true; font.family: Theme.fontFms
            }
        }

        // 6 row pairs
        Repeater {
            model: [
                { label: "FROM/TO",    right: false, value: () => FlightDataManager ? FlightDataManager.departure+"/"+FlightDataManager.destination : "----/----", col: Theme.white },
                { label: "ALTN",       right: false, value: () => FlightDataManager ? FlightDataManager.alternate : "----", col: Theme.cyan },
                { label: "FLT NBR",    right: false, value: () => FlightDataManager ? FlightDataManager.flightNumber : "--------", col: Theme.white },
                { label: "COST INDEX", right: true,  value: () => FlightDataManager ? FlightDataManager.costIndex.toString() : "--", col: Theme.cyan },
                { label: "CRZ FL",     right: true,  value: () => FlightDataManager ? "FL" + Math.round(FlightDataManager.cruiseAltitude/100).toString().padStart(3,"0") : "FL---", col: Theme.cyan },
                { label: "TROPO",      right: true,  value: () => "36090", col: Theme.mutedFg },
            ]

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Label (small, top)
                Text {
                    anchors.left: modelData.right ? undefined : parent.left
                    anchors.right: modelData.right ? parent.right : undefined
                    anchors.top: parent.top
                    anchors.margins: 8
                    text: modelData.label
                    color: "#546e7a"; font.pixelSize: 8; font.family: Theme.fontFms
                }
                // Value (large, centre-ish)
                Text {
                    anchors.left: modelData.right ? undefined : parent.left
                    anchors.right: modelData.right ? parent.right : undefined
                    anchors.bottom: parent.bottom
                    anchors.margins: 8
                    text: modelData.value()
                    color: modelData.col
                    font.pixelSize: 12; font.bold: true; font.family: Theme.fontFms
                }
                // Separator
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left; anchors.right: parent.right
                    height: 1; color: "#1a2a1a"
                }
            }
        }
    }
}
