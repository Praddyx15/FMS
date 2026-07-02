import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

/* BasicInstrumentsPanel — six-pack modal overlay. 1:1 port of React instruments/BasicInstrumentsPanel.tsx */
Item {
    id: root
    property var adc
    signal closed()

    // backdrop (bg-black/80)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.8)
        MouseArea { anchors.fill: parent }   // swallow clicks behind the panel
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 1024)   // max-w-5xl
        height: Math.min(parent.height - 32, implicitPanelHeight)
        property real implicitPanelHeight: 720
        color: Theme.cockpitPanel
        border.color: Theme.cockpitBorder; border.width: 2
        radius: Theme.radiusLg

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ── Header ────────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                color: "#000000"
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.cockpitBorder }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 12
                    Rectangle {
                        width: 8; height: 8; radius: 4; color: Theme.green
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.3; duration: 1000 }
                            NumberAnimation { from: 0.3; to: 1.0; duration: 1000 }
                        }
                    }
                    Text { text: "BASIC FLIGHT INSTRUMENTS"; color: "white"; font.pixelSize: 18; font.letterSpacing: 1; font.family: Theme.fontFcu }
                    Text { text: "SIX-PACK VIEW"; color: "#9ca3af"; font.pixelSize: 12; font.family: "monospace" }
                    Item { Layout.fillWidth: true }
                    Button {
                        flat: true
                        contentItem: Text { text: "✕"; color: closeMouse.containsMouse ? "white" : "#9ca3af"; font.pixelSize: 16 }
                        background: Rectangle { color: closeMouse.containsMouse ? Theme.cockpitDark : "transparent"; radius: 4 }
                        onClicked: root.closed()
                        MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                    }
                }
            }

            // ── Instruments grid (3 x 2) ──────────────────────────────────────
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 24
                columns: 3
                rowSpacing: 24; columnSpacing: 24

                component Cell : Item { Layout.fillWidth: true; Layout.fillHeight: true }

                Cell { AirspeedIndicator        { anchors.fill: parent; airspeed: root.adc ? root.adc.ias : 0 } }
                Cell { AttitudeIndicatorAnalog  { anchors.fill: parent; pitch: root.adc ? root.adc.pitch : 0; roll: root.adc ? root.adc.roll : 0 } }
                Cell { Altimeter                { anchors.fill: parent; altitude: root.adc ? root.adc.altitude : 0; qnh: FlightDataManager.qnh } }
                Cell { TurnCoordinator          { anchors.fill: parent; roll: root.adc ? root.adc.roll : 0; yaw: 0 } }
                Cell { HeadingIndicator         { anchors.fill: parent; heading: root.adc ? root.adc.heading : 0 } }
                Cell { VerticalSpeedIndicator   { anchors.fill: parent; vsi: root.adc ? root.adc.vsi : 0 } }
            }

            // ── Footer ────────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                color: "#000000"
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.cockpitBorder }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                    Text { text: "Press Ctrl+B to toggle"; color: "#9ca3af"; font.pixelSize: 12; font.family: "monospace" }
                    Item { Layout.fillWidth: true }
                    Text {
                        color: Theme.cyan; font.pixelSize: 12; font.family: "monospace"
                        text: "IAS: " + Math.round(root.adc ? root.adc.ias : 0) + " KT | ALT: "
                              + Math.round(root.adc ? root.adc.altitude : 0) + " FT | HDG: "
                              + Math.round(root.adc ? root.adc.heading : 0) + "°"
                    }
                }
            }
        }
    }
}
