import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// ARRIVAL — 1:1 port of React ArrivalPage.tsx
McduPage {
    id: page
    title: "ARRIVAL AT " + (FlightDataManager ? FlightDataManager.destination : "----")

    McduRow { left: "RWY"; right: "27L>"; rightColor: Theme.mcduWhite; bold: true }
    Repeater {
        model: ["LAM2E", "BIG3A", "OCK1G"]
        McduRow { left: "<" + modelData; right: ""; leftColor: Theme.mcduCyan }
    }
    Rectangle {
        Layout.fillWidth: true; Layout.topMargin: 6
        color: Qt.rgba(1,1,1,0.04)
        implicitHeight: ilsCol.implicitHeight + 8
        ColumnLayout {
            id: ilsCol
            anchors.fill: parent; anchors.margins: 4; spacing: 1
            McduRow { left: "ILS FREQ"; right: "109.50"; rightColor: Theme.mcduCyan; size: 10 }
            McduRow { left: "COURSE"; right: "272°"; size: 10 }
        }
    }
    Item { Layout.fillHeight: true }
    McduRow { left: "<F-PLN"; right: "APPR>"; leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan
        clickable: true; onClicked: if (page.fmsComputer) page.fmsComputer.navigateTo("fpln") }
}
