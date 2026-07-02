import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

/*
 * ECAM — Engine/Warning Display (upper) + System Display selector.
 * Faithful 1:1 port of React src/components/displays/ECAM.tsx.
 * Engine N1/EGT bind to AirDataComputer; remaining params use the same
 * constant fallbacks as the React source; hydraulics read FlightDataManager.
 */
Rectangle {
    id: root
    property var adc
    property string selectedPage: "ENG"
    color: Theme.mcduBackground // #000000

    readonly property color white60: Qt.rgba(Theme.white.r, Theme.white.g, Theme.white.b, 0.6)
    readonly property color line20:  Qt.rgba(Theme.white.r, Theme.white.g, Theme.white.b, 0.2)

    // ── label/value row (flex justify-between) ───────────────────────────────
    component ParamRow : RowLayout {
        property string label: ""
        property string value: ""
        property color  valueColor: Theme.green
        property int    valueSize: 13
        property bool   bold: false
        property int    labelSize: 10
        Layout.fillWidth: true
        spacing: 4
        Text { text: parent.label; color: root.white60; font.pixelSize: parent.labelSize }
        Item { Layout.fillWidth: true }
        Text {
            text: parent.value; color: parent.valueColor
            font.pixelSize: parent.valueSize; font.bold: parent.bold; font.family: "monospace"
        }
    }

    // ── one engine column (ENG 1 / ENG 2) ────────────────────────────────────
    component EngineColumn : ColumnLayout {
        property string title: ""
        property real n1: 0; property real n2: 0; property real egt: 0; property real ff: 0
        property real oilP: 0; property real oilT: 0; property real vib: 0
        Layout.fillWidth: true
        spacing: 8
        Text {
            text: parent.title; color: Theme.cyan; font.pixelSize: 12; font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
        ParamRow { label: "N1";    value: parent.n1.toFixed(1) + "%"; valueColor: Theme.green; valueSize: 16; bold: true }
        ParamRow { label: "N2";    value: parent.n2.toFixed(1) + "%"; valueColor: Theme.green; valueSize: 14 }
        ParamRow { label: "EGT";   value: Math.round(parent.egt) + "°C"; valueColor: parent.egt > 800 ? Theme.red : Theme.green; valueSize: 14 }
        ParamRow { label: "FF";    value: parent.ff + " KG/H"; valueColor: Theme.white; valueSize: 14 }
        ParamRow { label: "OIL P"; value: parent.oilP + " PSI"; valueColor: Theme.green; valueSize: 12 }
        ParamRow { label: "OIL T"; value: parent.oilT + "°C"; valueColor: Theme.green; valueSize: 12 }
        ParamRow { label: "VIB";   value: parent.vib.toFixed(1); valueColor: parent.vib > 0.7 ? Theme.amber : Theme.green; valueSize: 12 }
    }

    // ── status line (label : NORM/ON/etc) ────────────────────────────────────
    component StatusRow : RowLayout {
        property string label: ""
        property string value: ""
        property color  valueColor: Theme.green
        Layout.fillWidth: true
        Text { text: parent.label; color: root.white60; font.pixelSize: 11 }
        Item { Layout.fillWidth: true }
        Text { text: parent.value; color: parent.valueColor; font.pixelSize: 14; font.bold: true }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 32
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            x: 16; y: 16
            width: flick.width - 32
            spacing: 16

            // ── Title bar ─────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: "transparent"
                border.width: 0
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.line20 }
                Text {
                    anchors.centerIn: parent
                    text: "ENGINE / SYSTEMS"
                    color: Theme.cyan; font.pixelSize: 18; font.bold: true; font.letterSpacing: 1
                }
            }

            // ── Main two-column grid ──────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 24

                // Left: engine parameters + fuel
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.maximumWidth: parent ? (parent.width - 24) / 2 : 9999
                    clip: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "ENGINE PARAMETERS"; color: Theme.white; font.pixelSize: 14 }
                        Rectangle { Layout.fillWidth: true; height: 1; color: root.line20 }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        EngineColumn {
                            title: "ENG 1"
                            n1: root.adc ? root.adc.n1Left : 85.2; n2: 94.5
                            egt: root.adc ? root.adc.egtLeft : 715; ff: 1240
                            oilP: 38; oilT: 82; vib: 0.4
                        }
                        EngineColumn {
                            title: "ENG 2"
                            n1: root.adc ? root.adc.n1Right : 85.5; n2: 94.3
                            egt: root.adc ? root.adc.egtRight : 718; ff: 1235
                            oilP: 39; oilT: 81; vib: 0.3
                        }
                    }

                    // Fuel
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Rectangle { Layout.fillWidth: true; height: 1; color: root.line20 }
                        Text { text: "FUEL"; color: Theme.white; font.pixelSize: 14 }
                        ParamRow { label: "LEFT";   value: "5420 KG"; valueColor: Theme.green; valueSize: 14 }
                        ParamRow { label: "CENTER"; value: "4850 KG"; valueColor: Theme.green; valueSize: 14 }
                        ParamRow { label: "RIGHT";  value: "5380 KG"; valueColor: Theme.green; valueSize: 14 }
                        Rectangle { Layout.fillWidth: true; height: 1; color: root.line20 }
                        ParamRow { label: "FOB"; labelSize: 11; value: "15650 KG"; valueColor: Theme.cyan; valueSize: 16; bold: true }
                    }
                }

                // Right: systems status
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.maximumWidth: parent ? (parent.width - 24) / 2 : 9999
                    Layout.alignment: Qt.AlignTop
                    clip: true
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "SYSTEMS STATUS"; color: Theme.white; font.pixelSize: 14 }
                        Rectangle { Layout.fillWidth: true; height: 1; color: root.line20 }
                    }

                    // Hydraulic
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 6
                        Text { text: "HYDRAULIC"; color: Theme.cyan; font.pixelSize: 12; font.bold: true }
                        StatusRow { label: "GREEN";  value: (FlightDataManager.hydraulicGreen)  ? "NORM" : "OFF"; valueColor: FlightDataManager.hydraulicGreen  ? Theme.green : Theme.amber }
                        StatusRow { label: "BLUE";   value: (FlightDataManager.hydraulicBlue)   ? "NORM" : "OFF"; valueColor: FlightDataManager.hydraulicBlue   ? Theme.green : Theme.amber }
                        StatusRow { label: "YELLOW"; value: (FlightDataManager.hydraulicYellow) ? "NORM" : "OFF"; valueColor: FlightDataManager.hydraulicYellow ? Theme.green : Theme.amber }
                    }

                    // Electrical
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 6
                        Text { text: "ELECTRICAL"; color: Theme.cyan; font.pixelSize: 12; font.bold: true }
                        StatusRow { label: "GEN 1"; value: "ON" }
                        StatusRow { label: "GEN 2"; value: "ON" }
                        StatusRow { label: "BAT 1"; value: "AUTO" }
                        StatusRow { label: "BAT 2"; value: "AUTO" }
                    }

                    // Flight Controls
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 6
                        Text { text: "FLIGHT CONTROLS"; color: Theme.cyan; font.pixelSize: 12; font.bold: true }
                        StatusRow { label: "ELAC 1"; value: "NORM" }
                        StatusRow { label: "ELAC 2"; value: "NORM" }
                        StatusRow { label: "SEC 1";  value: "NORM" }
                        StatusRow { label: "FAC 1";  value: "NORM" }
                    }

                    // Pneumatic
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 6
                        Text { text: "PNEUMATIC"; color: Theme.cyan; font.pixelSize: 12; font.bold: true }
                        StatusRow { label: "ENG 1 BLEED"; value: "ON" }
                        StatusRow { label: "ENG 2 BLEED"; value: "ON" }
                        StatusRow { label: "APU BLEED"; value: "OFF"; valueColor: root.white60 }
                    }
                }
            }

            // ── Lower ECAM section: page selector ─────────────────────────────
            Rectangle { Layout.fillWidth: true; height: 1; color: root.line20 }

            Flow {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: ["ENG","BLEED","PRESS","ELEC","HYD","FUEL","APU","COND","DOOR","WHEEL","F/CTL","STS"]
                    Rectangle {
                        required property string modelData
                        readonly property bool active: root.selectedPage === modelData
                        width: pgLabel.implicitWidth + 16
                        height: pgLabel.implicitHeight + 8
                        radius: 4
                        color: active ? Theme.cyan : (pgMouse.containsMouse ? "#374151" : "#1f2937")
                        Text {
                            id: pgLabel
                            anchors.centerIn: parent
                            text: parent.modelData
                            font.pixelSize: 10; font.family: "monospace"
                            color: parent.active ? "#000000" : "#9ca3af"
                        }
                        MouseArea {
                            id: pgMouse
                            anchors.fill: parent; hoverEnabled: true
                            onClicked: root.selectedPage = parent.modelData
                        }
                    }
                }
            }

            // ── Lower ECAM display ────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 256
                color: "transparent"
                radius: 4
                border.color: root.line20; border.width: 1
                clip: true
                ECAMLowerDisplay {
                    anchors.fill: parent
                    anchors.margins: 1
                    selectedPage: root.selectedPage
                    adc: root.adc
                }
            }

            // ── Memo line ─────────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Rectangle { Layout.fillWidth: true; height: 1; color: root.line20 }
                Text {
                    id: memo
                    color: Theme.green; font.pixelSize: 10; font.family: "monospace"
                    text: "ALL SYSTEMS NORMAL - " + Qt.formatTime(new Date(), "hh:mm") + " UTC"
                    Timer {
                        interval: 10000; running: true; repeat: true
                        onTriggered: memo.text = "ALL SYSTEMS NORMAL - " + Qt.formatTime(new Date(), "hh:mm") + " UTC"
                    }
                }
            }
        }
    }
}
