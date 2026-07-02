import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0

// CompassRose — rotating compass with ARC/ROSE/PLAN rendering
Canvas {
    id: root
    renderTarget: Canvas.Image
    renderStrategy: Canvas.Immediate
    property var adc
    property string ndMode: "ARC"
    property real heading: adc ? adc.heading : 0

    onHeadingChanged: requestPaint()
    onNdModeChanged:  requestPaint()
    onWidthChanged:   requestPaint()
    onHeightChanged:  requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        var w = width, h = height
        ctx.clearRect(0, 0, w, h)

        var cx = w / 2
        var cy = (ndMode === "ARC") ? h * 0.7 : h / 2
        var r  = Math.min(w, h) * 0.44

        ctx.save()
        ctx.translate(cx, cy)
        
        // In PLAN mode, display is oriented North-up, so compass ring does not rotate with aircraft heading.
        var isPlan = (ndMode === "PLAN")
        if (!isPlan) {
            ctx.rotate(-heading * Math.PI / 180)
        }

        // ── Compass circle ────────────────────────────────────────────────
        ctx.strokeStyle = "#37474f"
        ctx.lineWidth = 1.5
        ctx.beginPath()
        if (ndMode === "ARC") {
            ctx.arc(0, 0, r, -140 * Math.PI / 180, -40 * Math.PI / 180)
        } else {
            ctx.arc(0, 0, r, 0, Math.PI * 2)
        }
        ctx.stroke()

        // ── Degree marks + cardinal labels ────────────────────────────────
        for (var deg = 0; deg < 360; deg += 5) {
            if (ndMode === "ARC") {
                var diff = deg - heading;
                while (diff < -180) diff += 360;
                while (diff > 180) diff -= 360;
                if (Math.abs(diff) > 50) continue;
            }

            var rad = (deg - 90) * Math.PI / 180
            var isMajor = (deg % 10 === 0)
            var inner = r - (isMajor ? 10 : 5)
            ctx.strokeStyle = Theme.mutedFg
            ctx.lineWidth = isMajor ? 1.2 : 0.6
            ctx.beginPath()
            ctx.moveTo(inner * Math.cos(rad), inner * Math.sin(rad))
            ctx.lineTo(r     * Math.cos(rad), r     * Math.sin(rad))
            ctx.stroke()

            if (deg % 30 === 0) {
                var lbl = deg === 0  ? "N" :
                          deg === 90 ? "E" :
                          deg === 180 ? "S" :
                          deg === 270 ? "W" : (deg / 10).toString()
                var labelR = r - 18
                ctx.save()
                ctx.translate(labelR * Math.cos(rad), labelR * Math.sin(rad))
                // Counter-rotate the text labels so they remain upright
                if (!isPlan) {
                    ctx.rotate(heading * Math.PI / 180)
                }
                ctx.fillStyle = (deg % 90 === 0) ? Theme.red : Theme.mutedFg
                ctx.font = (deg % 90 === 0) ? "bold 11px Consolas" : "9px Consolas"
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                ctx.fillText(lbl, 0, 0)
                ctx.restore()
            }
        }

        ctx.restore()

        // ── Heading select bug ────────────────────────────────────────────
        var selHdg = adc ? adc.selectedHeading : 0
        var bugAngle;
        if (isPlan) {
            bugAngle = selHdg - 90;
        } else if (ndMode === "ARC") {
            var bugDiff = selHdg - heading;
            while (bugDiff < -180) bugDiff += 360;
            while (bugDiff > 180) bugDiff -= 360;
            if (bugDiff < -50) bugDiff = -50;
            if (bugDiff > 50) bugDiff = 50;
            bugAngle = bugDiff - 90;
        } else {
            bugAngle = selHdg - heading - 90;
        }
        var bugRad = bugAngle * Math.PI / 180
        ctx.fillStyle = Theme.magenta
        ctx.beginPath()
        ctx.moveTo(cx + (r - 4) * Math.cos(bugRad), cy + (r - 4) * Math.sin(bugRad))
        ctx.lineTo(cx + (r + 8) * Math.cos(bugRad - 0.08), cy + (r + 8) * Math.sin(bugRad - 0.08))
        ctx.lineTo(cx + (r + 8) * Math.cos(bugRad + 0.08), cy + (r + 8) * Math.sin(bugRad + 0.08))
        ctx.closePath()
        ctx.fill()

        // ── Heading line / Aircraft Track line ────────────────────────────
        ctx.strokeStyle = "#90caf9"
        ctx.lineWidth = 1.5
        ctx.beginPath()
        if (isPlan) {
            // In PLAN mode, aircraft is rotating, so the track line points towards the current heading
            var trkRad = (heading - 90) * Math.PI / 180
            ctx.moveTo(cx, cy)
            ctx.lineTo(cx + r * Math.cos(trkRad), cy + r * Math.sin(trkRad))
        } else {
            // In ROSE/ARC modes, aircraft always points straight up
            ctx.moveTo(cx, cy)
            ctx.lineTo(cx, cy - r)
        }
        ctx.stroke()
    }
}
