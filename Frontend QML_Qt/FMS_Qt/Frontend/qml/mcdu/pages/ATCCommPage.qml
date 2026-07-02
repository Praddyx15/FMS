import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// ATC COMM — 1:1 port of React ATCCommPage.tsx
McduPage {
    id: page
    title: "ATC COMM"

    McduRow { left: "ACTIVE"; right: "EDDF TWR" }
    McduRow { left: "FREQ";   right: "118.500"; rightColor: Theme.mcduCyan }
    McduSep {}
    Text { Layout.fillWidth: true; text: "MESSAGES:"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 11; font.bold: true }
    Repeater {
        model: [
            { time: "1342Z", from: "EDDF TWR", message: "DLH1234 CLEARED FOR TAKEOFF RWY 25C" },
            { time: "1340Z", from: "EDDF GND",  message: "DLH1234 TAXI HOLDING POINT C3" },
        ]
        ColumnLayout {
            Layout.fillWidth: true; spacing: 0
            Text { text: modelData.time + " " + modelData.from + ":"; color: Theme.mcduCyan; font.family: Theme.fontFms; font.pixelSize: 10 }
            Text { Layout.fillWidth: true; text: modelData.message; color: Theme.mcduGreen; font.family: Theme.fontFms; font.pixelSize: 10; wrapMode: Text.WordWrap }
        }
    }
    McduSep {}
    Text { Layout.fillWidth: true; text: "COMPOSE:"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 11; font.bold: true }
    Rectangle {
        Layout.fillWidth: true; Layout.preferredHeight: 28
        color: "#000000"; border.color: Qt.rgba(Theme.mcduGreen.r, Theme.mcduGreen.g, Theme.mcduGreen.b, 0.3); border.width: 1
        Text {
            anchors.fill: parent; anchors.margins: 3; verticalAlignment: Text.AlignVCenter
            text: (page.fmsComputer && page.fmsComputer.scratchpad) ? page.fmsComputer.scratchpad : "_"
            color: Theme.mcduCyan; font.family: Theme.fontFms; font.pixelSize: 11
        }
    }
    McduRow { left: "<SEND"; right: "CLR>"; leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan; size: 10 }
    Item { Layout.fillHeight: true }
}
