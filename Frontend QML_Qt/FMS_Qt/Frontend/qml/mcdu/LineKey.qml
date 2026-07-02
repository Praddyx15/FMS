import QtQuick

// Line-select key (LSK) on the left/right edges of the MCDU screen.
Rectangle {
    id: root
    width: 26
    height: 14
    radius: 2
    color: pressed ? "#1c1f22" : "#26292c"
    border.color: "#0d0e10"
    border.width: 1

    property bool pressed: false
    signal clicked()

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: 2
        color: "transparent"
        border.color: "#3a3e42"
        border.width: 1
    }

    MouseArea {
        anchors.fill: parent
        onPressed: root.pressed = true
        onReleased: root.pressed = false
        onClicked: root.clicked()
    }
}
