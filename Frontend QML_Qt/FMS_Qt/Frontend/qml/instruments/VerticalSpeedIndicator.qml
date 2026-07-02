import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0

/* VerticalSpeedIndicator — 1:1 port of React instruments/VerticalSpeedIndicator.tsx */
Item {
    id: root
    property real vsi: 0
    property real displayVSI: vsi

    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: root.displayVSI += (root.vsi - root.displayVSI) * 0.2
    }
    onDisplayVSIChanged: dial.requestPaint()

    function vsiColor(r) {
        var a = Math.abs(r);
        if (a < 500)  return Theme.green;
        if (a < 2000) return Theme.amber;
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
                ctx.textAlign = "center"; ctx.textBaseline = "middle";

                var marks = [[-2,-90],[-1,-60],[-0.5,-30],[0,0],[0.5,30],[1,60],[2,90]];
                for (var i = 0; i < marks.length; i++) {
                    var val = marks[i][0]; var ang = marks[i][1];
                    var a = (ang - 90) * Math.PI / 180;
                    ctx.strokeStyle = "white"; ctx.lineWidth = 2;
                    ctx.beginPath();
                    ctx.moveTo(100 + 75 * Math.cos(a), 100 + 75 * Math.sin(a));
                    ctx.lineTo(100 + 65 * Math.cos(a), 100 + 65 * Math.sin(a));
                    ctx.stroke();
                    if (val !== 0) {
                        ctx.fillStyle = "white"; ctx.font = "bold 12px monospace";
                        ctx.fillText(Math.abs(val).toString(), 100 + 55 * Math.cos(a), 100 + 55 * Math.sin(a));
                    }
                }
                // UP / DN labels
                ctx.fillStyle = "white"; ctx.font = "bold 12px monospace";
                ctx.fillText("UP", 100, 25); ctx.fillText("DN", 100, 185);

                // minor ticks
                ctx.strokeStyle = "rgba(255,255,255,0.3)"; ctx.lineWidth = 1;
                for (var j = 0; j < 20; j++) {
                    var b = (-180 + j * 180 / 19) * Math.PI / 180;
                    ctx.beginPath();
                    ctx.moveTo(100 + 75 * Math.cos(b), 100 + 75 * Math.sin(b));
                    ctx.lineTo(100 + 70 * Math.cos(b), 100 + 70 * Math.sin(b));
                    ctx.stroke();
                }
                // needle
                var clamped = Math.max(-4000, Math.min(4000, root.displayVSI));
                var rot = (clamped / 2000 * 90) * Math.PI / 180;
                ctx.save(); ctx.translate(100, 100); ctx.rotate(rot);
                ctx.strokeStyle = "white"; ctx.lineWidth = 3;
                ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(0, -70); ctx.stroke();
                ctx.fillStyle = "white";
                ctx.beginPath(); ctx.moveTo(0, -70); ctx.lineTo(-3, -60); ctx.lineTo(3, -60); ctx.closePath(); ctx.fill();
                ctx.restore();
                // hub
                ctx.beginPath(); ctx.arc(100, 100, 5, 0, 2 * Math.PI);
                ctx.fillStyle = "white"; ctx.fill(); ctx.strokeStyle = "black"; ctx.lineWidth = 2; ctx.stroke();
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: bezel.width * 0.20
            color: "#000000"; border.color: "white"; border.width: 2; radius: 3
            width: vsiTxt.implicitWidth + 12; height: vsiTxt.implicitHeight + 3
            Text {
                id: vsiTxt; anchors.centerIn: parent
                text: (root.displayVSI > 0 ? "+" : "") + Math.round(root.displayVSI)
                color: root.vsiColor(root.displayVSI); font.pixelSize: 12; font.bold: true; font.family: "monospace"
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: bezel.width * 0.02
            text: "VSI"; color: "white"; font.pixelSize: 12; font.bold: true; font.family: "monospace"
        }
    }
}
