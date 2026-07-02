import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// PERF CRZ — 1:1 port of React PerfCrzPage.tsx
McduPage {
    id: page
    title: "PERF CRZ"

    McduRow { left: "<CRZ FL"; right: "350"; leftColor: Theme.mcduCyan; bold: true }
    McduSep {}
    McduRow { left: "OPT FL"; right: "FL370"; rightColor: Theme.mcduCyan }
    McduRow { left: "MAX FL"; right: "FL410"; rightColor: Theme.mcduMagenta }
    McduRow { left: "REC FL"; right: "FL370"; rightColor: Theme.mcduGreen }

    Rectangle {
        Layout.fillWidth: true; Layout.topMargin: 6
        color: Qt.rgba(1,1,1,0.04)
        implicitHeight: stepCol.implicitHeight + 10
        ColumnLayout {
            id: stepCol
            anchors.fill: parent; anchors.margins: 5; spacing: 2
            Text { Layout.alignment: Qt.AlignHCenter; text: "STEP CLIMB"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 11 }
            McduRow { left: "TO FL"; right: "390"; rightColor: Theme.mcduGreen }
            McduRow { left: "DIST";  right: "245 NM" }
            Text { text: "FUEL BENEFIT: +180 KG"; color: Theme.mcduAmber; font.family: Theme.fontFms; font.pixelSize: 10 }
        }
    }
    McduRow { left: "MACH";      right: ".78";  rightColor: Theme.mcduCyan }
    McduRow { left: "LRC SPEED"; right: "M.78"; rightColor: Theme.mcduCyan }
    Item { Layout.fillHeight: true }
    McduRow { left: ""; right: "DES>"; rightColor: Theme.mcduCyan }
}
