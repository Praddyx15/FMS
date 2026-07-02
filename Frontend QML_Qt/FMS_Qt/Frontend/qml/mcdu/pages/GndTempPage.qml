import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// GND TEMP — 1:1 port of React GndTempPage.tsx
McduPage {
    id: page
    title: "GND TEMP"

    McduRow { left: "<GND TEMP"; right: "15°C"; leftColor: Theme.mcduCyan }
    McduRow { left: "<QNH";      right: "1013"; leftColor: Theme.mcduCyan }
    Rectangle {
        Layout.fillWidth: true; Layout.topMargin: 6
        color: Qt.rgba(1,1,1,0.04)
        implicitHeight: cvCol.implicitHeight + 10
        ColumnLayout {
            id: cvCol
            anchors.fill: parent; anchors.margins: 5; spacing: 2
            Text { Layout.alignment: Qt.AlignHCenter; text: "COMPUTED VALUES"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 11 }
            McduRow { left: "PRESS ALT";   right: "0 FT";   rightColor: Theme.mcduCyan }
            McduRow { left: "DENSITY ALT"; right: "0 FT";   rightColor: Theme.mcduCyan }
            McduRow { left: "ISA DEV";     right: "+0.0°C"; rightColor: Theme.mcduAmber }
        }
    }
    McduSep {}
    McduRow { left: "FIELD ELEV";  right: "0 FT" }
    McduRow { left: "ISA @ FIELD"; right: "15.0°C"; rightColor: Theme.mcduCyan }
    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "NORMAL CONDITIONS"; color: Theme.mcduGreen; font.family: Theme.fontFms; font.pixelSize: 10 }
    Item { Layout.fillHeight: true }
}
