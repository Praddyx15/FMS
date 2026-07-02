import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

/*
 * McduRow — a single MCDU line: left text + right text (flex justify-between).
 * Defaults match the common case: green label on the left, white value right.
 * Optionally clickable (for index/menu pages that navigate on tap).
 */
Item {
    id: row
    property string left: ""
    property string right: ""
    property color  leftColor: Theme.mcduGreen
    property color  rightColor: Theme.mcduWhite
    property int    size: 12
    property bool   bold: false
    property bool   clickable: false
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: Math.max(lt.implicitHeight, rt.implicitHeight)

    Text {
        id: lt
        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
        text: row.left; color: row.leftColor
        font.family: Theme.fontFms; font.pixelSize: row.size; font.bold: row.bold
    }
    Text {
        id: rt
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        text: row.right; color: row.rightColor
        font.family: Theme.fontFms; font.pixelSize: row.size; font.bold: row.bold
        horizontalAlignment: Text.AlignRight
    }
    MouseArea {
        anchors.fill: parent
        enabled: row.clickable
        onClicked: row.clicked()
    }
}
