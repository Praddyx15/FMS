import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// Pedestal — throttle quadrant + speedbrake + brake
Rectangle {
    id: root
    property var adc
    color: "#12141a"
    radius: 6
    border.color: "#2a2d35"
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 16

        // ── Thrust levers ─────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillHeight: true; spacing: 6

            Text { text: "THRUST LEVERS"; color: "#78909c"; font.pixelSize: 9; font.family: "Consolas"; font.bold: true }

            RowLayout {
                spacing: 10

                Repeater {
                    model: ["ENG 1", "ENG 2"]
                    ColumnLayout {
                        spacing: 4
                        Text { text: modelData; color: "#546e7a"; font.pixelSize: 8; font.family: "Consolas"; Layout.alignment: Qt.AlignHCenter }

                        // Throttle label markers
                        Column {
                            spacing: 1
                            Repeater {
                                model: ["TOGA", "FLX", "MCT", "CL", "IDLE", "REV"]
                                Text {
                                    text: modelData; color: "#546e7a"; font.pixelSize: 7; font.family: "Consolas"
                                    leftPadding: 2
                                }
                            }
                        }

                        // Throttle slider
                        Slider {
                            id: throttleSlider
                            orientation: Qt.Vertical
                            from: 0; to: 100
                            value: (index === 0 && root.adc) ? root.adc.engine1Thrust :
                                   (index === 1 && root.adc) ? root.adc.engine2Thrust : 30

                            Layout.preferredHeight: 180
                            Layout.preferredWidth: 36

                            background: Rectangle {
                                x: throttleSlider.leftPadding + throttleSlider.availableWidth / 2 - width / 2
                                y: throttleSlider.topPadding
                                width: 8; height: throttleSlider.availableHeight
                                radius: 4; color: "#1a1d24"; border.color: "#37474f"

                                Rectangle {
                                    y: parent.height - throttleSlider.visualPosition * parent.height
                                    width: parent.width; height: throttleSlider.position * parent.height
                                    radius: 4
                                    color: {
                                        var v = throttleSlider.value
                                        if (v >= 90) return Theme.red
                                        if (v >= 70) return Theme.amber
                                        if (v >= 50) return Theme.green
                                        return Theme.cyan
                                    }
                                }
                            }
                            handle: Rectangle {
                                x: throttleSlider.leftPadding + throttleSlider.availableWidth / 2 - width / 2
                                y: throttleSlider.topPadding + throttleSlider.visualPosition * (throttleSlider.availableHeight - height)
                                width: 36; height: 16; radius: 4
                                color: "#2a2d35"; border.color: Theme.mutedFg; border.width: 1
                                Text {
                                    anchors.centerIn: parent; text: Math.round(throttleSlider.value) + "%"
                                    color: Theme.white; font.pixelSize: 8; font.family: "Consolas"
                                }
                            }
                            onValueChanged: {
                                if (root.adc) {
                                    if (index === 0) root.adc.engine1Thrust = value
                                    else             root.adc.engine2Thrust = value
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle { width: 1; Layout.fillHeight: true; color: "#2a2d35" }

        // ── Engine instrument strip ────────────────────────────────────────
        ColumnLayout {
            Layout.fillHeight: true; spacing: 6

            Text { text: "ENGINE STATUS"; color: "#78909c"; font.pixelSize: 9; font.family: "Consolas"; font.bold: true }

            GridLayout {
                columns: 3; rowSpacing: 4; columnSpacing: 10

                Repeater {
                    model: [
                        { label: "N1  ENG1", value: () => root.adc ? root.adc.n1Left.toFixed(1) + "%" : "---%",   col: Theme.green },
                        { label: "N1  ENG2", value: () => root.adc ? root.adc.n1Right.toFixed(1) + "%" : "---%",  col: Theme.green },
                        { label: "EGT ENG1", value: () => root.adc ? root.adc.egtLeft.toFixed(0) + "°C" : "---°C", col: Theme.amber },
                        { label: "EGT ENG2", value: () => root.adc ? root.adc.egtRight.toFixed(0) + "°C" : "---°C",col: Theme.amber },
                        { label: "FUEL/HR",  value: () => "2350 kg/h", col: Theme.cyan },
                        { label: "TOTAL FF", value: () => "4700 kg/h", col: Theme.cyan },
                    ]
                    ColumnLayout {
                        spacing: 1
                        Text { text: modelData.label; color: "#546e7a"; font.pixelSize: 8; font.family: "Consolas" }
                        Text { text: modelData.value(); color: modelData.col; font.pixelSize: 12; font.bold: true; font.family: "Consolas" }
                    }
                }
            }
        }

        Rectangle { width: 1; Layout.fillHeight: true; color: "#2a2d35" }

        // ── Speedbrake + Parking Brake ────────────────────────────────────
        ColumnLayout {
            Layout.fillHeight: true; spacing: 8; Layout.preferredWidth: 100

            Text { text: "CONTROLS"; color: "#78909c"; font.pixelSize: 9; font.family: "Consolas"; font.bold: true }

            // Speedbrake
            Text { text: "SPEED BRAKE"; color: "#546e7a"; font.pixelSize: 8; font.family: "Consolas" }
            Slider {
                from: 0; to: 40; value: 0
                Layout.preferredWidth: 80
                background: Rectangle { width: parent.availableWidth; height: 8; radius: 4; color: "#1a1d24"; border.color: "#37474f"
                    Rectangle { width: parent.parent.visualPosition * parent.width; height: 8; radius: 4; color: Theme.amber } }
                handle: Rectangle { width: 16; height: 16; radius: 3; color: "#37474f"; border.color: Theme.mutedFg
                                    x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                                    y: parent.topPadding + parent.availableHeight / 2 - height / 2 }
            }

            // Parking brake
            property bool parkBrake: false
            Text { text: "PARK BRAKE"; color: "#546e7a"; font.pixelSize: 8; font.family: "Consolas" }
            Rectangle {
                width: 60; height: 26; radius: 4
                color: parent.parkBrake ? Qt.rgba(1,0.1,0.1,0.3) : "#1a1d24"
                border.color: parent.parkBrake ? Theme.red : "#37474f"
                Text {
                    anchors.centerIn: parent
                    text: parent.parent.parkBrake ? "SET" : "OFF"
                    color: parent.parent.parkBrake ? Theme.red : "#78909c"
                    font.pixelSize: 10; font.bold: true; font.family: "Consolas"
                }
                MouseArea { anchors.fill: parent; onClicked: parent.parent.parkBrake = !parent.parent.parkBrake }
            }
        }
    }
}
