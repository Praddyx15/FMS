import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// ALTERNATE DEST — 1:1 port of React AlternatePage.tsx
McduPage {
    id: page
    title: "ALTERNATE DEST"

    McduRow { left: "<ICAO"; right: FlightDataManager ? (FlightDataManager.alternate || "----") : "----"; leftColor: Theme.mcduCyan; bold: true }
    McduSep {}
    McduRow { left: "DIST";     right: "118 NM" }
    McduRow { left: "BRG";      right: "048°" }
    McduRow { left: "TIME";     right: "00:28" }
    McduRow { left: "FUEL REQ"; right: "1800 KG"; rightColor: Theme.mcduCyan }
    McduSep {}
    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "RUNWAYS"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 11 }
    McduRow { left: "07L/25R"; right: "3000M"; size: 10 }
    McduRow { left: "07R/25L"; right: "2700M"; size: 10 }
    Rectangle {
        Layout.fillWidth: true; Layout.topMargin: 4
        color: Qt.rgba(1,1,1,0.04)
        implicitHeight: wxCol.implicitHeight + 8
        ColumnLayout {
            id: wxCol
            anchors.fill: parent; anchors.margins: 4; spacing: 1
            Text { text: "WEATHER"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10 }
            Text { text: "SCT025 BKN040\nWIND 250/15KT\nTEMP 18/12 Q1018"; color: Theme.mcduCyan; font.family: Theme.fontFms; font.pixelSize: 10; lineHeight: 0.95 }
        }
    }
    Item { Layout.fillHeight: true }
    McduRow { left: "<RETURN"; right: ""; leftColor: Theme.mcduCyan }
}
