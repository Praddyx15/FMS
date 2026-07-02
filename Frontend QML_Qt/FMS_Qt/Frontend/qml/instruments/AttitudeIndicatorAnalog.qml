import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0

/* AttitudeIndicatorAnalog — 1:1 port of React instruments/AttitudeIndicatorAnalog.tsx */
Item {
    id: root
    property real pitch: 0
    property real roll: 0
    property real displayPitch: pitch
    property real displayRoll: roll

    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: {
            root.displayPitch += (root.pitch - root.displayPitch) * 0.2;
            root.displayRoll += (root.roll - root.displayRoll) * 0.2;
        }
    }

    readonly property real clampedPitch: Math.max(-30, Math.min(30, displayPitch))
    // 30° maps to ~30% of bezel height (React: 60px on its instrument)
    readonly property real pitchScale: bezel.height * 0.30
    readonly property real pitchPx: (clampedPitch / 30) * pitchScale

    Rectangle {
        id: bezel
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height); height: width
        radius: width / 2
        color: "#111827"             // bg-gray-900
        border.color: "#374151"; border.width: 4
        clip: true

        // ── Rotating sphere ───────────────────────────────────────────────────
        Item {
            id: sphere
            anchors.centerIn: parent
            width: parent.width * 2; height: parent.height * 2
            rotation: root.displayRoll
            transformOrigin: Item.Center

            Item {
                anchors.fill: parent
                transform: Translate { y: root.pitchPx }

                // Sky (top half)
                Rectangle {
                    x: 0; y: 0; width: parent.width; height: parent.height / 2
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#38bdf8" } // sky-400
                        GradientStop { position: 1.0; color: "#0284c7" } // sky-600
                    }
                }
                // Ground (bottom half)
                Rectangle {
                    x: 0; y: parent.height / 2; width: parent.width; height: parent.height / 2
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#92400e" } // amber-800
                        GradientStop { position: 1.0; color: "#451a03" } // amber-950
                    }
                }
                // Horizon line
                Rectangle { x: 0; y: parent.height / 2 - 1; width: parent.width; height: 2; color: "white" }

                // Pitch ladder
                Repeater {
                    model: [-30, -20, -10, 10, 20, 30]
                    Row {
                        property int angle: modelData
                        spacing: 8
                        x: sphere.width / 2 - implicitWidth / 2
                        y: sphere.height / 2 - (angle / 30) * root.pitchScale - height / 2
                        Rectangle { width: angle > 0 ? 32 : 48; height: 2; color: "white"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: Math.abs(angle); color: "white"; font.pixelSize: 12; font.bold: true; font.family: "monospace" }
                        Rectangle { width: angle > 0 ? 32 : 48; height: 2; color: "white"; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }

        // ── Fixed overlay: aircraft symbol + bank scale ───────────────────────
        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d"); ctx.reset();
                var s = width / 200; ctx.scale(s, s);
                // aircraft symbol (yellow)
                ctx.strokeStyle = "yellow"; ctx.fillStyle = "yellow";
                ctx.lineWidth = 3;
                ctx.beginPath(); ctx.moveTo(70, 100); ctx.lineTo(95, 100); ctx.stroke();
                ctx.beginPath(); ctx.moveTo(105, 100); ctx.lineTo(130, 100); ctx.stroke();
                ctx.lineWidth = 2;
                ctx.beginPath(); ctx.moveTo(95, 100); ctx.lineTo(105, 100); ctx.stroke();
                ctx.beginPath(); ctx.arc(100, 100, 3, 0, 2 * Math.PI); ctx.fill();
                // bank scale marks
                ctx.strokeStyle = "white"; ctx.lineWidth = 2;
                var marks = [10, 20, 30, 45, 60];
                for (var i = 0; i < marks.length; i++) {
                    [-marks[i], marks[i]].forEach(function (a) {
                        var inner = (a === 10 || a === 20 || a === 30 || a === -10 || a === -20 || a === -30) ? 20 : 15;
                        ctx.save(); ctx.translate(100, 100); ctx.rotate(a * Math.PI / 180); ctx.translate(-100, -100);
                        ctx.beginPath(); ctx.moveTo(100, 10); ctx.lineTo(100, inner); ctx.stroke();
                        ctx.restore();
                    });
                }
                // roll triangle (yellow, fixed at top)
                ctx.fillStyle = "yellow";
                ctx.beginPath(); ctx.moveTo(100, 5); ctx.lineTo(95, 15); ctx.lineTo(105, 15); ctx.closePath(); ctx.fill();
            }
        }

        // Label
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: bezel.width * 0.02
            color: Qt.rgba(0, 0, 0, 0.6); radius: 3
            width: atLabel.implicitWidth + 8; height: atLabel.implicitHeight + 4
            Text { id: atLabel; anchors.centerIn: parent; text: "ATTITUDE"; color: "white"; font.pixelSize: 12; font.bold: true; font.family: "monospace" }
        }
    }
}
