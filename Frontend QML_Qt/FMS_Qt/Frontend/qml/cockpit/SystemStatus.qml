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

                SystemCard {
                    icon: "⛭"
                    name: "HYDRAULIC"
                    status: !FlightDataManager ? "OFF" : 
                            (FlightDataManager.hydraulicGreenPressure < 1000 && FlightDataManager.hydraulicBluePressure < 1000 && FlightDataManager.hydraulicYellowPressure < 1000) ? "LO PRESS" : "NORMAL"
                    statusColor: !FlightDataManager ? Theme.red : 
                                 (FlightDataManager.hydraulicGreenPressure < 1000 && FlightDataManager.hydraulicBluePressure < 1000 && FlightDataManager.hydraulicYellowPressure < 1000) ? Theme.red : Theme.green
                    details: [
                        "BLUE: " + (FlightDataManager ? Math.round(FlightDataManager.hydraulicBluePressure) : 0) + " PSI",
                        "GREEN: " + (FlightDataManager ? Math.round(FlightDataManager.hydraulicGreenPressure) : 0) + " PSI",
                        "YELLOW: " + (FlightDataManager ? Math.round(FlightDataManager.hydraulicYellowPressure) : 0) + " PSI"
                    ]
                }

                SystemCard {
                    icon: "⚡"
                    name: "ELECTRICAL"
                    status: !FlightDataManager ? "OFF" : 
                            (FlightDataManager.acBus1 > 50 && FlightDataManager.acBus2 > 50) ? "AC NORM" : "ALIGN/BAT"
                    statusColor: !FlightDataManager ? Theme.red : 
                                 (FlightDataManager.acBus1 > 50 && FlightDataManager.acBus2 > 50) ? Theme.green : Theme.amber
                    details: [
                        "GEN 1: " + (FlightDataManager ? Math.round(FlightDataManager.acBus1) : 0) + "V / 400Hz",
                        "GEN 2: " + (FlightDataManager ? Math.round(FlightDataManager.acBus2) : 0) + "V / 400Hz",
                        "BAT 1: " + (FlightDataManager ? FlightDataManager.bat1Voltage.toFixed(1) : "0.0") + "V"
                    ]
                }

                SystemCard {
                    icon: "⛽"
                    name: "FUEL SYSTEM"
                    status: "BALANCED"
                    statusColor: Theme.green
                    details: [
                        "L TANK: " + (FlightDataManager ? Math.round(FlightDataManager.fuelLOuter + FlightDataManager.fuelLInner) : 0) + " KG",
                        "CTR TANK: " + (FlightDataManager ? Math.round(FlightDataManager.fuelCentre) : 0) + " KG",
                        "R TANK: " + (FlightDataManager ? Math.round(FlightDataManager.fuelROuter + FlightDataManager.fuelRInner) : 0) + " KG"
                    ]
                }

                SystemCard {
                    icon: "☁"
                    name: "PNEUMATIC"
                    status: (FlightDataManager && FlightDataManager.apuActive) ? "NORMAL" : "OFF/LOW"
                    statusColor: (FlightDataManager && FlightDataManager.apuActive) ? Theme.green : Theme.amber
                    details: [
                        "APU BLEED: " + (FlightDataManager ? (FlightDataManager.apuActive ? "ON" : "OFF") : "OFF"),
                        "ENG 1 BLEED: " + (root.adc && root.adc.n1Left > 20 ? "28 PSI" : "0 PSI"),
                        "ENG 2 BLEED: " + (root.adc && root.adc.n1Right > 20 ? "27 PSI" : "0 PSI")
                    ]
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
                            Label { text: "N1: " + (root.adc ? root.adc.n1Left.toFixed(1) : "0.0") + "%"; color: Theme.white; font.pixelSize: 18; font.bold: true; font.family: "Consolas" }
                            Label { text: "EGT: " + (root.adc ? Math.round(root.adc.egtLeft) : 0) + "°C"; color: Theme.green; font.pixelSize: 10 }
                        }
                        
                        // Engine 2
                        Column {
                            Label { text: "ENG 2"; color: Theme.mutedFg; font.pixelSize: 9 }
                            Label { text: "N1: " + (root.adc ? root.adc.n1Right.toFixed(1) : "0.0") + "%"; color: Theme.white; font.pixelSize: 18; font.bold: true; font.family: "Consolas" }
                            Label { text: "EGT: " + (root.adc ? Math.round(root.adc.egtRight) : 0) + "°C"; color: Theme.green; font.pixelSize: 10 }
                        }
                    }
                }
            }
        }
    }

    // ── SystemCard helper component ─────────────────────────────────────
    component SystemCard : Rectangle {
        property string icon: ""
        property string name: ""
        property string status: ""
        property color statusColor: Theme.green
        property var details: []

        Layout.fillWidth: true
        height: 100
        color: "#161920"
        radius: 6
        border.color: statusColor
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            RowLayout {
                Label { text: icon + " " + name; color: Theme.mutedFg; font.bold: true; font.pixelSize: 11 }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 50; height: 16; radius: 3; color: Qt.rgba(0,0,0,0.3)
                    Label { 
                        anchors.centerIn: parent; text: status; color: statusColor
                        font.pixelSize: 8; font.bold: true 
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#263238" }

            Column {
                spacing: 2
                Repeater {
                    model: details
                    Label { text: "• " + modelData; color: Theme.mutedFg; font.pixelSize: 9; font.family: "Consolas" }
                }
            }
        }
    }
}
