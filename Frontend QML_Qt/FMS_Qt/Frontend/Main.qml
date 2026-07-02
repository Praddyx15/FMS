import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

ApplicationWindow {
    id: root
    width: 1600
    height: 900
    minimumWidth: 1200
    minimumHeight: 700
    visible: true
    title: "A320neo FMS Trainer"

    // ── Global colour palette (delegated to Theme → exact React tokens) ───────
    readonly property color bgDark:   Theme.cockpitBackground // #0a0a0a
    readonly property color bgPanel:  Theme.cockpitPanel      // #0f0f0f
    readonly property color bgCard:   Theme.cockpitBezel      // #262626 (≈ dark --secondary)
    readonly property color accent:   Theme.cockpitPrimary    // #1e90ff (dark --accent)
    readonly property color green:    Theme.green             // #22c55e
    readonly property color amber:    Theme.amber             // #f59e0b
    readonly property color red:      Theme.red               // #ef4444
    readonly property color cyan:     Theme.cyan              // #00bfff
    readonly property color magenta:  Theme.magenta           // #ff66ff
    readonly property color white:    Theme.white             // #f2f2f2
    readonly property color dimWhite: Theme.mutedFg           // #a6a6a6

    background: Rectangle { color: root.bgDark }

    // ── Simulation singletons ────────────────────────────────────────────────
    // NOTE: these are plain QObjects with no default property, so Connections
    // cannot be nested inside them — they live as siblings under the window.
    AirDataComputer  { id: adc }
    FMSComputer      { id: fmsComputer }
    InstructorEngine { id: instructor }

    // Failures from instructor engine → ADC
    Connections {
        target: instructor
        function onFailureInjected(id, active) { adc.applyFailure(id, active) }
    }
    // FMS outputs → ADC V-speeds
    Connections {
        target: fmsComputer
        function onRequestSetV1(v)  { adc.v1 = v }
        function onRequestSetVr(v)  { adc.vr = v }
        function onRequestSetV2(v)  { adc.v2 = v }
    }

    // ── Layout State ─────────────────────────────────────────────────────────
    property string layoutMode: "full"  // full | split | mcdu-focus | instruments | overhead | pedestal
    property bool setupComplete: false

    // ── Top menu bar ─────────────────────────────────────────────────────────
    header: ToolBar {
        visible: root.setupComplete
        height: visible ? 44 : 0
        background: Rectangle { color: root.bgPanel; border.width: 1; border.color: "#2a2d35" }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            // Logo / Title
            Label {
                text: "✈  A320neo FMS TRAINER"
                color: root.accent
                font.pixelSize: 14
                font.bold: true
                font.family: "Consolas"
            }

            Item { Layout.fillWidth: true }

            // View mode buttons
            Repeater {
                model: [
                    { label: "FULL",       mode: "full"        },
                    { label: "PFD/ND",     mode: "instruments" },
                    { label: "ENG/SYS",    mode: "ecam"        },
                    { label: "MCDU",       mode: "mcdu-focus"  },
                    { label: "SPLIT",      mode: "split"       },
                    { label: "OVERHEAD",   mode: "overhead"    },
                    { label: "PEDESTAL",   mode: "pedestal"    },
                    { label: "INSTRUCTOR", mode: "instructor"  },
                    { label: "EXAM",       mode: "exam"        },
                    { label: "SCENARIOS",  mode: "training"    },
                    { label: "ANALYTICS",  mode: "analytics"   },
                ]
                ToolButton {
                    text: modelData.label
                    font.pixelSize: 10
                    font.bold: root.layoutMode === modelData.mode
                    contentItem: Label {
                        text: parent.text
                        color: root.layoutMode === modelData.mode ? root.accent : root.dimWhite
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                    }
                    background: Rectangle {
                        color: root.layoutMode === modelData.mode
                               ? Qt.rgba(0, 0.82, 1.0, 0.12)
                               : "transparent"
                        radius: 4
                        border.color: root.layoutMode === modelData.mode
                                      ? root.accent
                                      : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    onClicked: root.layoutMode = modelData.mode
                }
            }

            Item { width: 8 }

            // Flight info strip
            Label {
                text: FlightDataManager.departure + "→" + FlightDataManager.destination
                      + "  FL" + Math.round(FlightDataManager.cruiseAltitude / 100)
                      + "  " + FlightDataManager.flightNumber
                color: root.dimWhite
                font.pixelSize: 10
                font.family: "Consolas"
            }

            // Clock
            Label {
                id: clockLabel
                color: root.dimWhite
                font.pixelSize: 10
                font.family: "Consolas"
                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clockLabel.text = Qt.formatTime(new Date(), "hh:mm:ss") + "Z"
                }
                Component.onCompleted: text = Qt.formatTime(new Date(), "hh:mm:ss") + "Z"
            }
        }
    }

    // ── Main content via Loader-based layout ─────────────────────────────────
    Loader {
        id: mainLoader
        anchors.fill: parent
        sourceComponent: root.setupComplete ? mainLayoutComponent : preFlightSetupComponent
    }

    Component {
        id: preFlightSetupComponent
        PreFlightSetup {
            onFlightInitialized: {
                root.setupComplete = true
            }
        }
    }

    Component {
        id: mainLayoutComponent
        MainLayout {
            layoutMode:   root.layoutMode
            adc:          adc
            fmsComputer:  fmsComputer
            instructor:   instructor
        }
    }
}
