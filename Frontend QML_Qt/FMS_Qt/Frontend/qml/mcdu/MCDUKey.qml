import QtQuick

// Generic square/rectangular keypad button (function keys, alpha grid, numeric pad).
// From the user's prepared MCDU design; font set to Consolas for Windows.
Rectangle {
    id: root

    property string label: ""
    property string subLabel: ""
    property color labelColor: "#f2f2f2"
    property real labelSize: 13
    property bool wide: false
    property bool highlight: false        // cardinal keys (E/N/S/W) — lighter box
    signal clicked()

    implicitWidth: 42
    implicitHeight: 32
    radius: 4
    color: highlight ? (mouse.pressed ? "#737d88" : "#9aa6b2")
                     : (mouse.pressed ? "#16181a" : "#202326")
    border.color: "#0a0b0c"
    border.width: 1

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1.5
        radius: 3
        color: "transparent"
        border.color: root.highlight ? "#cfd6de" : "#43474c"
        border.width: 1
    }

    Column {
        anchors.centerIn: parent
        spacing: 1
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: root.highlight ? "#14171a" : root.labelColor
            font.pixelSize: root.labelSize
            font.bold: true
            font.family: "Consolas"
        }
        Text {
            visible: root.subLabel.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.subLabel
            color: root.labelColor
            font.pixelSize: root.labelSize - 2
            font.bold: true
            font.family: "Consolas"
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
