import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ExamCenter — timed proficiency exam with scenario prompts and scoring
Rectangle {
    id: root
    property var adc
    property var fmsComputer
    color: "#0d1017"
    radius: 6
    border.color: "#2a2d35"

    property int  timeLeft:   300   // seconds
    property bool examActive: false
    property int  score:      0
    property int  maxScore:   100
    property string currentTask: "Program flight EDDF→LFPG in the MCDU INIT page"
    property int  taskIndex:  0

    property var tasks: [
        "Set FROM/TO as EDDF/LFPG in MCDU INIT page",
        "Enter cost index 35 in MCDU INIT page",
        "Set cruise altitude FL320 in MCDU INIT page",
        "Enter V1=140, VR=145, V2=150 in PERF page",
        "Verify waypoints in F-PLN page",
    ]

    Timer {
        id: countdownTimer
        interval: 1000; repeat: true; running: root.examActive
        onTriggered: {
            if (root.timeLeft > 0) {
                root.timeLeft--
            } else {
                root.examActive = false
                resultDialog.open()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 20; spacing: 14

        // Header
        RowLayout {
            Label { text: "🎓  PROFICIENCY EXAM CENTER"; color: "#4fc3f7"; font.pixelSize: 15; font.bold: true; font.family: "Consolas" }
            Item { Layout.fillWidth: true }
            // Timer
            Rectangle {
                visible: root.examActive; width: 110; height: 36; radius: 6
                color: root.timeLeft < 60 ? Qt.rgba(1,0,0,0.2) : "#1a1d24"
                border.color: root.timeLeft < 60 ? "#ff5252" : "#37474f"
                Behavior on color { ColorAnimation { duration: 300 } }
                Text {
                    anchors.centerIn: parent
                    text: {
                        var m = Math.floor(root.timeLeft / 60)
                        var s = root.timeLeft % 60
                        return "⏱ " + m.toString().padStart(2,'0') + ":" + s.toString().padStart(2,'0')
                    }
                    color: root.timeLeft < 60 ? "#ff5252" : "#00e5ff"
                    font.pixelSize: 15; font.bold: true; font.family: "Consolas"
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#2a2d35" }

        // Available exams
        Label { text: "SELECT EXAM"; color: "#78909c"; font.pixelSize: 10; font.family: "Consolas"; font.bold: true; visible: !root.examActive }

        GridLayout {
            columns: 3; rowSpacing: 8; columnSpacing: 8; Layout.fillWidth: true; visible: !root.examActive

            Repeater {
                model: [
                    { title: "INIT PROGRAMMING", desc: "MCDU initialization sequence", difficulty: "★★☆", time: 300 },
                    { title: "NORMAL PROCEDURES", desc: "Before-start & takeoff checklist", difficulty: "★★★", time: 600 },
                    { title: "EMERGENCY PROC",   desc: "Engine fire response", difficulty: "★★★", time: 480 },
                    { title: "APPROACH BRIEF",   desc: "ILS approach setup & FMA monitoring", difficulty: "★★☆", time: 360 },
                    { title: "FMS DATA ENTRY",   desc: "Complete FMS programming EDDF→LFPG", difficulty: "★☆☆", time: 240 },
                    { title: "SYSTEM KNOWLEDGE", desc: "Hydraulic, Electrical & Fuel quiz", difficulty: "★★☆", time: 420 },
                ]
                Rectangle {
                    Layout.fillWidth: true; height: 80; radius: 6
                    color: examCardBtn.containsMouse ? "#1a2030" : "#12141a"
                    border.color: examCardBtn.containsMouse ? "#00d4ff" : "#2a2d35"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 8; spacing: 3
                        Text { text: modelData.title; color: "#e0e0e0"; font.pixelSize: 11; font.bold: true; font.family: "Consolas" }
                        Text { text: modelData.desc;  color: "#546e7a"; font.pixelSize: 9;  font.family: "Consolas"; wrapMode: Text.Wrap; Layout.fillWidth: true }
                        RowLayout {
                            Text { text: modelData.difficulty; color: "#ffd54f"; font.pixelSize: 10 }
                            Item { Layout.fillWidth: true }
                            Text { text: (modelData.time / 60).toFixed(0) + " min"; color: "#546e7a"; font.pixelSize: 9; font.family: "Consolas" }
                        }
                    }
                    MouseArea {
                        id: examCardBtn
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            root.timeLeft   = modelData.time
                            root.taskIndex  = 0
                            root.currentTask = root.tasks[0]
                            root.score      = 0
                            root.examActive = true
                        }
                    }
                }
            }
        }

        // Active exam view
        ColumnLayout {
            visible: root.examActive; Layout.fillWidth: true; spacing: 10

            Rectangle {
                Layout.fillWidth: true; height: 80; radius: 6
                color: "#1a2030"; border.color: "#00d4ff"

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 12; spacing: 4
                    Label { text: "CURRENT TASK  " + (root.taskIndex + 1) + "/" + root.tasks.length
                            color: "#78909c"; font.pixelSize: 9; font.family: "Consolas" }
                    Label {
                        text: root.currentTask
                        color: "#e0e0e0"; font.pixelSize: 13; font.bold: true; font.family: "Consolas"
                        wrapMode: Text.Wrap; Layout.fillWidth: true
                    }
                }
            }

            // Progress bar
            Rectangle {
                Layout.fillWidth: true; height: 8; radius: 4; color: "#1a1d24"
                Rectangle {
                    width: parent.width * (root.taskIndex / root.tasks.length)
                    height: 8; radius: 4; color: "#00e676"
                    Behavior on width { NumberAnimation { duration: 300 } }
                }
            }
            Label { text: "Score: " + root.score + "/" + root.maxScore; color: "#00e676"; font.pixelSize: 11; font.family: "Consolas" }

            RowLayout {
                spacing: 10
                Button {
                    text: "✓ TASK COMPLETE"; Layout.preferredWidth: 160; height: 36
                    background: Rectangle { radius: 6; color: "#1a2a1a"; border.color: "#00e676" }
                    contentItem: Text { text: parent.text; color: "#00e676"; font.pixelSize: 10; font.family: "Consolas"; horizontalAlignment: Text.AlignHCenter }
                    onClicked: {
                        root.score += 20
                        root.taskIndex = Math.min(root.taskIndex + 1, root.tasks.length - 1)
                        root.currentTask = root.tasks[root.taskIndex]
                        if (root.taskIndex >= root.tasks.length - 1 && root.score >= root.maxScore) {
                            root.examActive = false; resultDialog.open()
                        }
                    }
                }
                Button {
                    text: "✕ ABORT"; height: 36
                    background: Rectangle { radius: 6; color: "#2a1010"; border.color: "#ff5252" }
                    contentItem: Text { text: parent.text; color: "#ff5252"; font.pixelSize: 10; font.family: "Consolas"; horizontalAlignment: Text.AlignHCenter }
                    onClicked: { root.examActive = false }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    // Result dialog
    Dialog {
        id: resultDialog
        anchors.centerIn: parent
        width: 320; height: 200
        modal: true

        background: Rectangle { color: "#12141a"; radius: 8; border.color: "#2a2d35" }

        ColumnLayout {
            anchors.centerIn: parent; spacing: 12
            Text {
                text: root.score >= 80 ? "✅  PASS" : "❌  FAIL"
                color: root.score >= 80 ? "#00e676" : "#ff5252"
                font.pixelSize: 24; font.bold: true; font.family: "Consolas"
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: "Score: " + root.score + " / " + root.maxScore
                color: "#e0e0e0"; font.pixelSize: 14; font.family: "Consolas"
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: root.score >= 80 ? "Proficiency standard met" : "Review procedures and retry"
                color: "#78909c"; font.pixelSize: 10; font.family: "Consolas"
                Layout.alignment: Qt.AlignHCenter
            }
            Button {
                text: "CLOSE"; Layout.alignment: Qt.AlignHCenter
                background: Rectangle { radius: 4; color: "#1a1d24"; border.color: "#37474f" }
                contentItem: Text { text: parent.text; color: "#b0bec5"; font.pixelSize: 10; font.family: "Consolas"; horizontalAlignment: Text.AlignHCenter }
                onClicked: resultDialog.close()
            }
        }
    }
}
