import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

/*
 * McduPage — standard A320 MCDU page frame: centred title with a green/30
 * underline, then a content column. Children declared inside go into the body.
 * Default text on the real MCDU is green on black in the Honeywell MCDU font.
 */
Item {
    id: page
    property var fmsComputer
    property var adc
    property string title: ""
    property color  titleColor: Theme.mcduGreen
    default property alias content: body.data

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 5

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: page.title
            color: page.titleColor
            font.family: Theme.fontFms
            font.pixelSize: 13
            font.bold: true
        }
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(Theme.mcduGreen.r, Theme.mcduGreen.g, Theme.mcduGreen.b, 0.3)
        }
        ColumnLayout {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
        }
    }
}
