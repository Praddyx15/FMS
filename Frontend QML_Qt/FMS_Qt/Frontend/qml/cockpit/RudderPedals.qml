import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0

// RudderPedals — 1:1 port of React controls/RudderPedals.tsx
Rectangle {
    id: root
    property var adc
    implicitHeight: 250
    color: Theme.cockpitPanel
    radius: 8
    border.color: Theme.cockpitBezel; border.width: 2

    property real leftPedal: 50   // 0..100, 50 centred
    property real rightPedal: 50
    readonly property real yaw: ((leftPedal - rightPedal) / 100) * 30
    function setLeft(v)  { leftPedal = v;  rightPedal = 100 - v }
    function setRight(v) { rightPedal = v; leftPedal  = 100 - v }

    component PedalSlider : Column {
        property string label: ""
        property real value: 50
        signal moved(real v)
        width: parent ? parent.width : 200; spacing: 4
        Row {
            width: parent.width
            Text { text: parent.parent.label; color: "#6b7280"; font.family: "monospace"; font.pixelSize: 10 }
            Item { width: parent.width - 120; height: 1 }
            Text { text: ((parent.parent.value - 50) * 2).toFixed(0) + "%"; color: Theme.cyan; font.family: "monospace"; font.pixelSize: 10 }
        }
        Rectangle {
            width: parent.width; height: 44; radius: 6; color: Theme.cockpitBezel; border.color: Theme.cockpitPanel; border.width: 2; clip: true
            Rectangle { anchors.verticalCenter: parent.verticalCenter; x: 6; width: parent.width - 12; height: 2; color: "#374151" }
            Rectangle { anchors.centerIn: parent; width: 2; height: parent.height; color: "#4b5563" }
            Rectangle {
                id: pedal
                width: 40; height: 36; radius: 4
                x: (parent.width - 40) * parent.parent.value / 100
                anchors.verticalCenter: parent.verticalCenter
                gradient: Gradient { GradientStop { position: 0; color: "#4b5563" } GradientStop { position: 1; color: "#1f2937" } }
                border.color: pma.pressed ? Theme.cyan : "#6b7280"; border.width: 2
            }
            MouseArea {
                id: pma; anchors.fill: parent
                onPositionChanged: if (pressed) parent.parent.moved(Math.max(0, Math.min(100, (mouseX - 20) / (width - 40) * 100)))
                onPressed: parent.parent.moved(Math.max(0, Math.min(100, (mouseX - 20) / (width - 40) * 100)))
            }
        }
    }

    Column {
        anchors.fill: parent; anchors.margins: 14; spacing: 12
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "RUDDER PEDALS"; color: Theme.cyan; font.family: "monospace"; font.pixelSize: 13; font.bold: true; font.letterSpacing: 1 }
        PedalSlider { label: "LEFT PEDAL";  value: root.leftPedal;  onMoved: root.setLeft(v) }
        PedalSlider { label: "RIGHT PEDAL"; value: root.rightPedal; onMoved: root.setRight(v) }
        Row {
            width: parent.width; spacing: 10
            Rectangle {
                width: (parent.width - 10) / 2; height: 40; radius: 3; color: Theme.cockpitBezel
                Column { anchors.centerIn: parent; spacing: 1
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "YAW"; color: "#6b7280"; font.family: "monospace"; font.pixelSize: 9 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: (root.yaw >= 0 ? "+" : "") + root.yaw.toFixed(1) + "°"; color: Math.abs(root.yaw) > 20 ? Theme.amber : Theme.green; font.family: "monospace"; font.pixelSize: 13; font.bold: true } }
            }
            Rectangle {
                width: (parent.width - 10) / 2; height: 40; radius: 3; color: rstMa.containsMouse ? Theme.cockpitPanel : Theme.cockpitBezel
                Text { anchors.centerIn: parent; text: "RESET CENTER"; color: Theme.cyan; font.family: "monospace"; font.pixelSize: 10 }
                MouseArea { id: rstMa; anchors.fill: parent; hoverEnabled: true; onClicked: { root.leftPedal = 50; root.rightPedal = 50 } }
            }
        }
        Text { anchors.horizontalCenter: parent.horizontalCenter
            text: Math.abs(root.yaw) > 1 ? ("● DEFLECTED " + (root.yaw > 0 ? "RIGHT" : "LEFT")) : "○ CENTERED"
            color: Math.abs(root.yaw) > 1 ? Theme.cyan : "#6b7280"; font.family: "monospace"; font.pixelSize: 11 }
    }
}
