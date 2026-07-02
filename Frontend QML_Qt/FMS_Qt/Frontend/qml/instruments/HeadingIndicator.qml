import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0

/* HeadingIndicator — rotating compass card. 1:1 port of React instruments/HeadingIndicator.tsx */
Item {
    id: root
    property real heading: 0
    property real displayHeading: heading

    // React smoothing with 360/0 wrap handling
    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: {
            var target = root.heading;
            var diff = target - root.displayHeading;
            if (diff > 180) target -= 360;
            if (diff < -180) target += 360;
            var nh = root.displayHeading + (target - root.displayHeading) * 0.15;
            root.displayHeading = ((nh % 360) + 360) % 360;
        }
    }
    onDisplayHeadingChanged: card.requestPaint()

    function pad3(n) { var s = Math.round(n).toString(); while (s.length < 3) s = "0" + s; return s; }

    Rectangle {
        id: bezel
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height); height: width
        radius: width / 2
        color: "#000000"
        border.color: "#374151"; border.width: 4
        clip: true

        // compass card drawn upright (rotation done analytically per-element)
        Canvas {
            id: card
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d"); ctx.reset();
                var s = width / 200; ctx.scale(s, s);
                ctx.textAlign = "center"; ctx.textBaseline = "middle";
                var hdg = root.displayHeading;

                var pts = [["N",0,"red"],["3",30,""],["6",60,""],["E",90,""],["12",120,""],["15",150,""],
                           ["S",180,""],["21",210,""],["24",240,""],["W",270,""],["30",300,""],["33",330,""]];
                for (var i = 0; i < pts.length; i++) {
                    var dir = pts[i][0]; var deg = pts[i][1]; var col = pts[i][2];
                    var a = (deg - hdg - 90) * Math.PI / 180;
                    ctx.strokeStyle = "white"; ctx.lineWidth = 3;
                    ctx.beginPath();
                    ctx.moveTo(100 + 75 * Math.cos(a), 100 + 75 * Math.sin(a));
                    ctx.lineTo(100 + 85 * Math.cos(a), 100 + 85 * Math.sin(a));
                    ctx.stroke();
                    var big = (dir === "N" || dir === "E" || dir === "S" || dir === "W");
                    ctx.fillStyle = col ? col : "white";
                    ctx.font = "bold " + (big ? 18 : 14) + "px monospace";
                    ctx.fillText(dir, 100 + 60 * Math.cos(a), 100 + 60 * Math.sin(a));
                }
                // minor ticks (every 10°, skip multiples of 30)
                ctx.strokeStyle = "rgba(255,255,255,0.5)"; ctx.lineWidth = 1;
                for (var d = 0; d < 360; d += 10) {
                    if (d % 30 === 0) continue;
                    var b = (d - hdg - 90) * Math.PI / 180;
                    ctx.beginPath();
                    ctx.moveTo(100 + 80 * Math.cos(b), 100 + 80 * Math.sin(b));
                    ctx.lineTo(100 + 85 * Math.cos(b), 100 + 85 * Math.sin(b));
                    ctx.stroke();
                }
                // fixed aircraft symbol (yellow triangle, pointing up)
                ctx.fillStyle = "yellow"; ctx.strokeStyle = "black"; ctx.lineWidth = 1;
                ctx.beginPath(); ctx.moveTo(100, 80); ctx.lineTo(94, 100); ctx.lineTo(106, 100); ctx.closePath();
                ctx.fill(); ctx.stroke();
            }
        }

        // digital heading readout (top-12)
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: bezel.width * 0.24
            color: "#000000"; border.color: "white"; border.width: 2; radius: 3
            width: hdgTxt.implicitWidth + 12; height: hdgTxt.implicitHeight + 6
            Text { id: hdgTxt; anchors.centerIn: parent; text: root.pad3(root.displayHeading) + "°"; color: Theme.green; font.pixelSize: 16; font.bold: true; font.family: "monospace" }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: bezel.width * 0.02
            text: "HEADING"; color: "white"; font.pixelSize: 12; font.bold: true; font.family: "monospace"
        }
    }
}
