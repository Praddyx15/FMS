import QtQuick

// BRT / DIM rotary knob.
Item {
    id: root
    property string label: ""
    width: 30
    height: 44

    Rectangle {
        id: knob
        width: 26
        height: 26
        radius: 13
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#6b7178" }
            GradientStop { position: 1.0; color: "#34373b" }
        }
        border.color: "#1c1e20"
        border.width: 1

        Rectangle {
            width: 2
            height: 8
            color: "#0d0e10"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 3
        }

        MouseArea {
            anchors.fill: parent
            onPressed: knob.rotation += 25
        }

        Behavior on rotation { NumberAnimation { duration: 120 } }
    }

    Text {
        anchors.top: knob.bottom
        anchors.topMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.label
        color: "#e8e8e8"
        font.pixelSize: 9
        font.bold: true
        font.family: "Consolas"
    }
}
