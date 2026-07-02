import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// MCDU MENU — 1:1 port of React MCDUMenuPage.tsx
McduPage {
    id: page
    title: "MCDU MENU"

    McduRow { left: "<FMGC";        right: "AIDS>";  leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan; clickable: true; onClicked: if (page.fmsComputer) page.fmsComputer.navigateTo("fmgc") }
    McduRow { left: "<ACARS";       right: "ATSU>";  leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan; clickable: true; onClicked: if (page.fmsComputer) page.fmsComputer.navigateTo("atsu") }
    McduRow { left: "<AIDS";        right: "CFG>";   leftColor: Theme.mcduCyan; rightColor: Theme.mcduCyan }
    McduRow { left: "PRINT";        right: "";       leftColor: Theme.mcduWhite }
    McduRow { left: "<FUNCTION";    right: "";       leftColor: Theme.mcduCyan }
    McduRow { left: "<MCDU STATUS"; right: "";       leftColor: Theme.mcduCyan }
    McduSep {}
    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "SOFTWARE VERSION"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 11 }
    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "FMGS: V3.12.1\nMCDU: V2.08.5"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10 }
    Item { Layout.fillHeight: true }
}
