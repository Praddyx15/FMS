import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// FailureInjection — grouped failure checklist with one-click inject/clear
Rectangle {
    id: root
    property var instructor
    color: "#0d1017"
    radius: 6
    border.color: "#2a2d35"

    ScrollView {
        anchors.fill: parent
        anchors.margins: 10
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 8

            Label { text: "⚠  FAILURE INJECTION"; color: "#ff5252"; font.pixelSize: 13; font.bold: true; font.family: "Consolas" }

            // Group helper
            function failureGroup(title, failures) {}

            // ── ENGINES ───────────────────────────────────────────────────
            FailureGroup {
                title: "ENGINES"
                accent: "#ff5252"
                Layout.fillWidth: true
                instructor: root.instructor
                failures: [
                    { id: "ENGINE_FIRE_1",  label: "Engine 1 Fire"   },
                    { id: "ENGINE_FIRE_2",  label: "Engine 2 Fire"   },
                ]
            }

            // ── PITOT / STATIC ────────────────────────────────────────────
            FailureGroup {
                title: "PITOT / STATIC"
                accent: "#ff9800"
                Layout.fillWidth: true
                instructor: root.instructor
                failures: [
                    { id: "PITOT_BLOCKAGE",         label: "Pitot Blockage"        },
                    { id: "STATIC_PORT_BLOCKAGE",   label: "Static Port Blockage"  },
                ]
            }

            // ── FMS ────────────────────────────────────────────────────────
            FailureGroup {
                title: "NAVIGATION / FMS"
                accent: "#ff9800"
                Layout.fillWidth: true
                instructor: root.instructor
                failures: [
                    { id: "DUAL_FMS_FAILURE",  label: "Dual FMS Failure"  },
                    { id: "TCAS_FAILURE",       label: "TCAS Failure"      },
                    { id: "GPWS_FAILURE",       label: "GPWS Failure"      },
                ]
            }

            // ── HYDRAULICS ────────────────────────────────────────────────
            FailureGroup {
                title: "HYDRAULICS"
                accent: "#ffeb3b"
                Layout.fillWidth: true
                instructor: root.instructor
                failures: [
                    { id: "HYDRAULIC_GREEN_FAILURE",  label: "Hyd Green Failure"  },
                    { id: "HYDRAULIC_YELLOW_FAILURE", label: "Hyd Yellow Failure" },
                    { id: "HYDRAULIC_BLUE_FAILURE",   label: "Hyd Blue Failure"   },
                ]
            }

            // ── ELECTRICS ─────────────────────────────────────────────────
            FailureGroup {
                title: "ELECTRICS"
                accent: "#00e5ff"
                Layout.fillWidth: true
                instructor: root.instructor
                failures: [
                    { id: "GEN1_FAILURE", label: "Gen 1 Failure" },
                    { id: "GEN2_FAILURE", label: "Gen 2 Failure" },
                    { id: "APU_FAILURE",  label: "APU Failure"   },
                ]
            }

            // ── WARNINGS ─────────────────────────────────────────────────
            FailureGroup {
                title: "WARNINGS"
                accent: "#ff9800"
                Layout.fillWidth: true
                instructor: root.instructor
                failures: [
                    { id: "WINDSHEAR_ALERT",  label: "Windshear Alert"  },
                    { id: "STALL_WARNING",    label: "Stall Warning"    },
                    { id: "OVERSPEED_WARNING",label: "Overspeed Warning" },
                ]
            }

            // Clear all button
            Button {
                Layout.fillWidth: true; Layout.preferredHeight: 36
                text: "✕  CLEAR ALL FAILURES"
                font.pixelSize: 10; font.family: "Consolas"; font.bold: true
                background: Rectangle { radius: 6; color: "#2a1010"; border.color: "#ff5252"; border.width: 1 }
                contentItem: Text { text: parent.text; color: "#ff5252"; font: parent.font; horizontalAlignment: Text.AlignHCenter }
                onClicked: { if (root.instructor) root.instructor.clearAllFailures() }
            }
        }
    }

    // ── FailureGroup component ─────────────────────────────────────────────
    component FailureGroup : ColumnLayout {
        property string title:    ""
        property color  accent:   "#ff5252"
        property var    instructor
        property var    failures: []

        spacing: 3

        Rectangle { Layout.fillWidth: true; height: 20; radius: 3; color: Qt.rgba(accent.r, accent.g, accent.b, 0.12); border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.4)
            Text { anchors.leftMargin: 8; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                   text: parent.parent.title; color: parent.parent.accent; font.pixelSize: 9; font.bold: true; font.family: "Consolas" }
        }

        Repeater {
            model: parent.failures
            RowLayout {
                Layout.fillWidth: true; height: 28; spacing: 6

                property bool active: parent.parent.instructor
                                      ? parent.parent.instructor.hasFailure(modelData.id)
                                      : false

                Rectangle {
                    width: 52; height: 24; radius: 4
                    color: parent.active ? Qt.rgba(1, 0.1, 0.1, 0.3) : "#1a1d24"
                    border.color: parent.active ? "#ff5252" : "#37474f"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text {
                        anchors.centerIn: parent; text: parent.parent.active ? "ACTIVE" : "INJECT"
                        color: parent.parent.active ? "#ff5252" : "#78909c"
                        font.pixelSize: 8; font.bold: true; font.family: "Consolas"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (!parent.parent.parent.instructor) return
                            if (parent.parent.active) parent.parent.parent.instructor.clearFailure(modelData.id)
                            else                      parent.parent.parent.instructor.injectFailure(modelData.id)
                        }
                    }
                }

                Text {
                    text: modelData.label
                    color: parent.active ? "#ff5252" : "#b0bec5"
                    font.pixelSize: 10; font.family: "Consolas"
                    Layout.fillWidth: true
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: parent.active ? "#ff5252" : "#2a2d35"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }
    }
}
