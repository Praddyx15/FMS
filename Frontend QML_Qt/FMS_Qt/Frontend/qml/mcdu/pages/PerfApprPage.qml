import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// PERF APPR — 1:1 port of React PerfApprPage.tsx
McduPage {
    id: page
    title: "PERF APPR"

    McduRow { left: "<QNH";     right: "1013"; leftColor: Theme.mcduCyan }
    McduRow { left: "<TEMP";    right: "15°C"; leftColor: Theme.mcduCyan }
    McduRow { left: "<MAG VAR"; right: "3°W";  leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan }
    McduSep {}
    McduRow { left: "LDG WT"; right: "62500 KG" }

    Rectangle {
        Layout.fillWidth: true; Layout.topMargin: 4
        color: Qt.rgba(1,1,1,0.04)
        implicitHeight: spdCol.implicitHeight + 10
        ColumnLayout {
            id: spdCol
            anchors.fill: parent; anchors.margins: 5; spacing: 2
            Text { Layout.alignment: Qt.AlignHCenter; text: "APPROACH SPEEDS"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 11 }
            GridLayout {
                Layout.fillWidth: true; columns: 2; rowSpacing: 2; columnSpacing: 16
                McduRow { left: "VAPP"; right: "138"; rightColor: Theme.mcduGreen }
                McduRow { left: "VLS";  right: "130"; rightColor: Theme.mcduCyan }
                McduRow { left: "VF";   right: "128"; rightColor: Theme.mcduGreen }
                McduRow { left: "VS";   right: "124"; rightColor: Theme.mcduGreen }
                McduRow { Layout.columnSpan: 2; left: "GREEN DOT"; right: "151"; rightColor: Theme.mcduGreen }
            }
        }
    }
    McduRow { left: "LDG DIST"; right: "1850 M" }
    McduRow { left: "<FLAPS";   right: "FULL"; leftColor: Theme.mcduCyan }
    Item { Layout.fillHeight: true }
}
