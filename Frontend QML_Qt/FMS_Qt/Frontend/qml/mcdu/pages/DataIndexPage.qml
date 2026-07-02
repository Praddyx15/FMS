import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// DATA INDEX — 1:1 port of React DataIndexPage.tsx
McduPage {
    id: page
    title: "DATA INDEX"
    function nav(p) { if (page.fmsComputer) page.fmsComputer.navigateTo(p) }

    McduRow { left: "<POSITION";  right: "IRS>";     leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan; clickable: true; onClicked: page.nav("pos_init") }
    McduRow { left: "<WIND";      right: "GPS>";     leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan; clickable: true; onClicked: page.nav("wind") }
    McduRow { left: "<WAYPOINTS"; right: "NAVAIDS>"; leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan }
    McduRow { left: "<AIRPORTS";  right: "RUNWAYS>"; leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan }
    McduRow { left: "<ROUTES";    right: "AIRWAYS>"; leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan; clickable: true; onClicked: page.nav("rte_sel") }
    McduSep {}
    McduRow { left: "<STATUS";    right: "CLOSEST>"; leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan; clickable: true; onClicked: page.nav("sys_status") }
    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "DATABASE EXPIRY: 28 DEC 2025"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10 }
    Item { Layout.fillHeight: true }
}
