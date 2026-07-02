import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// MainLayout — routes the layoutMode string to the correct view composition.
// Uses a Loader (not StackLayout) so only the ACTIVE view is instantiated —
// matches React's one-route-at-a-time behaviour and avoids building every view
// (incl. the Qt Charts analytics view) at startup.
Item {
    id: root

    property string layoutMode: "full"
    property var    adc
    property var    fmsComputer
    property var    instructor

    Loader {
        anchors.fill: parent
        sourceComponent: {
            switch (root.layoutMode) {
            case "instruments": return cInstruments
            case "ecam":        return cEcam
            case "mcdu-focus":  return cMcduFocus
            case "split":       return cSplit
            case "overhead":    return cOverhead
            case "pedestal":    return cPedestal
            case "instructor":  return cInstructor
            case "exam":        return cExam
            case "analytics":   return cAnalytics
            case "training":    return cTraining
            default:            return cFull
            }
        }
    }

    // 0 — Full cockpit — EXACT port of React FMSTrainer.tsx <main>:
    //   LEFT sidebar 280px (Yoke + Rudder) | CENTRE (FCU on top, PFD|ND side-by-side)
    //   | RIGHT sidebar 410px (MCDU + EFIS + Throttle, scrollable)
    Component {
        id: cFull
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8       // px-2 py-2
            spacing: 8               // gap-2

            // ── LEFT SIDEBAR (w-[280px]) ──────────────────────────────────────
            Rectangle {
                Layout.preferredWidth: 280
                Layout.fillHeight: true
                color: Qt.rgba(0, 0, 0, 0.6)               // bg-black/60
                radius: 8
                border.color: Theme.cockpitBorder
                clip: true
                Flickable {
                    id: leftFlk
                    anchors.fill: parent; anchors.margins: 12
                    contentWidth: width; contentHeight: leftCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds; clip: true
                    ColumnLayout {
                        id: leftCol
                        width: parent.width; spacing: 16   // p-3 space-y-4
                        Yoke         { Layout.fillWidth: true; adc: root.adc }
                        RudderPedals { Layout.fillWidth: true; adc: root.adc }
                    }
                    WheelHandler {
                        acceptedModifiers: Qt.NoModifier
                        onWheel: (e) => { leftFlk.contentY = Math.max(0, Math.min(Math.max(0, leftFlk.contentHeight - leftFlk.height), leftFlk.contentY - e.angleDelta.y)) }
                    }
                }
            }

            // ── CENTRE: FCU on top, PFD | ND below ────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                FCU { Layout.fillWidth: true; Layout.preferredHeight: 255; adc: root.adc }   // min-h-[255px]
                RowLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true; spacing: 8
                    DisplayBezel { label: "PFD"; labelColor: Theme.cyan
                        PFD { anchors.fill: parent; anchors.margins: 8; adc: root.adc } }
                    DisplayBezel { label: "ND"; labelColor: Theme.green
                        ND { anchors.fill: parent; anchors.margins: 8; adc: root.adc } }
                }
            }

            // ── RIGHT SIDEBAR (w-[410px]) ─────────────────────────────────────
            Rectangle {
                Layout.preferredWidth: 410
                Layout.fillHeight: true
                color: Qt.rgba(0, 0, 0, 0.6)
                radius: 8
                border.color: Theme.cockpitBorder
                clip: true
                Flickable {
                    id: rightFlk
                    anchors.fill: parent; anchors.margins: 12
                    contentWidth: width; contentHeight: rightCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds; clip: true
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOn }
                    ColumnLayout {
                        id: rightCol
                        width: parent.width; spacing: 12
                        MCDU { Layout.fillWidth: true; Layout.preferredHeight: 660; fmsComputer: root.fmsComputer; adc: root.adc }
                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.cockpitBorder }
                        EFISControl { Layout.fillWidth: true; Layout.preferredHeight: 380 }
                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.cockpitBorder }
                        ThrottleQuadrant { Layout.fillWidth: true; Layout.preferredHeight: 470; adc: root.adc }
                    }
                    WheelHandler {
                        acceptedModifiers: Qt.NoModifier
                        onWheel: (e) => { rightFlk.contentY = Math.max(0, Math.min(Math.max(0, rightFlk.contentHeight - rightFlk.height), rightFlk.contentY - e.angleDelta.y)) }
                    }
                }
            }
        }
    }

    // Reusable display bezel (black rounded border-2 box with a corner label badge)
    component DisplayBezel : Rectangle {
        property string label: ""
        property color  labelColor: Theme.cyan
        default property alias content: holder.data
        Layout.fillWidth: true; Layout.fillHeight: true
        color: "#000000"; radius: 8; border.color: Theme.cockpitBorder; border.width: 2; clip: true
        Item { id: holder; anchors.fill: parent }
        Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 8
            width: badge.implicitWidth + 10; height: badge.implicitHeight + 4; radius: 3
            color: Qt.rgba(0, 0, 0, 0.8); border.color: Qt.rgba(labelColor.r, labelColor.g, labelColor.b, 0.4); z: 10
            Text { id: badge; anchors.centerIn: parent; text: label; color: labelColor
                   font.pixelSize: 10; font.family: "monospace"; font.letterSpacing: 2 }
        }
    }

    // 1 — Instruments (PFD / ND, large)
    Component {
        id: cInstruments
        RowLayout {
            anchors.fill: parent; anchors.margins: 6; spacing: 6
            PFD { Layout.fillWidth: true; Layout.fillHeight: true; adc: root.adc }
            ND  { Layout.fillWidth: true; Layout.fillHeight: true; adc: root.adc }
        }
    }

    // ECAM — wide, centred (like the React modal) so the two columns have room
    Component {
        id: cEcam
        Item {
            ECAM {
                anchors.centerIn: parent
                width: Math.min(parent.width - 24, 1000)
                height: parent.height - 24
                adc: root.adc
            }
        }
    }

    // 2 — MCDU focus
    Component {
        id: cMcduFocus
        Item {
            MCDU {
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.55, 560)
                height: parent.height - 20
                fmsComputer: root.fmsComputer
                adc: root.adc
            }
        }
    }

    // 3 — Split view
    Component {
        id: cSplit
        CockpitSplitView { anchors.fill: parent; adc: root.adc; fmsComputer: root.fmsComputer }
    }

    // 4 — Overhead
    Component {
        id: cOverhead
        Item { OverheadPanel { anchors.fill: parent; anchors.margins: 10 } }
    }

    // 5 — Pedestal
    Component {
        id: cPedestal
        Item { Pedestal { anchors.fill: parent; anchors.margins: 10; adc: root.adc } }
    }

    // 6 — Instructor Station
    Component {
        id: cInstructor
        RowLayout {
            anchors.fill: parent; anchors.margins: 6; spacing: 6
            InstructorStation { Layout.fillWidth: true; Layout.fillHeight: true; instructor: root.instructor; adc: root.adc }
            FailureInjection  { Layout.preferredWidth: root.width * 0.45; Layout.fillHeight: true; instructor: root.instructor }
        }
    }

    // 7 — Exam Center
    Component {
        id: cExam
        ExamCenter { anchors.fill: parent; adc: root.adc; fmsComputer: root.fmsComputer }
    }

    // 8 — Analytics
    Component {
        id: cAnalytics
        Analytics { anchors.fill: parent; adc: root.adc }
    }

    // 9 — Training Scenarios
    Component {
        id: cTraining
        TrainingScenarios { anchors.fill: parent; adc: root.adc; instructor: root.instructor }
    }
}
