import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// AICoach — contextual flight coaching tips panel
Rectangle {
    id: root
    property var adc
    color: "#0d1017"
    radius: 6
    border.color: "#2a2d35"
    clip: true

    // Tip database keyed by flight phase / condition
    property var tipDatabase: ({
        "cruise":   [
            "Monitor fuel consumption against the F-PLN PROG page predictions.",
            "Cross-check MACH vs IAS target — above the crossover altitude use MACH.",
            "Verify that the lateral mode shows NAV and vertical shows CRZ or ALT.",
        ],
        "approach": [
            "Arm the approach by pressing APPR on the FCU. Confirm LOC* then GS*.",
            "Brief the missed approach: heading, altitude, and missed approach point.",
            "Set VAPP in the MCDU PERF APPR page before intercepting the glideslope.",
        ],
        "takeoff":  [
            "Cross-check V1, VR, V2 against the PERF TAKE-OFF page before lining up.",
            "After V1, relax backpressure until VR then rotate at 3°/sec to 15° pitch.",
            "Retract gear when positive rate of climb is confirmed on VSI.",
        ],
        "climb":    [
            "Select managed climb (open CLB) unless ATC assigns a speed restriction.",
            "Monitor EGT during climb — ensure it stays below the red line.",
            "Pass the acceleration altitude and retract flaps/slats per normal law.",
        ],
        "descent":  [
            "Check T/D (top of descent) on the ND — initiate managed descent when reached.",
            "Verify cabin pressure schedule matches the descent profile.",
            "Keep IAS below 250 kt below FL100 — ATC compliance.",
        ],
        "preflight":[
            "Enter FROM/TO in the INIT A page. Confirm alternates and cost index.",
            "Enter ZFW, BLOCK fuel on the INIT B page.",
            "Verify V-speeds are set correctly on the PERF TAKE-OFF page.",
        ],
    })

    property string currentPhase: root.adc ? root.adc.flightPhase : "cruise"
    property int    tipIndex:     0
    property var    tips:         tipDatabase[currentPhase] || tipDatabase["cruise"]

    onCurrentPhaseChanged: {
        tips = tipDatabase[currentPhase] || tipDatabase["cruise"]
        tipIndex = 0
    }

    // Rotate tips every 12 seconds
    Timer {
        interval: 12000; running: true; repeat: true
        onTriggered: {
            root.tipIndex = (root.tipIndex + 1) % root.tips.length
        }
    }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 10; spacing: 8

        // Header
        RowLayout {
            Label { text: "🤖  AI COACH"; color: "#e040fb"; font.pixelSize: 12; font.bold: true; font.family: "Consolas" }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 8; height: 8; radius: 4; color: "#00e676"
                SequentialAnimation on opacity { running: true; loops: Animation.Infinite
                    PropertyAnimation { to: 0.2; duration: 800 }
                    PropertyAnimation { to: 1.0; duration: 800 }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2d35" }

        // Phase badge
        Rectangle {
            Layout.fillWidth: true; height: 24; radius: 12
            color: Qt.rgba(0.88, 0.25, 0.98, 0.15)
            border.color: "#e040fb"; border.width: 1
            Text {
                anchors.centerIn: parent
                text: "✦  " + root.currentPhase.toUpperCase() + " PHASE"
                color: "#e040fb"; font.pixelSize: 9; font.bold: true; font.family: "Consolas"
            }
        }

        // Tip card with fade transition
        Item {
            Layout.fillWidth: true; Layout.preferredHeight: 100; clip: true

            Rectangle {
                id: tipCard
                anchors.fill: parent; radius: 6
                color: "#12141a"; border.color: "#2a2d35"

                Rectangle {
                    width: 3; height: parent.height * 0.6
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    color: "#e040fb"; radius: 2
                }

                Text {
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 12; leftPadding: 8
                    text: root.tips[root.tipIndex]
                    color: "#e0e0e0"; font.pixelSize: 10; font.family: "Consolas"
                    wrapMode: Text.WordWrap
                }

                SequentialAnimation on opacity {
                    id: tipFade; running: false
                    NumberAnimation { to: 0; duration: 300 }
                    PropertyAction { target: tipCard; property: "opacity"; value: 0 }
                    NumberAnimation { to: 1; duration: 300 }
                }
                Connections {
                    target: root
                    function onTipIndexChanged() { tipFade.restart() }
                }
            }
        }

        // Tip dot indicators
        Row {
            Layout.alignment: Qt.AlignHCenter; spacing: 5
            Repeater {
                model: root.tips.length
                Rectangle {
                    width: index === root.tipIndex ? 10 : 6
                    height: 6; radius: 3
                    color: index === root.tipIndex ? "#e040fb" : "#37474f"
                    Behavior on width { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // Navigation buttons
        RowLayout {
            spacing: 4
            Button {
                text: "◁ PREV"; Layout.fillWidth: true; height: 26
                background: Rectangle { color: "#1a1d24"; radius: 4; border.color: "#2a2d35" }
                contentItem: Text { text: parent.text; color: "#78909c"; font.pixelSize: 9; font.family: "Consolas"; horizontalAlignment: Text.AlignHCenter }
                onClicked: root.tipIndex = (root.tipIndex - 1 + root.tips.length) % root.tips.length
            }
            Button {
                text: "NEXT ▷"; Layout.fillWidth: true; height: 26
                background: Rectangle { color: "#1a1d24"; radius: 4; border.color: "#2a2d35" }
                contentItem: Text { text: parent.text; color: "#78909c"; font.pixelSize: 9; font.family: "Consolas"; horizontalAlignment: Text.AlignHCenter }
                onClicked: root.tipIndex = (root.tipIndex + 1) % root.tips.length
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2d35" }

        // Live parameters
        Label { text: "LIVE PARAMETERS"; color: "#546e7a"; font.pixelSize: 8; font.family: "Consolas"; font.bold: true }

        GridLayout {
            columns: 2; rowSpacing: 2; columnSpacing: 8; Layout.fillWidth: true

            Repeater {
                model: [
                    { label: "IAS",  value: () => root.adc ? Math.round(root.adc.ias) + " kt" : "---",  col: "#00e5ff" },
                    { label: "ALT",  value: () => root.adc ? Math.round(root.adc.altitude) + " ft" : "---", col: "#00e5ff" },
                    { label: "VSI",  value: () => root.adc ? Math.round(root.adc.vsi) + " fpm" : "---", col: root.adc && root.adc.vsi < -100 ? "#ff9800" : "#00e676" },
                    { label: "N1",   value: () => root.adc ? root.adc.n1Left.toFixed(0) + "%" : "---",  col: "#ffab40" },
                ]
                RowLayout {
                    spacing: 4
                    Text { text: modelData.label; color: "#546e7a"; font.pixelSize: 8; font.family: "Consolas"; Layout.preferredWidth: 28 }
                    Text { text: modelData.value(); color: modelData.col; font.pixelSize: 10; font.bold: true; font.family: "Consolas" }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
