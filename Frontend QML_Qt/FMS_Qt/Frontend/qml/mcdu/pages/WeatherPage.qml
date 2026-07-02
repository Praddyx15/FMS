import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// WEATHER INFO — 1:1 port of React WeatherPage.tsx
McduPage {
    id: page
    title: "WEATHER INFO"
    readonly property string dep: FlightDataManager ? FlightDataManager.departure : "----"
    readonly property string dest: FlightDataManager ? FlightDataManager.destination : "----"

    McduRow { left: "STATION"; right: page.dep }
    Text {
        Layout.fillWidth: true
        color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10; lineHeight: 0.95
        text: "METAR " + page.dep + " 121350Z\n27015KT 9999 FEW035\nSCT250 08/M02 Q1015\nNOSIG"
    }
    McduRow { left: "TAF";     right: "AVAIL"; rightColor: Theme.mcduCyan }
    McduRow { left: "DEST WX"; right: page.dest }
    Text {
        Layout.fillWidth: true
        color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10; lineHeight: 0.95
        text: "METAR " + page.dest + " 121350Z\n09008KT CAVOK 12/05\nQ1018 NOSIG"
    }
    McduRow { left: "WIND ALOFT"; right: "FL320" }
    McduRow { left: "DIR/SPD";    right: "270/85KT"; rightColor: Theme.mcduCyan }
    McduRow { left: "TEMP";       right: "-48°C" }
    Item { Layout.fillHeight: true }
}
