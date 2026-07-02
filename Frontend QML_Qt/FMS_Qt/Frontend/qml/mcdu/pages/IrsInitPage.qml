import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// IRS INITIALIZATION — 1:1 port of React IrsInitPage.tsx
McduPage {
    id: page
    title: "IRS INITIALIZATION"

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 6
        Repeater {
            model: 3
            Rectangle {
                Layout.fillWidth: true
                color: "transparent"
                border.color: Qt.rgba(Theme.mcduGreen.r, Theme.mcduGreen.g, Theme.mcduGreen.b, 0.3)
                border.width: 1
                implicitHeight: irsCol.implicitHeight + 10
                ColumnLayout {
                    id: irsCol
                    anchors.fill: parent; anchors.margins: 5; spacing: 3
                    Text { Layout.alignment: Qt.AlignHCenter; text: "IRS " + (index + 1); color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 11; font.bold: true }
                    Text { Layout.alignment: Qt.AlignHCenter; text: "ALIGNED"; color: Theme.mcduGreen; font.family: Theme.fontFms; font.pixelSize: 10 }
                    Text { Layout.fillWidth: true; text: "QUALITY"; color: Theme.mcduGreen; font.family: Theme.fontFms; font.pixelSize: 9 }
                    Rectangle {
                        Layout.fillWidth: true; height: 6; color: Qt.rgba(1,1,1,0.1)
                        Rectangle { width: parent.width; height: parent.height; color: Theme.mcduGreen }
                    }
                    Text { Layout.alignment: Qt.AlignHCenter; text: "100%"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 9 }
                }
            }
        }
    }
    McduSep {}
    Text {
        Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
        text: "ALIGN ON BATTERY: NO"; font.family: Theme.fontFms; font.pixelSize: 10
        color: Theme.mcduWhite
    }
    Item { Layout.fillHeight: true }
}
