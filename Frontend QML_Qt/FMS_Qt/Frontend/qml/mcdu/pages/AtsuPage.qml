import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// ATSU MENU — 1:1 port of React AtsuPage.tsx
McduPage {
    id: page
    title: "ATSU MENU"

    McduRow { left: "DATALINK STATUS"; right: "LOGGED ON"; rightColor: Theme.mcduGreen }
    McduRow { left: "CONNECTION";      right: "VHF";       rightColor: Theme.mcduCyan }
    McduSep {}
    McduRow { left: "<LOGON";     right: "LOGOFF>";  leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan }
    McduRow { left: "<ATC MENU";  right: "AOC MENU>";leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan; clickable: true; onClicked: if (page.fmsComputer) page.fmsComputer.navigateTo("aoc") }
    McduRow { left: "<EMERGENCY"; right: "STATUS>";  leftColor: Theme.mcduAmber; rightColor: Theme.mcduCyan }
    McduSep {}
    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "MESSAGE LOG"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 11 }
    Repeater {
        model: [
            { time: "1345Z", type: "CPDLC", msg: "CLEARED TO FL370" },
            { time: "1332Z", type: "ADS-C", msg: "POSITION REPORT" },
            { time: "1320Z", type: "CPDLC", msg: "CONTACT 132.45" },
        ]
        ColumnLayout {
            Layout.fillWidth: true; spacing: 0
            RowLayout {
                Layout.fillWidth: true
                Text { text: modelData.time; color: Theme.mcduCyan; font.family: Theme.fontFms; font.pixelSize: 10 }
                Item { Layout.fillWidth: true }
                Text { text: modelData.type; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10 }
            }
            Text { text: modelData.msg; color: Theme.mcduGreen; font.family: Theme.fontFms; font.pixelSize: 10 }
        }
    }
    Item { Layout.fillHeight: true }
}
