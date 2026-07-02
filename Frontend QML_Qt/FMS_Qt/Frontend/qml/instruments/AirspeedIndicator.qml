import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0

/* AirspeedIndicator — analog ASI. 1:1 port of React instruments/AirspeedIndicator.tsx */
Item {
    id: root
    property real airspeed: 0
    property real displaySpeed: airspeed

    // React smoothing: prev + (target-prev)*0.15 every 50ms
    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: root.displaySpeed += (root.airspeed - root.displaySpeed) * 0.15
    }
    onDisplaySpeedChanged: dial.requestPaint()

    function speedColor(s) {
        if (s < 60)  return Theme.white;
        if (s < 178) return Theme.green;
        if (s < 250) return Theme.amber;
        return Theme.red;
    }

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

                // colour arcs (exact SVG stroke-dasharray on r=80 circle)
                function arc(stroke, dash, off) {
                    ctx.strokeStyle = stroke; ctx.lineWidth = 12;
                    ctx.setLineDash([dash, 283]); ctx.lineDashOffset = off;
                    ctx.beginPath(); ctx.arc(100, 100, 80, 0, 2 * Math.PI); ctx.stroke();
                }
                arc("rgba(255,255,255,0.3)", 50, -35);
                arc("rgba(34,197,94,0.5)", 118, -85);
                arc("rgba(255,179,0,0.5)", 72, -203);
                ctx.setLineDash([]); ctx.lineDashOffset = 0;

                // major ticks + numbers
                ctx.textAlign = "center"; ctx.textBaseline = "middle";
                var labels = [0, 50, 100, 150, 200, 250, 300];
                for (var i = 0; i < labels.length; i++) {
                    var a = (-135 + i * 270 / 6) * Math.PI / 180;
                    ctx.strokeStyle = "white"; ctx.lineWidth = 2;
                    ctx.beginPath();
                    ctx.moveTo(100 + 70 * Math.cos(a), 100 + 70 * Math.sin(a));
                    ctx.lineTo(100 + 60 * Math.cos(a), 100 + 60 * Math.sin(a));
                    ctx.stroke();
                    ctx.fillStyle = "white"; ctx.font = "bold 12px monospace";
                    var txt = (labels[i] === 0) ? "0" : (labels[i] / 10).toString();
                    ctx.fillText(txt, 100 + 50 * Math.cos(a), 100 + 50 * Math.sin(a));
                }
                // minor ticks
                ctx.strokeStyle = "rgba(255,255,255,0.5)"; ctx.lineWidth = 1;
                for (var j = 0; j < 30; j++) {
                    var b = (-135 + j * 270 / 30) * Math.PI / 180;
                    ctx.beginPath();
                    ctx.moveTo(100 + 70 * Math.cos(b), 100 + 70 * Math.sin(b));
                    ctx.lineTo(100 + 65 * Math.cos(b), 100 + 65 * Math.sin(b));
                    ctx.stroke();
                }
                // needle (rotate -45 + displaySpeed/300*270)
                var rot = (-45 + root.displaySpeed / 300 * 270) * Math.PI / 180;
                ctx.save(); ctx.translate(100, 100); ctx.rotate(rot);
                ctx.fillStyle = "white"; ctx.strokeStyle = "black"; ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.moveTo(0, 0); ctx.lineTo(-2, -70); ctx.lineTo(0, -80); ctx.lineTo(2, -70);
                ctx.closePath(); ctx.fill(); ctx.stroke();
                ctx.beginPath(); ctx.arc(0, 0, 5, 0, 2 * Math.PI);
                ctx.fillStyle = "white"; ctx.fill(); ctx.lineWidth = 2; ctx.stroke();
                ctx.restore();
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: bezel.width * 0.08
            spacing: 0
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "AIRSPEED"; color: "white"; font.pixelSize: 12; font.bold: true; font.family: "monospace" }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(root.displaySpeed); color: root.speedColor(root.displaySpeed); font.pixelSize: 18; font.bold: true; font.family: "monospace" }
        }
    }
}
