import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// WEATHER REQUEST — 1:1 port of React WeatherReqPage.tsx
McduPage {
    id: page
    title: "WEATHER REQUEST"
    property string wxType: "METAR"

    McduRow { left: "<ICAO"; right: "KJFK"; leftColor: Theme.mcduCyan; bold: true }
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 4
        Repeater {
            model: ["METAR", "TAF", "SIGMET"]
            Text {
                Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: page.wxType === modelData ? Theme.mcduGreen : Theme.mcduCyan
                font.family: Theme.fontFms; font.pixelSize: 11
                MouseArea { anchors.fill: parent; onClicked: page.wxType = modelData }
            }
        }
    }
    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "<REQUEST"; color: Theme.mcduCyan; font.family: Theme.fontFms; font.pixelSize: 11 }
    Rectangle {
        Layout.fillWidth: true; Layout.topMargin: 4
        color: Qt.rgba(1,1,1,0.04)
        implicitHeight: respTxt.implicitHeight + 8
        Text { id: respTxt; anchors.fill: parent; anchors.margins: 4; wrapMode: Text.WordWrap
            text: "METAR KJFK 121351Z 27015KT 10SM FEW035 SCT250 08/M02 A2992 NOSIG"
            color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10 }
    }
    McduSep {}
    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "REQUEST HISTORY"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10 }
    Repeater {
        model: [ { time: "1345Z", icao: "EGLL", type: "METAR" }, { time: "1320Z", icao: "LFPG", type: "TAF" } ]
        RowLayout {
            Layout.fillWidth: true
            Text { text: modelData.time; color: Theme.mcduCyan; font.family: Theme.fontFms; font.pixelSize: 10 }
            Item { Layout.fillWidth: true }
            Text { text: modelData.icao; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10 }
            Item { Layout.fillWidth: true }
            Text { text: modelData.type; color: Theme.mcduGreen; font.family: Theme.fontFms; font.pixelSize: 10 }
        }
    }
    Item { Layout.fillHeight: true }
}
