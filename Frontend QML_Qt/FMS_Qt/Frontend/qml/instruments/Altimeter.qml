import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0

/* Altimeter — 3-needle analog. 1:1 port of React instruments/Altimeter.tsx */
Item {
    id: root
    property real altitude: 0
    property real qnh: 1013
    property real displayAltitude: altitude

    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: root.displayAltitude += (root.altitude - root.displayAltitude) * 0.15
    }
    onDisplayAltitudeChanged: dial.requestPaint()

    function pad5(n) { var s = Math.round(n).toString(); while (s.length < 5) s = "0" + s; return s; }

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
                ctx.textAlign = "center"; ctx.textBaseline = "middle";

                // outer ring numbers 0-9
                for (var i = 0; i < 10; i++) {
                    var a = (i * 36 - 90) * Math.PI / 180;
                    ctx.strokeStyle = "white"; ctx.lineWidth = 2;
                    ctx.beginPath();
                    ctx.moveTo(100 + 85 * Math.cos(a), 100 + 85 * Math.sin(a));
                    ctx.lineTo(100 + 75 * Math.cos(a), 100 + 75 * Math.sin(a));
                    ctx.stroke();
                    ctx.fillStyle = "white"; ctx.font = "bold 14px monospace";
                    ctx.fillText(i.toString(), 100 + 65 * Math.cos(a), 100 + 65 * Math.sin(a));
                }
                // minor ticks
                ctx.strokeStyle = "rgba(255,255,255,0.5)"; ctx.lineWidth = 1;
                for (var j = 0; j < 50; j++) {
                    var b = (j * 7.2 - 90) * Math.PI / 180;
                    ctx.beginPath();
                    ctx.moveTo(100 + 85 * Math.cos(b), 100 + 85 * Math.sin(b));
                    ctx.lineTo(100 + 80 * Math.cos(b), 100 + 80 * Math.sin(b));
                    ctx.stroke();
                }
                var alt = root.displayAltitude;
                var hundreds = (alt % 1000) / 1000 * 360;
                var thousands = (alt % 10000) / 10000 * 360;
                var tenK = (alt % 100000) / 100000 * 360;

                function hand(deg, drawFn) {
                    ctx.save(); ctx.translate(100, 100); ctx.rotate(deg * Math.PI / 180);
                    drawFn(); ctx.restore();
                }
                // 10,000 ft (short triangle)
                hand(tenK, function () {
                    ctx.fillStyle = "white"; ctx.strokeStyle = "black"; ctx.lineWidth = 1;
                    ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(-3, -50); ctx.lineTo(0, -55); ctx.lineTo(3, -50);
                    ctx.closePath(); ctx.fill(); ctx.stroke();
                });
                // 1,000 ft
                hand(thousands, function () {
                    ctx.fillStyle = "white"; ctx.strokeStyle = "black"; ctx.lineWidth = 1;
                    ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(-3, -65); ctx.lineTo(0, -75); ctx.lineTo(3, -65);
                    ctx.closePath(); ctx.fill(); ctx.stroke();
                });
                // 100 ft (long line + arrow)
                hand(hundreds, function () {
                    ctx.strokeStyle = "white"; ctx.lineWidth = 3;
                    ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(0, -80); ctx.stroke();
                    ctx.fillStyle = "white";
                    ctx.beginPath(); ctx.moveTo(0, -80); ctx.lineTo(-3, -70); ctx.lineTo(3, -70); ctx.closePath(); ctx.fill();
                });
                // hub
                ctx.beginPath(); ctx.arc(100, 100, 6, 0, 2 * Math.PI);
                ctx.fillStyle = "white"; ctx.fill(); ctx.strokeStyle = "black"; ctx.lineWidth = 2; ctx.stroke();
            }
        }

        // digital altitude readout (centre, mt-8)
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: bezel.width * 0.16
            color: "#000000"; border.color: "white"; border.width: 2; radius: 3
            width: altTxt.implicitWidth + 16; height: altTxt.implicitHeight + 6
            Text { id: altTxt; anchors.centerIn: parent; text: root.pad5(root.displayAltitude); color: Theme.green; font.pixelSize: 14; font.bold: true; font.family: "monospace" }
        }

        // QNH box
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: bezel.width * 0.16
            color: "#000000"; border.color: "white"; border.width: 1; radius: 3
            width: qnhTxt.implicitWidth + 12; height: qnhTxt.implicitHeight + 4
            Text { id: qnhTxt; anchors.centerIn: parent; text: Math.round(root.qnh); color: "white"; font.pixelSize: 11; font.family: "monospace" }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: bezel.width * 0.02
            text: "ALT"; color: "white"; font.pixelSize: 12; font.bold: true; font.family: "monospace"
        }
    }
}
