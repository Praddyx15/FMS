import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// FMGC — 1:1 port of React FmgcPage.tsx
McduPage {
    id: page
    title: "FMGC"

    component FmgcBox : Rectangle {
        property string name: ""
        Layout.fillWidth: true
        color: "transparent"
        border.color: Qt.rgba(Theme.mcduGreen.r, Theme.mcduGreen.g, Theme.mcduGreen.b, 0.3)
        border.width: 1
        implicitHeight: bc.implicitHeight + 10
        ColumnLayout {
            id: bc
            anchors.fill: parent; anchors.margins: 5; spacing: 2
            Text { Layout.alignment: Qt.AlignHCenter; text: parent.parent.name; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 11 }
            McduRow { left: "STATUS"; right: "NORMAL"; rightColor: Theme.mcduGreen; size: 10 }
            McduRow { left: "MODE";   right: "NAV";    rightColor: Theme.mcduCyan;  size: 10 }
            McduRow { left: "PERF";   right: "OK";     rightColor: Theme.mcduGreen; size: 10 }
        }
    }

    RowLayout {
        Layout.fillWidth: true; spacing: 8
        FmgcBox { name: "FMGC 1" }
        FmgcBox { name: "FMGC 2" }
    }
    McduSep {}
    McduRow { left: "CROSS FILL";    right: "ACTIVE"; rightColor: Theme.mcduGreen }
    McduRow { left: "<INDEPENDENT";  right: "OFF";    leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan }
    McduSep {}
    McduRow { left: "DATABASE"; right: "AIRAC 2513"; size: 10 }
    McduRow { left: "EXPIRY";   right: "28 DEC 2025"; rightColor: Theme.mcduCyan; size: 10 }
    Item { Layout.fillHeight: true }
}
