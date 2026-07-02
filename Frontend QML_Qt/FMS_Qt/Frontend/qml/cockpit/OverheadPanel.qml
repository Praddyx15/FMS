import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// OverheadPanel — hydraulic, electrical, fuel, air systems
Rectangle {
    id: root
    color: "#12141a"
    radius: 6
    border.color: "#2a2d35"
    border.width: 1

    GridLayout {
        anchors.fill: parent
        anchors.margins: 10
        columns: 3
        rowSpacing: 10
        columnSpacing: 10

        // ── Hydraulics ────────────────────────────────────────────────────
        OHPanel {
            title: "HYDRAULIC"
            Layout.columnSpan: 1
            model: [
                { label: "GREEN",  prop: "hydraulicGreen",  col: Theme.green },
                { label: "YELLOW", prop: "hydraulicYellow", col: "#ffeb3b" },
                { label: "BLUE",   prop: "hydraulicBlue",   col: Theme.cyan },
            ]
        }

        // ── Electrical ────────────────────────────────────────────────────
        OHPanel {
            title: "ELECTRICAL"
            Layout.columnSpan: 1
            model: [
                { label: "GEN 1", prop: "gen1Active", col: Theme.green },
                { label: "GEN 2", prop: "gen2Active", col: Theme.green },
                { label: "APU",   prop: "apuActive",  col: Theme.amber },
            ]
        }

        // ── GNSS / Navigation ─────────────────────────────────────────────
        OHPanel {
            title: "NAVIGATION"
            Layout.columnSpan: 1
            model: [
                { label: "GPS 1",  prop: "gnssActive", col: Theme.cyan },
                { label: "ADIRS 1", prop: "gnssActive", col: Theme.cyan },
                { label: "ADIRS 2", prop: "gnssActive", col: Theme.cyan },
            ]
        }

        // ── Fuel ─────────────────────────────────────────────────────────
        Rectangle {
            Layout.columnSpan: 3
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            color: "#1a1d24"; radius: 4; border.color: "#2a2d35"

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 4

                Text { text: "FUEL SYSTEM"; color: "#78909c"; font.pixelSize: 9; font.family: "Consolas"; font.bold: true }

                RowLayout {
                    spacing: 12
                    Repeater {
                        model: ["L OUTER","L INNER","CTR","R INNER","R OUTER"]
                        ColumnLayout {
                            spacing: 2
                            Text { text: modelData; color: "#546e7a"; font.pixelSize: 8; font.family: "Consolas" }
                            Text {
                                text: {
                                    var vals = [800, 5400, 6200, 5400, 800]
                                    return vals[index].toString() + " kg"
                                }
                                color: Theme.cyan; font.pixelSize: 9; font.bold: true; font.family: "Consolas"
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    ColumnLayout {
                        spacing: 2
                        Text { text: "TOTAL"; color: "#546e7a"; font.pixelSize: 8; font.family: "Consolas" }
                        Text { text: "18600 kg"; color: Theme.amber; font.pixelSize: 11; font.bold: true; font.family: "Consolas" }
                    }
                }
            }
        }
    }

    // ── OHPanel sub-component ─────────────────────────────────────────────
    component OHPanel : Rectangle {
        property string title: ""
        property var    model: []
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        color: "#1a1d24"; radius: 4; border.color: "#2a2d35"

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 8; spacing: 4

            Text { text: parent.parent.title; color: "#78909c"; font.pixelSize: 9; font.family: "Consolas"; font.bold: true }

            Repeater {
                model: parent.parent.model
                RowLayout {
                    spacing: 6
                    property bool sysActive: FlightDataManager ? FlightDataManager[modelData.prop] : true

                    Rectangle {
                        width: 32; height: 20; radius: 3
                        color: parent.sysActive ? Qt.rgba(0, 0.9, 0.4, 0.2) : Qt.rgba(1,0,0,0.2)
                        border.color: parent.sysActive ? modelData.col : Theme.red
                        Text {
                            anchors.centerIn: parent; text: parent.parent.sysActive ? "ON" : "OFF"
                            color: parent.parent.sysActive ? modelData.col : Theme.red
                            font.pixelSize: 8; font.bold: true; font.family: "Consolas"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { if (FlightDataManager) FlightDataManager[modelData.prop] = !FlightDataManager[modelData.prop] }
                        }
                    }
                    Text { text: modelData.label; color: Theme.mutedFg; font.pixelSize: 9; font.family: "Consolas" }
                }
            }
        }
    }
}
