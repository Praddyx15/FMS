import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0

// AttitudeIndicator — Canvas-based artificial horizon
Canvas {
    id: root
    renderTarget: Canvas.Image
    renderStrategy: Canvas.Immediate
    property var adc
    property real pitchDeg: adc ? adc.pitch : 0
    property real rollDeg:  adc ? adc.roll  : 0
    property bool fdActive: adc ? adc.fdActive : true

    onPitchDegChanged: requestPaint()
    onRollDegChanged:  requestPaint()
    onWidthChanged:    requestPaint()
    onHeightChanged:   requestPaint()

    // Smooth 60Hz bindings

    onPaint: {
        var ctx = getContext("2d")
        var w = width, h = height
        var cx = w / 2, cy = h / 2
        ctx.clearRect(0, 0, w, h)

        ctx.save()

        // ── Clip to a circle (A320 standard Attitude indicator shape) ──
        var r = Math.min(w, h) * 0.44
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, 2 * Math.PI)
        ctx.clip()

        // ── Background gradient (sky/ground) ──────────────────────────────
        ctx.save()
        ctx.translate(cx, cy)
        ctx.rotate(rollDeg * Math.PI / 180)

        var pitchPx = pitchDeg * (h / 60) // pixels per degree ladder

        // Sky
        ctx.fillStyle = "#1565c0"
        ctx.fillRect(-w, -h - pitchPx, w * 2, h * 2)

        // Ground
        ctx.fillStyle = "#5d4037"
        ctx.fillRect(-w, -pitchPx, w * 2, h)

        // Horizon line
        ctx.strokeStyle = Theme.white
        ctx.lineWidth = 2
        ctx.beginPath()
        ctx.moveTo(-w, -pitchPx)
        ctx.lineTo(w, -pitchPx)
        ctx.stroke()

        // ── Pitch ladder ──────────────────────────────────────────────────
        ctx.strokeStyle = Theme.white
        ctx.lineWidth = 1
        ctx.font = "bold 9px Consolas"
        ctx.fillStyle = Theme.white
        ctx.textAlign = "right"
        ctx.textBaseline = "middle"

        for (var deg = -30; deg <= 30; deg += 5) {
            if (deg === 0) continue
            var y = -pitchPx - deg * (h / 60)
            var len = (Math.abs(deg) % 10 === 0) ? 28 : 14
            ctx.beginPath()
            ctx.moveTo(-len, y)
            ctx.lineTo(len, y)
            ctx.stroke()
            if (Math.abs(deg) % 10 === 0) {
                ctx.fillText(Math.abs(deg), -len - 4, y)
            }
        }

        ctx.restore() // Restores the translation/rotation of background/ladder

        ctx.restore() // Restores the clipping context so elements outside are not clipped

        // ── Outer Bezel (Drawn outside clipping) ──────────────────────────
        ctx.save()
        ctx.strokeStyle = "#37474f" // Slate gray bezel
        ctx.lineWidth = 6
        ctx.beginPath()
        ctx.arc(cx, cy, r + 3, 0, 2 * Math.PI)
        ctx.stroke()
        ctx.restore()

        // ── Bank angle arc ────────────────────────────────────────────────
        var arcR = Math.min(w, h) * 0.42
        ctx.save()
        ctx.translate(cx, cy)
        ctx.strokeStyle = "#90caf9"
        ctx.lineWidth = 1.5
        ctx.beginPath()
        ctx.arc(0, 0, arcR, -Math.PI * 0.75, -Math.PI * 0.25)
        ctx.stroke()

        // Bank angle tick marks
        var bankAngles = [-60, -45, -30, -20, -10, 0, 10, 20, 30, 45, 60]
        bankAngles.forEach(function(angle) {
            var rad = (angle - 90) * Math.PI / 180
            var inner = arcR - 6
            ctx.beginPath()
            ctx.moveTo(inner * Math.cos(rad), inner * Math.sin(rad))
            ctx.lineTo(arcR * Math.cos(rad), arcR * Math.sin(rad))
            ctx.stroke()
        })

        // Bank angle pointer
        ctx.save()
        ctx.rotate(rollDeg * Math.PI / 180)
        ctx.fillStyle = "#90caf9"
        ctx.beginPath()
        ctx.moveTo(0, -arcR + 2)
        ctx.lineTo(-5, -arcR + 12)
        ctx.lineTo(5, -arcR + 12)
        ctx.closePath()
        ctx.fill()
        ctx.restore()

        ctx.restore() // Restores translation/rotation for bank angle

        // ── Fixed aircraft symbol ─────────────────────────────────────────
        ctx.strokeStyle = "#ffeb3b"
        ctx.lineWidth = 3
        ctx.lineCap = "round"
        // Wings
        ctx.beginPath()
        ctx.moveTo(cx - 30, cy)
        ctx.lineTo(cx - 8, cy)
        ctx.moveTo(cx + 8, cy)
        ctx.lineTo(cx + 30, cy)
        ctx.stroke()
        // Nose
        ctx.fillStyle = "#ffeb3b"
        ctx.beginPath()
        ctx.arc(cx, cy, 4, 0, Math.PI * 2)
        ctx.fill()
        // Tail
        ctx.beginPath()
        ctx.moveTo(cx, cy - 2)
        ctx.lineTo(cx, cy - 14)
        ctx.stroke()

        // ── Flight Director (FD) ──────────────────────────────────────────
        if (fdActive) {
            var targetPitch = adc ? adc.targetPitch : 0
            var targetRoll  = adc ? adc.targetRoll  : 0
            
            ctx.save()
            ctx.strokeStyle = Theme.green
            ctx.lineWidth = 2.5
            ctx.shadowColor = Qt.rgba(0.46, 1.0, 0.01, 0.5)
            ctx.shadowBlur = 4
            
            // Pitch bar (horizontal)
            var fdY = cy + (pitchDeg - targetPitch) * (h / 60)
            if (fdY > cy - r && fdY < cy + r) {
                ctx.beginPath()
                ctx.moveTo(cx - 35, fdY)
                ctx.lineTo(cx + 35, fdY)
                ctx.stroke()
            }
            
            // Roll bar (vertical)
            var fdX = cx + (targetRoll - rollDeg) * (w / 60)
            if (fdX > cx - r && fdX < cx + r) {
                ctx.beginPath()
                ctx.moveTo(fdX, cy - 35)
                ctx.lineTo(fdX, cy + 35)
                ctx.stroke()
            }
            ctx.restore()
        }
    }
}
