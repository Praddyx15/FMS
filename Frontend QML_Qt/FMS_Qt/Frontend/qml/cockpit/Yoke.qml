import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0

// Yoke — sidestick control. 1:1 port of React controls/Yoke.tsx
Rectangle {
    id: root
    property var adc
    implicitHeight: 300
    color: Theme.cockpitPanel
    radius: 8
    border.color: Theme.cockpitBezel; border.width: 2

    readonly property int maxDefl: 60
    property real posX: 0
    property real posY: 0
    readonly property real pitch: -(posY / maxDefl) * 15
    readonly property real roll:  (posX / maxDefl) * 30

    // Drive the aircraft attitude (PFD) — only applied when autopilot is off
    onPitchChanged: if (adc) adc.setManualAttitude(pitch, roll)
    onRollChanged:  if (adc) adc.setManualAttitude(pitch, roll)

    // auto-centre when released (0.85 damping @ ~60fps), like React
    Timer {
        id: centering; interval: 16; repeat: true; running: false
        onTriggered: {
            root.posX *= 0.85; root.posY *= 0.85
            if (Math.abs(root.posX) < 0.5 && Math.abs(root.posY) < 0.5) { root.posX = 0; root.posY = 0; running = false }
        }
    }

    Column {
        anchors.fill: parent; anchors.margins: 16; spacing: 12
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "YOKE CONTROL"; color: Theme.cyan; font.family: "monospace"; font.pixelSize: 13; font.bold: true; font.letterSpacing: 1 }

        // Yoke circle
        Item {
            width: 168; height: 168
            anchors.horizontalCenter: parent.horizontalCenter
            Rectangle {
                id: circle
                anchors.fill: parent; radius: width / 2
                color: Theme.cockpitBezel; border.color: Theme.cockpitPanel; border.width: 4
                // crosshair
                Rectangle { anchors.centerIn: parent; width: 2; height: parent.height; color: "#374151" }
                Rectangle { anchors.centerIn: parent; width: parent.width; height: 2; color: "#374151" }
                // handle
                Rectangle {
                    id: handle
                    width: 44; height: 44; radius: 22
                    x: parent.width / 2 + root.posX * (parent.width / 2 - 22) / root.maxDefl - 22
                    y: parent.height / 2 + root.posY * (parent.height / 2 - 22) / root.maxDefl - 22
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#374151" }
                        GradientStop { position: 1.0; color: "#111827" }
                    }
                    border.color: drag.pressed ? Theme.cyan : "#4b5563"; border.width: 3
                    Rectangle { anchors.fill: parent; anchors.margins: 6; radius: width/2; color: "transparent"; border.color: "#6b7280"; opacity: 0.5 }
                }
                MouseArea {
                    id: drag
                    anchors.fill: parent
                    onPressed: centering.running = false
                    onReleased: centering.running = true
                    onPositionChanged: {
                        if (!pressed) return
                        var dx = mouseX - width / 2, dy = mouseY - height / 2
                        root.posX = Math.max(-root.maxDefl, Math.min(root.maxDefl, dx / (width/2 - 22) * root.maxDefl))
                        root.posY = Math.max(-root.maxDefl, Math.min(root.maxDefl, dy / (height/2 - 22) * root.maxDefl))
                    }
                }
            }
        }

        // readouts
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 12
            Repeater {
                model: [
                    { l: "PITCH", v: (root.pitch >= 0 ? "+" : "") + root.pitch.toFixed(1) + "°", warn: Math.abs(root.pitch) > 10 },
                    { l: "ROLL",  v: (root.roll  >= 0 ? "+" : "") + root.roll.toFixed(1)  + "°", warn: Math.abs(root.roll) > 20 },
                ]
                Rectangle {
                    width: 96; height: 38; radius: 3; color: Theme.cockpitBezel
                    Column {
                        anchors.centerIn: parent; spacing: 1
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.l; color: "#6b7280"; font.family: "monospace"; font.pixelSize: 9 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.v; color: modelData.warn ? Theme.amber : Theme.green; font.family: "monospace"; font.pixelSize: 13; font.bold: true }
                    }
                }
            }
        }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: drag.pressed ? "● ACTIVE" : "○ CENTERED"; color: drag.pressed ? Theme.cyan : "#6b7280"; font.family: "monospace"; font.pixelSize: 11 }
    }
}
