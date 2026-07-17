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
                        id: leverDelegate
                        spacing: 4
                        // Backing value for the lever position (TLA, deg, 0..45 = IDLE..TOGA).
                        // NOT bound live to adc.tla1/2: that property changes 12.5x/sec from
                        // the sim tick, which would fight the user's mouse drag every frame.
                        property real tla: 0

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

                        // Throttle slider — domain is TLA degrees (0=IDLE..45=TOGA),
                        // matching ThrottleQuadrantModel's forward range.
                        Slider {
                            id: throttleSlider
                            orientation: Qt.Vertical
                            from: 0; to: 45
                            value: leverDelegate.tla

                            Layout.preferredHeight: 180
                            Layout.preferredWidth: 36

                            Component.onCompleted: {
                                if (root.adc) {
                                    leverDelegate.tla = (index === 0) ? root.adc.tla1 : root.adc.tla2
                                }
                            }

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
                                        var pct = throttleSlider.value / 45.0 * 100.0
                                        if (pct >= 90) return Theme.red
                                        if (pct >= 70) return Theme.amber
                                        if (pct >= 50) return Theme.green
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
                                    anchors.centerIn: parent; text: Math.round(throttleSlider.value / 45.0 * 100.0) + "%"
                                    color: Theme.white; font.pixelSize: 8; font.family: "Consolas"
                                }
                            }
                            onValueChanged: {
                                leverDelegate.tla = value
                                if (root.adc) {
                                    if (index === 0) root.adc.tla1 = value
                                    else             root.adc.tla2 = value
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
            id: controlsCol
            Layout.fillHeight: true; spacing: 8; Layout.preferredWidth: 100
            // Local backing value, same reasoning as the throttle sliders above:
            // avoid live-binding a Slider to a property that changes via NOTIFY
            // dataChanged on every sim tick (redundant onValueChanged churn).
            property real speedbrakeDeg: 0

            Text { text: "CONTROLS"; color: "#78909c"; font.pixelSize: 9; font.family: "Consolas"; font.bold: true }

            // Speedbrake
            Text { text: "SPEED BRAKE"; color: "#546e7a"; font.pixelSize: 8; font.family: "Consolas" }
            Slider {
                id: speedbrakeSlider
                from: 0; to: 40; value: controlsCol.speedbrakeDeg
                Layout.preferredWidth: 80
                Component.onCompleted: {
                    if (root.adc) controlsCol.speedbrakeDeg = root.adc.speedbrakeLever * 40.0
                }
                onValueChanged: {
                    controlsCol.speedbrakeDeg = value
                    if (root.adc) root.adc.speedbrakeLever = value / 40.0
                }
                background: Rectangle { width: parent.availableWidth; height: 8; radius: 4; color: "#1a1d24"; border.color: "#37474f"
                    Rectangle { width: parent.parent.visualPosition * parent.width; height: 8; radius: 4; color: Theme.amber } }
                handle: Rectangle { width: 16; height: 16; radius: 3; color: "#37474f"; border.color: Theme.mutedFg
                                    x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                                    y: parent.topPadding + parent.availableHeight / 2 - height / 2 }
            }

            // Parking brake
            Text { text: "PARK BRAKE"; color: "#546e7a"; font.pixelSize: 8; font.family: "Consolas" }
            Rectangle {
                width: 60; height: 26; radius: 4
                property bool set: root.adc ? root.adc.parkingBrake : false
                color: set ? Qt.rgba(1,0.1,0.1,0.3) : "#1a1d24"
                border.color: set ? Theme.red : "#37474f"
                Text {
                    anchors.centerIn: parent
                    text: parent.set ? "SET" : "OFF"
                    color: parent.set ? Theme.red : "#78909c"
                    font.pixelSize: 10; font.bold: true; font.family: "Consolas"
                }
                MouseArea { anchors.fill: parent; onClicked: if (root.adc) root.adc.parkingBrake = !root.adc.parkingBrake }
            }
        }
    }
}
