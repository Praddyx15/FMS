import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0

/* TurnCoordinator — 1:1 port of React instruments/TurnCoordinator.tsx */
Item {
    id: root
    property real roll: 0
    property real yaw: 0
    property real displayRoll: roll
    property real displayYaw: yaw

    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: {
            root.displayRoll += (root.roll - root.displayRoll) * 0.2;
            root.displayYaw += (root.yaw - root.displayYaw) * 0.2;
        }
    }
    onDisplayRollChanged: dial.requestPaint()
    onDisplayYawChanged: dial.requestPaint()

    Rectangle {
        id: bezel
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height); height: width
        radius: width / 2
        color: "#000000"
        border.color: "#374151"; border.width: 4

        Canvas {
            id: dial
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d"); ctx.reset();
                var s = width / 200; ctx.scale(s, s);

                function vline(x, y1, y2, lw) { ctx.strokeStyle = "white"; ctx.lineWidth = lw; ctx.beginPath(); ctx.moveTo(x, y1); ctx.lineTo(x, y2); ctx.stroke(); }
                // turn marks
                vline(30, 80, 95, 3); vline(50, 85, 95, 2); vline(100, 80, 95, 3); vline(150, 85, 95, 2); vline(170, 80, 95, 3);

                // aircraft symbol rotated by turnRate
                var turnRate = Math.max(-20, Math.min(20, root.displayRoll / 15 * 20));
                ctx.save(); ctx.translate(100, 100); ctx.rotate(turnRate * Math.PI / 180); ctx.translate(-100, -100);
                ctx.fillStyle = "white"; ctx.strokeStyle = "black"; ctx.lineWidth = 1;
                ctx.fillRect(95, 60, 10, 40); ctx.strokeRect(95, 60, 10, 40);   // fuselage
                ctx.fillRect(60, 78, 80, 8); ctx.strokeRect(60, 78, 80, 8);     // wings
                ctx.beginPath(); ctx.moveTo(100, 60); ctx.lineTo(95, 50); ctx.lineTo(105, 50); ctx.closePath(); ctx.fill(); ctx.stroke(); // tail
                ctx.restore();

                // slip/skid (translate 0,30)
                ctx.save(); ctx.translate(0, 30);
                ctx.strokeStyle = "white"; ctx.lineWidth = 2;
                ctx.beginPath(); ctx.ellipse(60, 105, 80, 30); ctx.stroke();      // tube rx40 ry15 centred (100,120)
                ctx.lineWidth = 1;
                ctx.beginPath(); ctx.moveTo(60, 120); ctx.lineTo(140, 120); ctx.stroke();
                ctx.beginPath(); ctx.moveTo(80, 115); ctx.lineTo(80, 125); ctx.stroke();
                ctx.beginPath(); ctx.moveTo(120, 115); ctx.lineTo(120, 125); ctx.stroke();
                var ball = Math.max(-20, Math.min(20, root.displayYaw * 2));
                ctx.beginPath(); ctx.arc(100 + ball, 120, 8, 0, 2 * Math.PI);
                ctx.fillStyle = "white"; ctx.fill(); ctx.strokeStyle = "black"; ctx.lineWidth = 2; ctx.stroke();
                ctx.restore();

                // labels
                ctx.fillStyle = "white"; ctx.font = "10px monospace"; ctx.textAlign = "center"; ctx.textBaseline = "alphabetic";
                ctx.fillText("L", 30, 105); ctx.fillText("R", 170, 105); ctx.fillText("2 MIN", 100, 165);
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: bezel.width * 0.02
            text: "TURN COORD"; color: "white"; font.pixelSize: 12; font.bold: true; font.family: "monospace"
        }
    }
}
