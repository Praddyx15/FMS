import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// PFD — Primary Flight Display outer container
Rectangle {
    id: root
    property var adc
    color: "#0a0c10"
    radius: 4
    border.color: "#2a2d35"
    border.width: 1
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 0

        // ── FMA bar ──────────────────────────────────────────────────────────
        FMA {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            adc: root.adc
        }

        // ── Main attitude + tapes ─────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Speed tape (left edge)
            SpeedTape {
                id: speedTape
                width: 52
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 2
                adc: root.adc
            }

            // Attitude Indicator (centre container preventing stretch)
            Item {
                id: adiContainer
                anchors.left: speedTape.right
                anchors.right: altTape.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 2

                AttitudeIndicator {
                    id: adi
                    width: Math.min(parent.width, parent.height)
                    height: width
                    anchors.centerIn: parent
                    adc: root.adc
                }
            }

            // Altitude tape (right of ADI)
            AltitudeTape {
                id: altTape
                width: 52
                anchors.right: vsi.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 2
                adc: root.adc
            }

            // VSI (far right)
            VSIndicator {
                id: vsi
                width: 36
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 2
                adc: root.adc
            }
        }

        // ── Heading tape ──────────────────────────────────────────────────────
        HeadingTape {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            adc: root.adc
        }

        // ── Bottom data bar ───────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            color: "#0d1017"
            radius: 3

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 10

                Label {
                    text: "GS  " + Math.round(root.adc ? root.adc.groundSpeed : 0)
                    color: Theme.mutedFg; font.pixelSize: 10; font.family: "Consolas"
                }
                Label {
                    text: "TAS " + Math.round(root.adc ? root.adc.tas : 0)
                    color: Theme.mutedFg; font.pixelSize: 10; font.family: "Consolas"
                }
                Label {
                    text: "M " + (root.adc ? root.adc.mach.toFixed(2) : "0.00")
                    color: Theme.cyan; font.pixelSize: 10; font.family: "Consolas"
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: "QNH " + (FlightDataManager ? FlightDataManager.qnh.toFixed(0) : "1013")
                    color: Theme.mutedFg; font.pixelSize: 10; font.family: "Consolas"
                }
            }
        }
    }
}
