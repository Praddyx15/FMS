import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// FLT INIT MENU — 1:1 port of React FltInitPage.tsx
McduPage {
    id: page
    title: "FLT INIT MENU"

    McduRow { left: "<FLT NBR"; right: "BA0123"; leftColor: Theme.mcduCyan; bold: true }
    McduRow { left: "COMPANY";  right: "BRITISH AIRWAYS"; rightColor: Theme.mcduCyan }
    McduSep {}
    McduRow { left: "DATE";     right: Qt.formatDate(new Date(), "dd MMM yyyy").toUpperCase() }
    McduRow { left: "UTC TIME"; right: Qt.formatTime(new Date(), "HH:mm") + "Z"; rightColor: Theme.mcduCyan }
    McduSep {}
    McduRow { left: "DATABASE"; right: "AIRAC 2513"; size: 10 }
    McduRow { left: "EXPIRY";   right: "28 DEC 2025"; rightColor: Theme.mcduCyan; size: 10 }
    McduSep {}
    McduRow { left: "<ACFT TYPE"; right: "A320-214"; leftColor: Theme.mcduCyan }
    McduRow { left: "<REG";       right: "G-EUUU";   leftColor: Theme.mcduCyan }
    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "FLIGHT INIT COMPLETE"; color: Theme.mcduGreen; font.family: Theme.fontFms; font.pixelSize: 10 }
    Item { Layout.fillHeight: true }
}
