import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// AOC MENU — 1:1 port of React AocPage.tsx
McduPage {
    id: page
    title: "AOC MENU"

    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "MESSAGE CENTER"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 11 }

    Repeater {
        model: [
            { from: "OPS",      time: "1345Z", subject: "GATE CHANGE B12" },
            { from: "DISPATCH", time: "1320Z", subject: "FUEL UPLIFT CONF" },
            { from: "MAINT",    time: "1305Z", subject: "MEL UPDATE" },
        ]
        Rectangle {
            Layout.fillWidth: true
            color: "transparent"
            border.color: Qt.rgba(Theme.mcduGreen.r, Theme.mcduGreen.g, Theme.mcduGreen.b, 0.3)
            border.width: 1
            implicitHeight: msgCol.implicitHeight + 6
            ColumnLayout {
                id: msgCol
                anchors.fill: parent; anchors.margins: 3; spacing: 1
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "FROM: " + modelData.from; color: Theme.mcduCyan; font.family: Theme.fontFms; font.pixelSize: 10 }
                    Item { Layout.fillWidth: true }
                    Text { text: modelData.time; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10 }
                }
                Text { text: modelData.subject; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10 }
            }
        }
    }
    McduSep {}
    McduRow { left: "<NEW MSG";   right: "REPORTS>";  leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan }
    McduRow { left: "<SEND";      right: "REQUESTS>"; leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan }
    McduRow { left: "<FREE TEXT"; right: "WEATHER>";  leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan; clickable: true; onClicked: if (page.fmsComputer) page.fmsComputer.navigateTo("weather") }
    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "● CONNECTED"; color: Theme.mcduGreen; font.family: Theme.fontFms; font.pixelSize: 10 }
    Item { Layout.fillHeight: true }
}
