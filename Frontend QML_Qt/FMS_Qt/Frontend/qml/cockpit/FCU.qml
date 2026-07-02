import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// FCU — Flight Control Unit. 1:1 port of React controls/FCU.tsx (5-column panel).
Rectangle {
    id: root
    property var adc
    color: "#1c1c1c"
    radius: 12
    border.color: "#2a2a2a"; border.width: 6
    property int altInc: 100

    // ── reusable: digital display window ──────────────────────────────────────
    component FcuDisplay : Column {
        property string text1: ""
        property var    labels: []
        property bool   managed: false
        property string unit: ""
        spacing: 4
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 10
            Repeater { model: parent.parent.labels
                Text { text: modelData; color: Qt.rgba(1,1,1,0.4); font.family: Theme.fontFcu; font.pixelSize: 9; font.bold: true; font.letterSpacing: 2 } }
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 96; height: 40; radius: 4; color: "#000000"
            border.color: Qt.rgba(Theme.fcuButton.r, Theme.fcuButton.g, Theme.fcuButton.b, 0.4); border.width: 2
            Row {
                anchors.centerIn: parent; spacing: 2
                Text {
                    text: parent.parent.parent.managed ? "---" : parent.parent.parent.text1
                    color: parent.parent.parent.managed ? Theme.cyan : Theme.fcuText
                    font.family: Theme.fontFcu; font.pixelSize: 22; font.letterSpacing: 2
                }
                Text { visible: parent.parent.parent.unit !== ""; text: parent.parent.parent.unit; color: parent.parent.parent.managed ? Theme.cyan : Theme.fcuText; font.pixelSize: 9; anchors.bottom: parent.bottom; anchors.bottomMargin: 4; opacity: 0.6 }
            }
            Rectangle { visible: parent.parent.managed; anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: Theme.cyan }
        }
    }

    // ── reusable: knob with -/+ and push/pull ─────────────────────────────────
    component FcuKnob : Column {
        id: knob
        property string text1: ""
        property var    labels: []
        property bool   managed: false
        property bool   hasPushPull: true
        signal inc(); signal dec(); signal push(); signal pull()
        spacing: 6
        FcuDisplay { text1: knob.text1; labels: knob.labels; managed: knob.managed }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
            Rectangle { width: 26; height: 26; radius: 13; color: dn.pressed ? "#0f0f0f" : "#1a1a1a"; border.color: "#333"
                Text { anchors.centerIn: parent; text: "−"; color: "#9ca3af"; font.pixelSize: 16 }
                MouseArea { id: dn; anchors.fill: parent; onClicked: knob.dec() } }
            Column {
                spacing: 2
                Text { anchors.horizontalCenter: parent.horizontalCenter; visible: knob.hasPushPull; text: "PUSH"; color: Theme.cyan; font.pixelSize: 6; font.bold: true
                    MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: knob.push() } }
                Rectangle {
                    width: 48; height: 48; radius: 24
                    anchors.horizontalCenter: parent.horizontalCenter
                    gradient: Gradient { GradientStop { position: 0; color: "#374151" } GradientStop { position: 1; color: "#111827" } }
                    border.width: 3; border.color: knob.managed ? Theme.cyan : "#4b5563"
                    Rectangle { anchors.centerIn: parent; width: 18; height: 18; radius: 9; color: knob.managed ? Theme.cyan : "#6b7280" }
                }
                Text { anchors.horizontalCenter: parent.horizontalCenter; visible: knob.hasPushPull; text: "PULL"; color: Theme.amber; font.pixelSize: 6; font.bold: true
                    MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: knob.pull() } }
            }
            Rectangle { width: 26; height: 26; radius: 13; color: up.pressed ? "#0f0f0f" : "#1a1a1a"; border.color: "#333"
                Text { anchors.centerIn: parent; text: "+"; color: "#9ca3af"; font.pixelSize: 14 }
                MouseArea { id: up; anchors.fill: parent; onClicked: knob.inc() } }
        }
    }

    // ── reusable: mode button (LED + label) ───────────────────────────────────
    component FcuModeButton : Rectangle {
        id: mbtn
        property string label: ""
        property bool   active: false
        signal clicked()
        implicitWidth: 64; implicitHeight: 44; radius: 6
        color: active ? "#222222" : (mma.containsMouse ? "#1c1c1c" : "#1a1a1a")
        border.width: 2; border.color: active ? Theme.green : Qt.rgba(0.4,0.4,0.4,0.5)
        Column {
            anchors.centerIn: parent; spacing: 4
            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 24; height: 6; radius: 2; color: mbtn.active ? Theme.green : "#111827" }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: mbtn.label; color: Qt.rgba(1,1,1, mbtn.active ? 0.95 : 0.4); font.family: Theme.fontFcu; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1 }
        }
        MouseArea { id: mma; anchors.fill: parent; hoverEnabled: true; onClicked: mbtn.clicked() }
    }

    // decorative corner screws
    Repeater { model: [[0,0],[1,0],[0,1],[1,1]]
        Rectangle { width: 6; height: 6; radius: 3; color: "#1f2937"; border.color: "#000"
            x: modelData[0] === 1 ? root.width - 16 : 10; y: modelData[1] === 1 ? root.height - 16 : 10 } }

    // ── 5-column grid ─────────────────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent; anchors.margins: 18; spacing: 0

        // SPD
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            FcuKnob {
                Layout.alignment: Qt.AlignHCenter
                labels: ["SPD", "MACH"]; text1: root.adc ? Math.round(root.adc.selectedSpeed).toString() : "---"
                managed: root.adc ? root.adc.speedMode === "MANAGED" : false
                onInc: if (root.adc) root.adc.selectedSpeed = Math.min(400, root.adc.selectedSpeed + 1)
                onDec: if (root.adc) root.adc.selectedSpeed = Math.max(100, root.adc.selectedSpeed - 1)
                onPush: if (root.adc) root.adc.pushSpeed()
                onPull: if (root.adc) root.adc.pullSpeed()
            }
            Item { Layout.fillHeight: true }
        }
        Rectangle { Layout.fillHeight: true; width: 1; color: Qt.rgba(1,1,1,0.05) }

        // HDG
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            FcuKnob {
                Layout.alignment: Qt.AlignHCenter
                labels: ["HDG", "TRK"]; text1: root.adc ? (("00" + Math.round(root.adc.selectedHeading)).slice(-3)) : "---"
                managed: root.adc ? root.adc.headingMode === "MANAGED" : false
                onInc: if (root.adc) root.adc.selectedHeading = (root.adc.selectedHeading + 1) % 360
                onDec: if (root.adc) root.adc.selectedHeading = (root.adc.selectedHeading + 359) % 360
                onPush: if (root.adc) root.adc.pushHeading()
                onPull: if (root.adc) root.adc.pullHeading()
            }
            FcuModeButton { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 8; label: "LOC"; active: false }
        }
        Rectangle { Layout.fillHeight: true; width: 1; color: Qt.rgba(1,1,1,0.05) }

        // CENTER: AP / A-THR
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 10
            Item { Layout.fillHeight: true }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter; spacing: 8
                FcuModeButton { label: "AP 1"; active: root.adc ? root.adc.ap1Active : false; onClicked: if (root.adc) root.adc.ap1Active = !root.adc.ap1Active }
                FcuModeButton { label: "AP 2"; active: root.adc ? root.adc.ap2Active : false; onClicked: if (root.adc) root.adc.ap2Active = !root.adc.ap2Active }
            }
            FcuModeButton { Layout.alignment: Qt.AlignHCenter; implicitWidth: 96; label: "A/THR"; active: root.adc ? root.adc.athrActive : false; onClicked: if (root.adc) root.adc.athrActive = !root.adc.athrActive }
            Text { Layout.alignment: Qt.AlignHCenter; text: "FLIGHT CONTROL UNIT"; color: Qt.rgba(1,1,1,0.12); font.family: Theme.fontFcu; font.pixelSize: 9; font.letterSpacing: 3; font.bold: true }
            Item { Layout.fillHeight: true }
        }
        Rectangle { Layout.fillHeight: true; width: 1; color: Qt.rgba(1,1,1,0.05) }

        // ALT
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            FcuKnob {
                Layout.alignment: Qt.AlignHCenter
                labels: ["ALT", "LVL/CH"]; text1: root.adc ? Math.round(root.adc.selectedAltitude).toString() : "-----"
                managed: root.adc ? root.adc.altitudeMode === "MANAGED" : false
                onInc: if (root.adc) root.adc.selectedAltitude = root.adc.selectedAltitude + root.altInc
                onDec: if (root.adc) root.adc.selectedAltitude = Math.max(0, root.adc.selectedAltitude - root.altInc)
                onPush: if (root.adc) root.adc.pushAltitude()
                onPull: if (root.adc) root.adc.pullAltitude()
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 8; spacing: 6
                Text { text: "100"; color: root.altInc === 100 ? Theme.cyan : "#6b7280"; font.family: Theme.fontFcu; font.pixelSize: 9; font.bold: true }
                Rectangle {
                    width: 40; height: 20; radius: 10; color: "#111"; border.color: Qt.rgba(1,1,1,0.1)
                    Rectangle { width: 16; height: 16; radius: 8; y: 2; x: root.altInc === 1000 ? 22 : 2; color: "#9ca3af"; Behavior on x { NumberAnimation { duration: 150 } } }
                    MouseArea { anchors.fill: parent; onClicked: root.altInc = (root.altInc === 100 ? 1000 : 100) }
                }
                Text { text: "1000"; color: root.altInc === 1000 ? Theme.cyan : "#6b7280"; font.family: Theme.fontFcu; font.pixelSize: 9; font.bold: true }
            }
        }
        Rectangle { Layout.fillHeight: true; width: 1; color: Qt.rgba(1,1,1,0.05) }

        // V/S
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            FcuKnob {
                Layout.alignment: Qt.AlignHCenter; hasPushPull: false
                labels: ["V/S", "FPA"]
                text1: root.adc ? (root.adc.selectedVS >= 0 ? "+" + Math.round(root.adc.selectedVS) : Math.round(root.adc.selectedVS).toString()) : "0"
                managed: root.adc ? root.adc.selectedVS === 0 : true
                onInc: if (root.adc) root.adc.selectedVS = Math.min(6000, root.adc.selectedVS + 100)
                onDec: if (root.adc) root.adc.selectedVS = Math.max(-6000, root.adc.selectedVS - 100)
            }
            FcuModeButton { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 8; label: "APPR"; active: false }
        }
    }
}
