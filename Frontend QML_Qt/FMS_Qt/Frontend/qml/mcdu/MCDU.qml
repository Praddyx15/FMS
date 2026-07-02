import QtQuick
import FmsTrainer 1.0
import FmsBackend 1.0

// MCDU — A320-200 panel. Visual design from the user's prepared MCDUPanel,
// adapted to the project: keys wired to FMSComputer and the live MCDUScreen
// hosted in the display area so pages + scratchpad work.
Rectangle {
    id: panel
    property var fmsComputer
    property var adc

    implicitWidth: 420
    implicitHeight: 660
    radius: 16
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#9aa6b2" }
        GradientStop { position: 1.0; color: "#7c8794" }
    }
    border.color: "#5a626c"
    border.width: 2
    focus: true

    function nav(p) { if (panel.fmsComputer) panel.fmsComputer.navigateTo(p) }
    function key(l) {
        if (!panel.fmsComputer) return
        if (l === "+/-") panel.fmsComputer.pressKey("PLUSMINUS")
        else if (l === "OVFY") { /* overfly — not a scratchpad char */ }
        else panel.fmsComputer.pressKey(l)
    }

    // physical keyboard input
    MouseArea { anchors.fill: parent; z: -1; onPressed: panel.forceActiveFocus() }
    Keys.onPressed: (e) => {
        if (!fmsComputer) return
        var k = e.text.toUpperCase()
        if (k >= "A" && k <= "Z") { fmsComputer.pressKey(k); e.accepted = true }
        else if (k >= "0" && k <= "9") { fmsComputer.pressKey(k); e.accepted = true }
        else if (e.key === Qt.Key_Slash) { fmsComputer.pressKey("/"); e.accepted = true }
        else if (e.key === Qt.Key_Period) { fmsComputer.pressKey("."); e.accepted = true }
        else if (e.key === Qt.Key_Space) { fmsComputer.pressKey("SP"); e.accepted = true }
        else if (e.key === Qt.Key_Backspace || e.key === Qt.Key_Delete) { fmsComputer.pressKey("CLR"); e.accepted = true }
    }

    // mounting screws
    Repeater {
        model: [ Qt.point(18, 18), Qt.point(panel.width - 18, 18) ]
        delegate: Rectangle {
            x: modelData.x - 8; y: modelData.y - 8
            width: 16; height: 16; radius: 8; color: "#3a3f44"; border.color: "#1c1e20"
            Rectangle { anchors.centerIn: parent; width: 9; height: 2; color: "#0c0d0e" }
        }
    }

    Column {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 14
        spacing: 7

        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "A320-200"; color: "#eef2f0"; font.family: "Consolas"; font.pixelSize: 16; font.bold: true; font.letterSpacing: 2 }

        // ---------- SCREEN ROW (LSKs + live display) ----------
        Row {
            spacing: 6
            Column {
                spacing: 33
                anchors.verticalCenter: screen.verticalCenter
                Repeater { model: 6; delegate: LineKey { width: 30; height: 16; onClicked: if (panel.fmsComputer) panel.fmsComputer.handleLSK("L", index) } }
            }

            Rectangle {
                id: screen
                width: 320; height: 274
                color: "#070908"; radius: 3; border.color: "#26292c"; border.width: 3
                MCDUScreen {
                    anchors.fill: parent; anchors.margins: 4
                    fmsComputer: panel.fmsComputer
                    adc: panel.adc
                }
            }

            Column {
                spacing: 33
                anchors.verticalCenter: screen.verticalCenter
                Repeater { model: 6; delegate: LineKey { width: 30; height: 16; onClicked: if (panel.fmsComputer) panel.fmsComputer.handleLSK("R", index) } }
            }
        }

        // ---------- FUNCTION KEY ROWS + BRT/DIM ----------
        Column {
            spacing: 6
            anchors.horizontalCenter: parent.horizontalCenter
            Row {
                spacing: 6
                MCDUKey { label: "DIR";  onClicked: panel.nav("dir_to") }
                MCDUKey { label: "PROG"; onClicked: panel.nav("prog") }
                MCDUKey { label: "PERF"; onClicked: panel.nav("perf") }
                MCDUKey { label: "INIT"; onClicked: panel.nav("init") }
                MCDUKey { label: "DATA"; onClicked: panel.nav("data_index") }
                MCDUKey { label: "BRT"; labelColor: "#ffffff"; onClicked: {} }
            }
            Row {
                spacing: 6
                MCDUKey { label: "F-PLN"; onClicked: panel.nav("fpln") }
                MCDUKey { label: "RAD";  subLabel: "NAV";   onClicked: panel.nav("radnav") }
                MCDUKey { label: "FUEL"; subLabel: "PRED";  onClicked: panel.nav("fuel_pred") }
                MCDUKey { label: "SEC";  subLabel: "F-PLN"; onClicked: panel.nav("sec_fpln") }
                MCDUKey { label: "ATC";  subLabel: "COMM";  onClicked: panel.nav("atc_comm") }
                MCDUKey { label: "MCDU"; subLabel: "MENU";  onClicked: panel.nav("menu") }
            }
        }

        // ---------- AIRPORT / ARROWS + NUMERIC + ALPHA KEYPAD ----------
        Row {
            spacing: 14
            anchors.horizontalCenter: parent.horizontalCenter
            Column {
                spacing: 6
                Row {
                    spacing: 4
                    MCDUKey { label: "AIR"; subLabel: "PORT"; implicitWidth: 88; implicitHeight: 68; onClicked: panel.nav("data_index") }
                    Column {
                        spacing: 4
                        Row {
                            spacing: 4
                            MCDUKey { label: "←"; implicitWidth: 42; onClicked: if (panel.fmsComputer && panel.fmsComputer.currentPage === "init_b") panel.nav("init") }
                            MCDUKey { label: "↑"; implicitWidth: 42; onClicked: if (panel.fmsComputer) panel.fmsComputer.scrollUp() }
                        }
                        Row {
                            spacing: 4
                            MCDUKey { label: "→"; implicitWidth: 42; onClicked: if (panel.fmsComputer && panel.fmsComputer.currentPage === "init") panel.nav("init_b") }
                            MCDUKey { label: "↓"; implicitWidth: 42; onClicked: if (panel.fmsComputer) panel.fmsComputer.scrollDown() }
                        }
                    }
                }
                Grid {
                    columns: 3; spacing: 4
                    Repeater {
                        model: ["1","2","3","4","5","6","7","8","9",".","0","+/-"]
                        MCDUKey { label: modelData; onClicked: panel.key(modelData) }
                    }
                }
            }

            Grid {
                columns: 5; spacing: 4
                Repeater {
                    model: ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","/","SP","OVFY","CLR"]
                    MCDUKey {
                        label: modelData
                        labelSize: modelData === "OVFY" ? 10 : 13
                        labelColor: modelData === "CLR" ? "#2fd4e8" : "#f2f2f2"
                        highlight: modelData === "E" || modelData === "N" || modelData === "S" || modelData === "W"
                        onClicked: panel.key(modelData)
                    }
                }
            }
        }
    }
}
