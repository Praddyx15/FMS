import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0

// ThrottleQuadrant — 1:1 port of React controls/ThrottleQuadrant.tsx
Rectangle {
    id: root
    property var adc
    implicitHeight: 470
    color: Theme.cockpitPanel
    radius: 6
    border.color: Theme.cockpitBorder; border.width: 2

    property real eng1: 30
    property real eng2: 30
    property bool throttleLock: false
    property bool athr: root.adc ? root.adc.athrActive : false
    property int  flaps: 0
    property real speedBrake: 0
    readonly property var flapsNames: ["0", "1", "2", "3", "FULL"]
    function n1(t) { return Math.round(t * 0.9 + 10) }

    // TLA domain is 0..45 deg (IDLE..TOGA); this lever is a 0..100 percent
    // scale, top = TOGA (matches the detent markers below).
    function pctToTla(pct) { return pct / 100.0 * 45.0; }
    function tlaToPct(tla) { return tla / 45.0 * 100.0; }

    // Reflect actual backend state on load (adc.tla1/2 default to 0 = IDLE)
    // rather than the arbitrary eng1/eng2: 30 visual default.
    Component.onCompleted: {
        if (root.adc) {
            root.eng1 = root.tlaToPct(root.adc.tla1);
            root.eng2 = root.tlaToPct(root.adc.tla2);
            root.flaps = root.adc.flapHandleIndex;
            root.speedBrake = root.adc.speedbrakeLever * 100.0;
        }
    }

    // one vertical throttle lever with detent scale
    component VThrottle : Item {
        id: vthrottle
        property string eng: "ENG 1"
        property real value: 30
        property bool active: false
        signal moved(real v)
        width: 120; height: 210
        Text { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; text: vthrottle.eng; color: Theme.white; font.pixelSize: 11 }
        Item {
            id: leverTrack
            anchors.top: parent.top; anchors.topMargin: 20; anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
            width: 90
            // scale bar
            Rectangle {
                id: track
                anchors.left: parent.left; width: 22; anchors.top: parent.top; anchors.bottom: parent.bottom
                color: "#1f2937"; radius: 6; border.color: "#374151"
                Rectangle { anchors.top: parent.top; width: parent.width; height: 2; color: "#ef4444" }       // TO/GA
                Rectangle { y: parent.height*0.15; width: parent.width; height: 2; color: "#eab308" }          // FLX/MCT
                Rectangle { y: parent.height*0.90; width: parent.width; height: 2; color: "#22c55e" }          // CL
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2; color: "#3b82f6" }  // IDLE
            }
            // detent labels
            Text { x: 28; y: 0;                     text: "TO/GA";   color: "#f87171"; font.pixelSize: 8 }
            Text { x: 28; y: parent.height*0.15;    text: "FLX/MCT"; color: "#facc15"; font.pixelSize: 8 }
            Text { x: 28; y: parent.height*0.88;    text: "CL";      color: "#4ade80"; font.pixelSize: 8 }
            Text { x: 28; y: parent.height - 10;    text: "IDLE";    color: "#60a5fa"; font.pixelSize: 8 }
            // lever — use vthrottle.active directly to avoid parent-chain binding failures
            Rectangle {
                id: lever
                width: 48; height: 30; radius: 3
                x: track.x - 13
                y: (leverTrack.height - height) * (1 - vthrottle.value / 100)
                color: "#374151"; border.color: "#4b5563"; border.width: 2
                Behavior on y { enabled: vthrottle.active; NumberAnimation { duration: 300 } }
                Rectangle { anchors.centerIn: parent; width: 30; height: 5; radius: 2; color: vthrottle.active ? "#22c55e" : "#9ca3af" }
            }
            MouseArea {
                anchors.fill: parent
                enabled: !vthrottle.active
                onPositionChanged: if (pressed) vthrottle.moved(Math.max(0, Math.min(100, (1 - (mouseY - 15) / (height - 30)) * 100)))
                onPressed: vthrottle.moved(Math.max(0, Math.min(100, (1 - (mouseY - 15) / (height - 30)) * 100)))
            }
        }
    }

    Column {
        anchors.fill: parent; anchors.margins: 12; spacing: 14

        // header + Split / A-THR
        Row {
            width: parent.width
            Text { text: "Throttle Quadrant"; color: Theme.white; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
            Item { width: parent.width - 240; height: 1 }
            Row {
                spacing: 6
                Rectangle {
                    width: 64; height: 26; radius: 4; color: root.throttleLock ? "#1d4ed8" : Theme.cockpitBezel; border.color: "#4b5563"
                    Text { anchors.centerIn: parent; text: root.throttleLock ? "Linked" : "Split"; color: Theme.white; font.pixelSize: 10 }
                    MouseArea { anchors.fill: parent; onClicked: { root.throttleLock = !root.throttleLock; if (root.throttleLock) root.eng2 = root.eng1 } }
                }
                Rectangle {
                    width: 64; height: 26; radius: 4; color: root.athr ? "#15803d" : Theme.cockpitBezel; border.color: "#4b5563"
                    Text { anchors.centerIn: parent; text: "A/THR"; color: Theme.white; font.pixelSize: 10 }
                    MouseArea { anchors.fill: parent; onClicked: if (root.adc) root.adc.athrActive = !root.adc.athrActive }
                }
            }
        }

        // two throttle levers
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 24
            Column {
                spacing: 4
                VThrottle {
                    eng: "ENG 1"; value: root.eng1; active: root.athr
                    onMoved: {
                        root.eng1 = v
                        if (root.adc) root.adc.tla1 = root.pctToTla(v)
                        if (root.throttleLock) {
                            root.eng2 = v
                            if (root.adc) root.adc.tla2 = root.pctToTla(v)
                        }
                    }
                }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "N1: " + (root.adc ? root.adc.n1Left.toFixed(0) : root.n1(root.eng1)) + "%"; color: Theme.cyan; font.pixelSize: 10 }
            }
            Column {
                spacing: 4
                VThrottle {
                    eng: "ENG 2"; value: root.eng2; active: root.athr || root.throttleLock
                    onMoved: { root.eng2 = v; if (root.adc) root.adc.tla2 = root.pctToTla(v) }
                }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "N1: " + (root.adc ? root.adc.n1Right.toFixed(0) : root.n1(root.eng2)) + "%"; color: Theme.cyan; font.pixelSize: 10 }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#374151" }

        // FLAPS + SPEED BRAKE
        Row {
            width: parent.width
            Column {
                width: parent.width / 2; spacing: 6
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "FLAPS"; color: Theme.white; font.pixelSize: 11 }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
                    Rectangle { width: 30; height: 28; radius: 3; color: Theme.cockpitBezel; border.color: "#4b5563"
                        Text { anchors.centerIn: parent; text: "▲"; color: Theme.white; font.pixelSize: 10 }
                        MouseArea { anchors.fill: parent; onClicked: { root.flaps = Math.max(0, root.flaps - 1); if (root.adc) root.adc.flapHandleIndex = root.flaps } } }
                    Rectangle { width: 56; height: 28; color: "#000000"; border.color: "#4b5563"
                        Text { anchors.centerIn: parent; text: root.flapsNames[root.flaps]; color: Theme.green; font.pixelSize: 13; font.family: "monospace" } }
                    Rectangle { width: 30; height: 28; radius: 3; color: Theme.cockpitBezel; border.color: "#4b5563"
                        Text { anchors.centerIn: parent; text: "▼"; color: Theme.white; font.pixelSize: 10 }
                        MouseArea { anchors.fill: parent; onClicked: { root.flaps = Math.min(4, root.flaps + 1); if (root.adc) root.adc.flapHandleIndex = root.flaps } } }
                }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "CONFIG " + root.flaps; color: Theme.cyan; font.pixelSize: 9 }
            }
            Column {
                width: parent.width / 2; spacing: 6
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "SPEED BRAKE"; color: Theme.white; font.pixelSize: 11 }
                Rectangle {
                    width: parent.width - 24; height: 8; radius: 4; anchors.horizontalCenter: parent.horizontalCenter; color: "#1f2937"; clip: true
                    Rectangle { width: parent.width * root.speedBrake / 100; height: parent.height; color: Theme.cyan }
                    MouseArea {
                        anchors.fill: parent
                        function setFromMouse() {
                            root.speedBrake = Math.max(0, Math.min(100, mouseX / width * 100))
                            if (root.adc) root.adc.speedbrakeLever = root.speedBrake / 100.0
                        }
                        onPressed: setFromMouse()
                        onPositionChanged: if (pressed) setFromMouse()
                    }
                }
                Text { anchors.horizontalCenter: parent.horizontalCenter
                    text: root.speedBrake === 0 ? "RETRACTED" : root.speedBrake < 50 ? "PARTIAL" : root.speedBrake < 100 ? "DEPLOYED" : "FULL"
                    color: Theme.cyan; font.pixelSize: 9 }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 70; height: 22; radius: 4
                    color: (root.adc && root.adc.speedbrakeArmed) ? "#b45309" : Theme.cockpitBezel
                    border.color: "#4b5563"
                    Text { anchors.centerIn: parent; text: "ARM"; color: Theme.white; font.pixelSize: 9; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: if (root.adc) root.adc.speedbrakeArmed = !root.adc.speedbrakeArmed }
                }
            }
        }
    }
}
