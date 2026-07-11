import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// SplitCockpitView — left: PFD+ND, right: MCDU / Checklist / Flight-plan / Systems
Item {
    id: root
    property var adc
    property var fmsComputer

    property string rightContent: "mcdu"  // mcdu | checklist | flight-plan | system-status

    RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        // LEFT: PFD + ND stack
        ColumnLayout {
            Layout.preferredWidth: root.width * 0.55
            Layout.fillHeight: true
            spacing: 6

            PFD {
                Layout.fillWidth: true
                Layout.preferredHeight: root.height * 0.55
                adc: root.adc
            }
            ND {
                Layout.fillWidth: true
                Layout.fillHeight: true
                adc: root.adc
            }
            FCU {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                adc: root.adc
            }
        }

        // DIVIDER
        Rectangle { width: 1; Layout.fillHeight: true; color: "#2a2d35" }

        // RIGHT: dynamic content
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            // Content selector tabs
            RowLayout {
                spacing: 3
                Repeater {
                    model: [
                        { label: "MCDU",       id: "mcdu"        },
                        { label: "COACH",      id: "coach"       },
                        { label: "CHECKLIST",  id: "checklist"   },
                        { label: "FLT PLAN",   id: "flight-plan" },
                        { label: "SYSTEMS",    id: "system-status"},
                    ]
                    Rectangle {
                        Layout.fillWidth: true; height: 22; radius: 3
                        color: root.rightContent === modelData.id
                               ? Qt.rgba(0,0.82,1,0.15) : Qt.rgba(1,1,1,0.04)
                        border.color: root.rightContent === modelData.id ? Theme.cyan : "#2a2d35"
                        Text {
                            anchors.centerIn: parent; text: modelData.label
                            color: root.rightContent === modelData.id ? Theme.cyan : "#546e7a"
                            font.pixelSize: 8; font.bold: root.rightContent === modelData.id; font.family: "Consolas"
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.rightContent = modelData.id }
                    }
                }
            }

            // Content area
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true

                Item {
                    anchors.fill: parent
                    visible: root.rightContent === "mcdu"
                    Item {
                        id: mcduWrapper
                        property real scaleFactor: Math.min(parent.width / 380, parent.height / 660)
                        width: 380 * scaleFactor
                        height: 660 * scaleFactor
                        anchors.centerIn: parent
                        MCDU {
                            id: mcduInstance
                            anchors.centerIn: parent
                            scale: mcduWrapper.scaleFactor
                            fmsComputer: root.fmsComputer
                            adc: root.adc
                        }
                    }
                }

                AICoach {
                    anchors.fill: parent
                    visible: root.rightContent === "coach"
                    adc: root.adc
                }

                Rectangle {
                    anchors.fill: parent
                    visible: root.rightContent === "checklist"
                    color: "#0d1017"; radius: 4; border.color: "#2a2d35"
                    Label {
                        anchors.centerIn: parent; text: "NORMAL PROCEDURES\nNormal Checklist — In Development"
                        color: "#546e7a"; font.pixelSize: 11; font.family: "Consolas"; horizontalAlignment: Text.AlignHCenter
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    visible: root.rightContent === "flight-plan"
                    color: "#0d1017"; radius: 4; border.color: "#2a2d35"
                    // Inline flight plan list
                    ListView {
                        anchors.fill: parent; anchors.margins: 12
                        model: FlightDataManager ? FlightDataManager.waypoints : []
                        delegate: RowLayout {
                            width: parent.width; height: 26; spacing: 8
                            Text { text: index + 1 + "."; color: "#546e7a"; font.pixelSize: 9; font.family: "Consolas"; Layout.preferredWidth: 20 }
                            Text { text: modelData.name; color: Theme.green; font.pixelSize: 11; font.bold: true; font.family: "Consolas"; Layout.preferredWidth: 60 }
                            Text { text: modelData.altitude > 0 ? "FL" + Math.round(modelData.altitude/100) : "----"; color: Theme.amber; font.pixelSize: 10; font.family: "Consolas" }
                            Text { text: modelData.speed > 0 ? modelData.speed + "kt" : "----"; color: Theme.cyan; font.pixelSize: 10; font.family: "Consolas" }
                        }
                    }
                }

                // ── System Status ───────────────────────────────────────────
                SystemStatus {
                    anchors.fill: parent
                    visible: root.rightContent === "system-status"
                    adc: root.adc
                }
            }
        }
    }
}
