import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// TrainingScenarios — quick-load flight states for practice
Rectangle {
    id: root
    property var adc
    property var instructor
    color: "#0d1017"
    radius: 6
    border.color: "#2a2d35"

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 16; spacing: 12

        Label { text: "📚  TRAINING SCENARIOS"; color: "#00e676"; font.pixelSize: 14; font.bold: true; font.family: "Consolas" }
        Label { text: "Select a scenario to instantly load that flight state for practice"
                color: "#546e7a"; font.pixelSize: 10; font.family: "Consolas"; wrapMode: Text.Wrap; Layout.fillWidth: true }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2d35" }

        ListView {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 8; clip: true

            model: [
                { title: "Normal Takeoff",         phase: "TAKEOFF",   difficulty: "Beginner",   desc: "Configure the aircraft for takeoff from EDDF runway 25C. Practice rotation and initial climb.", icon: "🛫", col: "#00e676" },
                { title: "Stabilised ILS Approach", phase: "APPROACH",  difficulty: "Intermediate",desc: "Intercept ILS at LFPG runway 27L. Manage approach profile from FAF to flare.", icon: "🛬", col: "#00e5ff" },
                { title: "Engine Fire at V1",      phase: "TAKEOFF",   difficulty: "Advanced",   desc: "Engine 1 fire at V1 during takeoff roll. Apply memory items and continue climb.", icon: "🔥", col: "#ff5252" },
                { title: "FMS Dual Failure",       phase: "CRUISE",    difficulty: "Advanced",   desc: "Both FMGCs fail en-route. Navigate using raw data VOR/DME and pilot monitoring.", icon: "⚠️", col: "#ff9800" },
                { title: "Windshear Encounter",    phase: "APPROACH",  difficulty: "Advanced",   desc: "Windshear detected on approach. Execute go-around and follow EGPWS guidance.", icon: "🌪", col: "#ffeb3b" },
                { title: "Cold-and-Dark Setup",    phase: "PREFLIGHT", difficulty: "Beginner",   desc: "Power up the aircraft from cold and dark. Complete before-start checks.", icon: "⚡", col: "#b0bec5" },
            ]

            delegate: Rectangle {
                width: parent.width; height: 90; radius: 6
                color: scenArea.containsMouse ? "#1a2030" : "#12141a"
                border.color: scenArea.containsMouse ? modelData.col : "#2a2d35"
                Behavior on color { ColorAnimation { duration: 100 } }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 12; spacing: 12

                    // Icon circle
                    Rectangle {
                        width: 52; height: 52; radius: 26
                        color: Qt.rgba(0.1, 0.1, 0.15, 1)
                        border.color: modelData.col; border.width: 2
                        Text { anchors.centerIn: parent; text: modelData.icon; font.pixelSize: 22 }
                    }

                    // Text block
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 3
                        Label { text: modelData.title; color: "#e0e0e0"; font.pixelSize: 12; font.bold: true; font.family: "Consolas" }
                        Label { text: modelData.desc;  color: "#78909c"; font.pixelSize: 9; font.family: "Consolas"; wrapMode: Text.Wrap; Layout.fillWidth: true }
                        Row {
                            spacing: 10
                            Label {
                                text: modelData.difficulty
                                color: modelData.difficulty === "Beginner" ? "#00e676" :
                                       modelData.difficulty === "Intermediate" ? "#ffab40" : "#ff5252"
                                font.pixelSize: 9; font.family: "Consolas"; font.bold: true
                            }
                            Label { text: "Phase: " + modelData.phase; color: "#546e7a"; font.pixelSize: 9; font.family: "Consolas" }
                        }
                    }

                    // Load button
                    Rectangle {
                        width: 70; height: 32; radius: 6
                        color: scenArea.containsMouse ? Qt.rgba(0, 0.7, 0.4, 0.2) : "#1a1d24"
                        border.color: scenArea.containsMouse ? "#00e676" : "#37474f"
                        Text { anchors.centerIn: parent; text: "LOAD ▶"; color: "#00e676"; font.pixelSize: 9; font.bold: true; font.family: "Consolas" }
                    }
                }

                MouseArea {
                    id: scenArea; anchors.fill: parent; hoverEnabled: true
                    onClicked: {
                        if (root.instructor) root.instructor.startScenario(modelData.phase.toLowerCase())
                        if (root.adc) root.adc.setFlightPhase(modelData.phase.toLowerCase())
                    }
                }
            }
        }
    }
}
