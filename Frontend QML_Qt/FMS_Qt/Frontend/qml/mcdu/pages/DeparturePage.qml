import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// DEPARTURE — 1:1 port of React DeparturePage.tsx
McduPage {
    id: page
    title: "DEPARTURE FROM " + (FlightDataManager ? FlightDataManager.departure : "----")

    McduRow { left: "<RWY"; right: "09L"; leftColor: Theme.mcduCyan; bold: true }
    Repeater {
        model: ["MERIT5", "GREKI3", "JFK7"]
        McduRow { left: "<" + modelData; right: ""; leftColor: Theme.mcduCyan }
    }
    Rectangle {
        Layout.fillWidth: true; Layout.topMargin: 6
        color: Qt.rgba(1,1,1,0.04)
        implicitHeight: rwyCol.implicitHeight + 8
        ColumnLayout {
            id: rwyCol
            anchors.fill: parent; anchors.margins: 4; spacing: 1
            McduRow { left: "RWY 09L"; right: "3460M"; size: 10 }
            McduRow { left: "ILS"; right: "110.90"; rightColor: Theme.mcduCyan; size: 10 }
        }
    }
    Item { Layout.fillHeight: true }
    McduRow { left: "<F-PLN"; right: "PERF>"; leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan
        clickable: true; onClicked: if (page.fmsComputer) page.fmsComputer.navigateTo("fpln") }
}
