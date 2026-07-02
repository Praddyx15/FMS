import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// SEC F-PLN — 1:1 port of React SecFplnPage.tsx
McduPage {
    id: page
    title: "SEC F-PLN"
    titleColor: Theme.mcduAmber

    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "SECONDARY"; color: Theme.mcduAmber; font.family: Theme.fontFms; font.pixelSize: 11 }
    Repeater {
        model: FlightDataManager ? FlightDataManager.waypoints.slice(0, 5) : []
        McduRow {
            left: modelData.name !== undefined ? modelData.name : ""
            right: (modelData.altitude !== undefined && modelData.altitude > 0) ? ("FL" + Math.floor(modelData.altitude / 100)) : "-----"
            leftColor: Theme.mcduWhite
            rightColor: Theme.mcduGreen
        }
    }
    McduSep {}
    McduRow { left: "<COPY ACT"; right: ""; leftColor: Theme.mcduCyan }
    McduRow { left: "<ACTIVATE"; right: ""; leftColor: Theme.mcduCyan }
    McduRow { left: "<ERASE";    right: ""; leftColor: Theme.mcduCyan }
    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "Secondary flight plan for what-if scenarios"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 9; wrapMode: Text.WordWrap }
    Item { Layout.fillHeight: true }
    McduRow { left: "<F-PLN"; right: ""; leftColor: Theme.mcduCyan
        clickable: true; onClicked: if (page.fmsComputer) page.fmsComputer.navigateTo("fpln") }
}
