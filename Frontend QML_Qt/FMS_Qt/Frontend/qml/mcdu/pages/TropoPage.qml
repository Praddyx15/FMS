import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// TROPOPAUSE — 1:1 port of React TropoPage.tsx
McduPage {
    id: page
    title: "TROPOPAUSE"

    McduRow { left: "<ALTITUDE"; right: "36090 FT"; leftColor: Theme.mcduCyan }
    McduRow { left: "<TEMP";     right: "-56°C";    leftColor: Theme.mcduCyan }
    McduSep {}
    McduRow { left: "MODE"; right: "AUTO"; rightColor: Theme.mcduGreen }
    Rectangle {
        Layout.fillWidth: true; Layout.topMargin: 4
        color: Qt.rgba(1,1,1,0.04)
        implicitHeight: calcCol.implicitHeight + 10
        ColumnLayout {
            id: calcCol
            anchors.fill: parent; anchors.margins: 5; spacing: 2
            Text { Layout.alignment: Qt.AlignHCenter; text: "AUTO-CALCULATE"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 11 }
            McduRow { left: "LATITUDE";   right: "N40°";     rightColor: Theme.mcduCyan; size: 10 }
            McduRow { left: "CALC TROPO"; right: "46000 FT"; rightColor: Theme.mcduCyan; size: 10 }
            McduRow { left: "CALC TEMP";  right: "-58°C";    rightColor: Theme.mcduCyan; size: 10 }
            Text { Layout.alignment: Qt.AlignHCenter; text: "<APPLY AUTO"; color: Theme.mcduCyan; font.family: Theme.fontFms; font.pixelSize: 10 }
        }
    }
    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "Tropopause affects cruise performance and RVSM"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 9; wrapMode: Text.WordWrap }
    Item { Layout.fillHeight: true }
}
