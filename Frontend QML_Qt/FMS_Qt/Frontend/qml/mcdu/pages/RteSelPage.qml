import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// ROUTE SELECTION — 1:1 port of React RteSelPage.tsx
McduPage {
    id: page
    title: "ROUTE SELECTION"

    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "COMPANY ROUTES"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 11 }
    Repeater {
        model: [
            { id: "EDDFLFPG01", from: "EDDF", to: "LFPG", distance: 244, time: "00:52" },
            { id: "EDDFLFPG02", from: "EDDF", to: "LFPG", distance: 268, time: "00:58" },
            { id: "EDDFEGLL01", from: "EDDF", to: "EGLL", distance: 406, time: "01:18" },
        ]
        ColumnLayout {
            Layout.fillWidth: true; spacing: 0
            McduRow { left: "<" + modelData.id; right: ""; leftColor: Theme.mcduCyan }
            RowLayout {
                Layout.fillWidth: true; Layout.leftMargin: 8
                Text { text: modelData.from + " → " + modelData.to; color: Theme.mcduGreen; font.family: Theme.fontFms; font.pixelSize: 10 }
                Item { Layout.fillWidth: true }
                Text { text: modelData.distance + " NM"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10 }
            }
        }
    }
    Item { Layout.fillHeight: true }
    McduRow { left: "<INSERT"; right: "RETURN>"; leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan }
}
