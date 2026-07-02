import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0
import QtQuick.Layouts 1.15

// FMA — 5-column Flight Mode Annunciator
// Each box shows:  top = active mode (coloured, large)
//                  bottom = armed mode (white, small)
// Green border flashes 10s on active-mode change (A320 standard).
Rectangle {
    id: root
    property var adc
    color: "#0d1017"
    radius: 3
    border.color: "#2a2d35"
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: 2
        spacing: 1

        // Box 1 — A/THR
        FMACell {
            activeMode:  adc ? adc.autoThrustMode : "- -"
            armedMode:   (adc && (adc.ap1Active || adc.ap2Active)) ? "SPEED" : ""
            activeColor: (adc && adc.athrActive) ? Theme.green : Theme.mutedFg
            boxCol:      "#1a2010"
            label:       "A/THR"
        }
        Rectangle { width: 1; Layout.fillHeight: true; color: "#2a2d35" }

        // Box 2 — Lateral
        FMACell {
            activeMode:  adc ? adc.lateralMode       : "- -"
            armedMode:   adc ? adc.armedLateralMode  : ""
            activeColor: Theme.green
            boxCol:      "#101a28"
            label:       "LATERAL"
        }
        Rectangle { width: 1; Layout.fillHeight: true; color: "#2a2d35" }

        // Box 3 — Vertical
        FMACell {
            activeMode:  adc ? adc.verticalMode      : "- -"
            armedMode:   adc ? adc.armedVerticalMode : ""
            activeColor: Theme.cyan
            boxCol:      "#101a28"
            label:       "VERTICAL"
        }
        Rectangle { width: 1; Layout.fillHeight: true; color: "#2a2d35" }

        // Box 4 — Approach
        FMACell {
            activeMode:  adc ? adc.approachMode : "- -"
            armedMode:   (adc && adc.ilsArmed)  ? "LOC*" : ""
            activeColor: Theme.cyan
            boxCol:      "#1a1a20"
            label:       "APPROACH"
        }
        Rectangle { width: 1; Layout.fillHeight: true; color: "#2a2d35" }

        // Box 5 — AP engagement
        FMACell {
            property bool ap1: adc ? adc.ap1Active : false
            property bool ap2: adc ? adc.ap2Active : false
            activeMode:  ap1 && ap2 ? "1+2" : ap1 ? "AP1" : ap2 ? "AP2" : "AP OFF"
            armedMode:   ""
            activeColor: (ap1 || ap2) ? Theme.green : Theme.red
            boxCol:      "#101a10"
            label:       "AP"
        }
    }

    // FMA cell sub-component
    component FMACell : Rectangle {
        property string activeMode:  ""
        property string armedMode:   ""
        property color  activeColor: Theme.mutedFg
        property color  boxCol:      "#101010"
        property string label:       ""

        Layout.fillWidth: true
        Layout.fillHeight: true
        color: boxCol
        radius: 2

        // Flash green border 10s on active mode change
        property string _prevActive: ""
        border.color: flashTimer.running ? Theme.green : "transparent"
        border.width: 2

        Timer {
            id: flashTimer
            interval: 10000
            running:  false
            repeat:   false
        }
        onActiveModeChanged: {
            if (_prevActive !== "" && _prevActive !== activeMode) {
                flashTimer.restart()
            }
            _prevActive = activeMode
        }

        Column {
            anchors.centerIn: parent
            spacing: 1

            // Active mode — large, bold, coloured
            Text {
                text:                   parent.parent.activeMode
                color:                  parent.parent.activeColor
                font.pixelSize:         11
                font.bold:              true
                font.family:            "Consolas"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            // Armed mode — small, white
            Text {
                text:                   parent.parent.armedMode
                color:                  Theme.white
                font.pixelSize:         8
                font.family:            "Consolas"
                visible:                parent.parent.armedMode !== ""
                anchors.horizontalCenter: parent.horizontalCenter
            }
            // Column header label
            Text {
                text:                   parent.parent.label
                color:                  "#546e7a"
                font.pixelSize:         7
                font.family:            "Consolas"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}

