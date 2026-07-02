import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// SystemStatus — Detailed overview of aircraft systems (Hyd, Elec, Fuel, Eng)
Rectangle {
    id: root
    property var adc
    color: "#0a0c10"
    radius: 4
    border.color: "#2a2d35"
    clip: true

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: parent.width
            spacing: 12
            anchors.margins: 12

            Label {
                text: "AIRCRAFT SYSTEMS STATUS"
                color: Theme.cyan
                font.pixelSize: 14; font.bold: true; font.family: "Consolas"
            }

            // ── Grid of system cards ──────────────────────────────────────
            GridLayout {
                Layout.fillWidth: true
                columns: width > 400 ? 2 : 1
                rowSpacing: 10; columnSpacing: 10

                Repeater {
                    model: [
                        { name: "HYDRAULIC", status: "NORMAL", color: Theme.green, icon: "⛭", 
                          details: ["BLUE: 3000 PSI", "GREEN: 2980 PSI", "YELLOW: 3005 PSI"] },
                        { name: "ELECTRICAL", status: "AC NORM", color: Theme.green, icon: "⚡",
                          details: ["GEN 1: 115V / 400Hz", "GEN 2: 115V / 401Hz", "BAT 1: 28.2V"] },
                        { name: "FUEL SYSTEM", status: "BALANCED", color: Theme.green, icon: "⛽",
                          details: ["L TANK: 4500 KG", "CTR TANK: 2100 KG", "R TANK: 4520 KG"] },
                        { name: "PNEUMATIC", status: "LOW PRESS", color: Theme.amber, icon: "☁",
                          details: ["APU BLEED: OFF", "ENG 1 BLEED: 28 PSI", "ENG 2 BLEED: 27 PSI"] },
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        height: 100
                        color: "#161920"
                        radius: 6
                        border.color: modelData.color
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            RowLayout {
                                Label { text: modelData.icon + " " + modelData.name; color: Theme.mutedFg; font.bold: true; font.pixelSize: 11 }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    width: 50; height: 16; radius: 3; color: Qt.rgba(0,0,0,0.3)
                                    Label { 
                                        anchors.centerIn: parent; text: modelData.status; color: modelData.color
                                        font.pixelSize: 8; font.bold: true 
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: "#263238" }

                            Column {
                                spacing: 2
                                Repeater {
                                    model: modelData.details
                                    Label { text: "• " + modelData; color: Theme.mutedFg; font.pixelSize: 9; font.family: "Consolas" }
                                }
                            }
                        }
                    }
                }
            }

            // ── Engine Status (Live Data) ───────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                color: "#1a1d24"
                radius: 6
                border.color: "#37474f"

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 8
                    Label { text: "ENGINE PERFORMANCE (LIVE)"; color: Theme.green; font.pixelSize: 10; font.bold: true }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20
                        
                        // Engine 1
                        Column {
                            Label { text: "ENG 1"; color: Theme.mutedFg; font.pixelSize: 9 }
                            Label { text: "N1: " + (root.adc ? (root.adc.v1 * 0.45).toFixed(1) : "0.0") + "%"; color: Theme.white; font.pixelSize: 18; font.bold: true; font.family: "Consolas" }
                            Label { text: "EGT: 420°C"; color: Theme.green; font.pixelSize: 10 }
                        }
                        
                        // Engine 2
                        Column {
                            Label { text: "ENG 2"; color: Theme.mutedFg; font.pixelSize: 9 }
                            Label { text: "N1: " + (root.adc ? (root.adc.v2 * 0.46).toFixed(1) : "0.0") + "%"; color: Theme.white; font.pixelSize: 18; font.bold: true; font.family: "Consolas" }
                            Label { text: "EGT: 418°C"; color: Theme.green; font.pixelSize: 10 }
                        }
                    }
                }
            }
        }
    }
}
