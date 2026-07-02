import QtQuick 2.15
import FmsBackend 1.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// InstructorStation — scenario loading, weather override, phase jump
Rectangle {
    id: root
    property var instructor
    property var adc
    color: "#0d1017"
    radius: 6
    border.color: "#2a2d35"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Header
        RowLayout {
            Label { text: "⚡  INSTRUCTOR STATION"; color: "#e040fb"; font.pixelSize: 13; font.bold: true; font.family: "Consolas" }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 16; height: 16; radius: 8
                color: root.instructor && root.instructor.instructorActive ? "#00e676" : "#ff5252"
                Behavior on color { ColorAnimation { duration: 300 } }
            }
            Label {
                text: root.instructor && root.instructor.instructorActive ? "ACTIVE" : "STANDBY"
                color: root.instructor && root.instructor.instructorActive ? "#00e676" : "#ff5252"
                font.pixelSize: 10; font.family: "Consolas"
            }
            Switch {
                checked: root.instructor ? root.instructor.instructorActive : false
                onCheckedChanged: { if (root.instructor) root.instructor.instructorActive = checked }
                palette.highlight: "#e040fb"
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2d35" }

        // ── Quick Scenarios ────────────────────────────────────────────────
        Label { text: "QUICK-LOAD SCENARIOS"; color: "#78909c"; font.pixelSize: 9; font.family: "Consolas"; font.bold: true }

        GridLayout {
            columns: 2; rowSpacing: 6; columnSpacing: 8; Layout.fillWidth: true

            Repeater {
                model: [
                    { label: "🛫  TAKEOFF",       id: "takeoff",       col: "#00e676" },
                    { label: "🛬  APPROACH",       id: "approach",      col: "#00e5ff" },
                    { label: "🔥  ENGINE FIRE 1", id: "engine_fire_1", col: "#ff5252" },
                    { label: "🧭  DUAL FMS FAIL", id: "dual_fms",      col: "#ff9800" },
                    { label: "💧  PITOT BLOCK",   id: "pitot_blockage",col: "#ff9800" },
                    { label: "🔄  RESET ALL",     id: "_reset",        col: "#b0bec5" },
                ]
                Rectangle {
                    Layout.fillWidth: true; height: 34; radius: 6
                    color: Qt.rgba(0.12, 0.12, 0.15, 1)
                    border.color: scenBtn.pressed ? modelData.col : "#2a2d35"
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent; text: modelData.label
                        color: scenBtn.pressed ? modelData.col : "#b0bec5"
                        font.pixelSize: 10; font.family: "Consolas"
                    }
                    MouseArea {
                        id: scenBtn
                        anchors.fill: parent
                        onClicked: {
                            if (!root.instructor) return
                            if (modelData.id === "_reset") root.instructor.clearAllFailures()
                            else root.instructor.startScenario(modelData.id)
                        }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2d35" }

        // ── Weather ────────────────────────────────────────────────────────
        Label { text: "WEATHER OVERRIDE"; color: "#78909c"; font.pixelSize: 9; font.family: "Consolas"; font.bold: true }

        GridLayout {
            columns: 2; rowSpacing: 4; columnSpacing: 8; Layout.fillWidth: true

            Label { text: "Wind Dir"; color: "#546e7a"; font.pixelSize: 9; font.family: "Consolas" }
            Slider {
                from: 0; to: 360; value: FlightDataManager ? FlightDataManager.windHeading : 270
                Layout.fillWidth: true
                onValueChanged: { if (FlightDataManager) FlightDataManager.windHeading = value }
            }
            Label { text: "Wind Spd"; color: "#546e7a"; font.pixelSize: 9; font.family: "Consolas" }
            Slider {
                from: 0; to: 80; value: FlightDataManager ? FlightDataManager.windSpeed : 10
                Layout.fillWidth: true
                onValueChanged: { if (FlightDataManager) FlightDataManager.windSpeed = value }
            }
            Label { text: "Turbulence"; color: "#546e7a"; font.pixelSize: 9; font.family: "Consolas" }
            Slider {
                from: 0; to: 10; value: FlightDataManager ? FlightDataManager.turbulence : 2
                Layout.fillWidth: true
                onValueChanged: { if (FlightDataManager) FlightDataManager.turbulence = value }
            }
        }

        // ── Flight Phase Jump ──────────────────────────────────────────────
        Label { text: "FLIGHT PHASE"; color: "#78909c"; font.pixelSize: 9; font.family: "Consolas"; font.bold: true }
        RowLayout {
            spacing: 4
            Repeater {
                model: ["PREFLIGHT", "TAKEOFF", "CLIMB", "CRUISE", "DESCENT", "APPROACH"]
                Rectangle {
                    Layout.fillWidth: true; height: 24; radius: 4
                    color: "#1a1d24"; border.color: "#2a2d35"
                    Text { anchors.centerIn: parent; text: modelData; color: "#78909c"; font.pixelSize: 8; font.family: "Consolas" }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { if (root.adc) root.adc.setFlightPhase(modelData.toLowerCase()) }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
