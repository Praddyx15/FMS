import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

/*
 * EFISControl — EFIS control panel. 1:1 port of React displays/EFISControl.tsx.
 * Shared EFIS state lives on FlightDataManager (range/mode/overlays/qnh) so the
 * panel actually drives the ND. ndb/gain/tilt have no backend field yet → local.
 */
Rectangle {
    id: root
    property bool  ndbOverlay: false
    property int   wxrGain: 50
    property int   wxrTilt: 0

    color: Theme.cockpitPanel
    border.color: Theme.cockpitDark; border.width: 2
    radius: Theme.radiusLg

    // ── reusable buttons ──────────────────────────────────────────────────────
    component ModeButton : Rectangle {
        property string value: ""
        property string label: ""
        readonly property bool active: FlightDataManager.ndMode === value
        width: 64; height: 64; radius: 32
        color: active ? Theme.green : (mbMouse.containsMouse ? "#374151" : Theme.cockpitDark)
        border.width: 2; border.color: active ? "#d1d5db" : "#4b5563"
        Text { anchors.centerIn: parent; text: parent.label; color: parent.active ? "#000000" : "#9ca3af"; font.pixelSize: 13; font.bold: true }
        MouseArea { id: mbMouse; anchors.fill: parent; hoverEnabled: true; onClicked: FlightDataManager.ndMode = parent.value }
    }

    component ToggleButton : Rectangle {
        property string label: ""
        property bool isActive: false
        signal toggled()
        Layout.fillWidth: true
        implicitHeight: 34; radius: 6
        color: isActive ? Theme.cockpitPrimary : (tgMouse.containsMouse ? "#374151" : Theme.cockpitDark)
        Text { anchors.centerIn: parent; text: parent.label; color: parent.isActive ? "white" : "#9ca3af"; font.pixelSize: 12; font.bold: true }
        MouseArea { id: tgMouse; anchors.fill: parent; hoverEnabled: true; onClicked: parent.toggled() }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Header
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { Layout.alignment: Qt.AlignHCenter; text: "EFIS CONTROL PANEL"; color: "#d1d5db"; font.pixelSize: 14; font.bold: true }
            Text { Layout.alignment: Qt.AlignHCenter; text: "Electronic Flight Instrument System"; color: "#6b7280"; font.pixelSize: 12 }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#374151" }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 24

            // ── Left controls ─────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 16

                // Range
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 8
                    Text { Layout.alignment: Qt.AlignHCenter; text: "RANGE (NM)"; color: "#9ca3af"; font.pixelSize: 12 }
                    GridLayout {
                        Layout.alignment: Qt.AlignHCenter
                        columns: 3; rowSpacing: 8; columnSpacing: 8
                        Repeater {
                            model: [10, 20, 40, 80, 160, 320]
                            Rectangle {
                                required property int modelData
                                readonly property bool active: FlightDataManager.ndRange === modelData
                                width: 44; height: 26; radius: 4
                                color: active ? Theme.amber : (rngMouse.containsMouse ? "#374151" : Theme.cockpitDark)
                                Text { anchors.centerIn: parent; text: parent.modelData; color: parent.active ? "#000000" : "#9ca3af"; font.pixelSize: 12; font.bold: true; font.family: "monospace" }
                                MouseArea { id: rngMouse; anchors.fill: parent; hoverEnabled: true; onClicked: FlightDataManager.ndRange = parent.modelData }
                            }
                        }
                    }
                }

                // Display modes
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 12
                    Text { Layout.alignment: Qt.AlignHCenter; text: "DISPLAY MODE"; color: "#9ca3af"; font.pixelSize: 12 }
                    GridLayout {
                        Layout.alignment: Qt.AlignHCenter
                        columns: 3; rowSpacing: 8; columnSpacing: 8
                        ModeButton { value: "ROSE_LS";  label: "LS" }
                        ModeButton { value: "ROSE_VOR"; label: "VOR" }
                        ModeButton { value: "ROSE_NAV"; label: "NAV" }
                        ModeButton { value: "ARC";      label: "ARC" }
                        ModeButton { value: "PLAN";     label: "PLAN" }
                    }
                }

                // QNH
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 4
                    Text { Layout.alignment: Qt.AlignHCenter; text: "QNH (hPa)"; color: "#9ca3af"; font.pixelSize: 12 }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter; spacing: 8
                        Rectangle {
                            width: 32; height: 32; radius: 4; color: qm1.containsMouse ? "#374151" : Theme.cockpitDark
                            Text { anchors.centerIn: parent; text: "−"; color: "white"; font.pixelSize: 18 }
                            MouseArea { id: qm1; anchors.fill: parent; hoverEnabled: true; onClicked: if (FlightDataManager.qnh - 1 >= 950) FlightDataManager.qnh = FlightDataManager.qnh - 1 }
                        }
                        Rectangle {
                            width: 80; height: 40; color: "#000000"; border.color: "#4b5563"; border.width: 1
                            Text { anchors.centerIn: parent; text: Math.round(FlightDataManager.qnh); color: Theme.amber; font.pixelSize: 14; font.bold: true; font.family: "monospace" }
                        }
                        Rectangle {
                            width: 32; height: 32; radius: 4; color: qm2.containsMouse ? "#374151" : Theme.cockpitDark
                            Text { anchors.centerIn: parent; text: "+"; color: "white"; font.pixelSize: 16 }
                            MouseArea { id: qm2; anchors.fill: parent; hoverEnabled: true; onClicked: if (FlightDataManager.qnh + 1 <= 1050) FlightDataManager.qnh = FlightDataManager.qnh + 1 }
                        }
                    }
                }
            }

            // ── Right controls ────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 16

                // Overlays
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 8
                    Text { text: "OVERLAYS"; color: "#9ca3af"; font.pixelSize: 12 }
                    ToggleButton { label: "WEATHER"; isActive: FlightDataManager.wxrOverlay;  onToggled: FlightDataManager.wxrOverlay  = !FlightDataManager.wxrOverlay }
                    ToggleButton { label: "TERRAIN"; isActive: FlightDataManager.terrOverlay; onToggled: FlightDataManager.terrOverlay = !FlightDataManager.terrOverlay }
                    ToggleButton { label: "TRAFFIC"; isActive: FlightDataManager.tcasOverlay; onToggled: FlightDataManager.tcasOverlay = !FlightDataManager.tcasOverlay }
                }

                // WXR controls (only when weather overlay on)
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 12
                    visible: FlightDataManager.wxrOverlay
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#374151" }
                    Text { text: "WXR CONTROLS"; color: "#9ca3af"; font.pixelSize: 12 }

                    // Gain
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Text { Layout.alignment: Qt.AlignHCenter; text: "GAIN"; color: "#6b7280"; font.pixelSize: 10 }
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter; spacing: 8
                            Rectangle { width: 24; height: 24; radius: 4; color: Theme.cockpitDark
                                Text { anchors.centerIn: parent; text: "−"; color: "white"; font.pixelSize: 14 }
                                MouseArea { anchors.fill: parent; onClicked: root.wxrGain = Math.max(0, root.wxrGain - 5) } }
                            Rectangle { width: 64; height: 32; color: "#000000"; border.width: 1; border.color: Qt.rgba(Theme.green.r, Theme.green.g, Theme.green.b, 0.4)
                                Text { anchors.centerIn: parent; text: root.wxrGain; color: Theme.green; font.pixelSize: 12; font.bold: true; font.family: "monospace" } }
                            Rectangle { width: 24; height: 24; radius: 4; color: Theme.cockpitDark
                                Text { anchors.centerIn: parent; text: "+"; color: "white"; font.pixelSize: 12 }
                                MouseArea { anchors.fill: parent; onClicked: root.wxrGain = Math.min(100, root.wxrGain + 5) } }
                        }
                        Rectangle {
                            Layout.fillWidth: true; height: 6; radius: 3; color: "#1f2937"; clip: true
                            Rectangle { width: parent.width * root.wxrGain / 100; height: parent.height; color: Theme.green }
                        }
                    }

                    // Tilt
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Text { Layout.alignment: Qt.AlignHCenter; text: "TILT"; color: "#6b7280"; font.pixelSize: 10 }
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter; spacing: 8
                            Rectangle { width: 24; height: 24; radius: 4; color: Theme.cockpitDark
                                Text { anchors.centerIn: parent; text: "−"; color: "white"; font.pixelSize: 14 }
                                MouseArea { anchors.fill: parent; onClicked: root.wxrTilt = Math.max(-15, root.wxrTilt - 1) } }
                            Rectangle { width: 64; height: 32; color: "#000000"; border.width: 1; border.color: Qt.rgba(Theme.amber.r, Theme.amber.g, Theme.amber.b, 0.4)
                                Text { anchors.centerIn: parent; text: (root.wxrTilt > 0 ? "+" : "") + root.wxrTilt + "°"; color: Theme.amber; font.pixelSize: 12; font.bold: true; font.family: "monospace" } }
                            Rectangle { width: 24; height: 24; radius: 4; color: Theme.cockpitDark
                                Text { anchors.centerIn: parent; text: "+"; color: "white"; font.pixelSize: 12 }
                                MouseArea { anchors.fill: parent; onClicked: root.wxrTilt = Math.min(15, root.wxrTilt + 1) } }
                        }
                        Rectangle {
                            Layout.fillWidth: true; height: 6; radius: 3; color: "#1f2937"; clip: true
                            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 1; height: parent.height; color: "#4b5563" }
                            Rectangle {
                                height: parent.height; color: Theme.amber
                                x: root.wxrTilt >= 0 ? parent.width / 2 : parent.width * (0.5 + (root.wxrTilt / 15) * 0.5)
                                width: Math.abs(root.wxrTilt / 15) * parent.width * 0.5
                            }
                        }
                    }
                }

                // Nav aids
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 8
                    Text { text: "NAV AIDS"; color: "#9ca3af"; font.pixelSize: 12 }
                    ToggleButton { label: "VOR";       isActive: FlightDataManager.vorOverlay; onToggled: FlightDataManager.vorOverlay = !FlightDataManager.vorOverlay }
                    ToggleButton { label: "NDB";       isActive: root.ndbOverlay;              onToggled: root.ndbOverlay = !root.ndbOverlay }
                    ToggleButton { label: "WAYPOINTS"; isActive: FlightDataManager.wptOverlay; onToggled: FlightDataManager.wptOverlay = !FlightDataManager.wptOverlay }
                }
            }
        }

        // Status bar
        ColumnLayout {
            Layout.fillWidth: true; spacing: 8
            Rectangle { Layout.fillWidth: true; height: 1; color: "#374151" }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "WX: " + (FlightDataManager.wxrOverlay ? "ON" : "OFF"); color: FlightDataManager.wxrOverlay ? Theme.green : "#6b7280"; font.pixelSize: 12; font.family: "monospace" }
                Item { Layout.fillWidth: true }
                Text { text: "MODE: " + FlightDataManager.ndMode; color: Theme.cyan; font.pixelSize: 12; font.family: "monospace" }
                Item { Layout.fillWidth: true }
                Text { text: "TERR: " + (FlightDataManager.terrOverlay ? "ON" : "OFF"); color: FlightDataManager.terrOverlay ? Theme.amber : "#6b7280"; font.pixelSize: 12; font.family: "monospace" }
            }
        }
    }
}
