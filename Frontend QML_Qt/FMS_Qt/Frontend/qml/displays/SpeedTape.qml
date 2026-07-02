import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0

// SpeedTape — IAS speed tape with A320 speed markers
Canvas {
    id: root
    renderTarget: Canvas.Image
    renderStrategy: Canvas.Immediate
    property var adc
    property real ias: adc ? adc.ias : 270

    onIasChanged: requestPaint()
    onWidthChanged:  requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        var w = width, h = height
        ctx.clearRect(0, 0, w, h)

        // Background
        ctx.fillStyle = "#0a0c10"
        ctx.fillRect(0, 0, w, h)

        var cy = h / 2
        var pxPerKt = 3.5   // pixels per knot

        // ── Speed protection zones ────────────────────────────────────────
        var drawZone = function(spd, col, ht) {
            var y = cy - (spd - ias) * pxPerKt
            ctx.fillStyle = col
            ctx.fillRect(0, y - ht, w * 0.22, ht)
        }

        // VMax (red/amber barber pole) — above VMO
        var vmax = adc ? adc.vMax : 350
        var vls  = adc ? adc.vLs  : 210
        var vAlphaProt = adc ? adc.vAlphaProt : 200
        var vAlphaMax  = adc ? adc.vAlphaMax  : 185
        var vFeNext    = adc ? adc.vFeNext    : 225

        var yVmax = cy - (vmax - ias) * pxPerKt
        if (yVmax < h) {
            ctx.fillStyle = Theme.red
            ctx.fillRect(0, 0, w * 0.22, Math.max(0, yVmax))
        }

        // VLS amber zone (from VLS down to vAlphaProt)
        var yVls       = cy - (vls       - ias) * pxPerKt
        var yAlphaProt = cy - (vAlphaProt - ias) * pxPerKt
        if (yVls > 0) {
            ctx.fillStyle = Theme.amber
            ctx.fillRect(0, yAlphaProt, w * 0.22, yVls - yAlphaProt)
        }

        // vAlphaProt → vAlphaMax: dark amber band
        var yAlphaMax = cy - (vAlphaMax - ias) * pxPerKt
        if (yAlphaProt < h) {
            ctx.fillStyle = "#c05000"
            ctx.fillRect(0, yAlphaProt, w * 0.22, Math.max(0, yAlphaMax - yAlphaProt))
        }

        // vAlphaMax and below: red
        if (yAlphaMax < h && yAlphaMax > 0) {
            ctx.fillStyle = Theme.red
            ctx.fillRect(0, yAlphaMax, w * 0.22, h - yAlphaMax)
        }

        // VFe-next: amber dashed horizontal line (no setLineDash — leaks memory)
        var yVfe = cy - (vFeNext - ias) * pxPerKt
        if (yVfe >= 0 && yVfe <= h) {
            ctx.fillStyle = Theme.amber
            for (var dx = 0; dx < w * 0.22; dx += 8) {
                ctx.fillRect(dx, yVfe - 1, 4, 2)
            }
        }

        // ── Tape graduation ───────────────────────────────────────────────
        ctx.strokeStyle = Theme.white
        ctx.fillStyle   = Theme.white
        ctx.font = "bold 9px Consolas"
        ctx.textAlign = "right"
        ctx.textBaseline = "middle"

        var minSpd = Math.max(0, ias - h / pxPerKt / 2)
        var maxSpd = ias + h / pxPerKt / 2

        for (var spd = Math.ceil(minSpd / 10) * 10; spd <= maxSpd; spd += 10) {
            var y = cy - (spd - ias) * pxPerKt
            ctx.lineWidth = (spd % 20 === 0) ? 1.5 : 0.8
            ctx.beginPath()
            ctx.moveTo(w * 0.22, y)
            ctx.lineTo(w * 0.45, y)
            ctx.stroke()
            if (spd % 20 === 0) {
                ctx.fillText(spd, w - 2, y)
            }
        }

        // ── Speed bug markers ─────────────────────────────────────────────
        var drawBug = function(spd, col, label) {
            var y = cy - (spd - ias) * pxPerKt
            if (y < 0 || y > h) return
            ctx.strokeStyle = col; ctx.fillStyle = col; ctx.lineWidth = 2
            ctx.beginPath()
            ctx.moveTo(w * 0.45, y)
            ctx.lineTo(w * 0.65, y - 5)
            ctx.lineTo(w * 0.65, y + 5)
            ctx.closePath(); ctx.fill()
            ctx.font = "bold 8px Consolas"
            ctx.fillText(label, w * 0.62, y - 6)
        }

        if (adc) {
            drawBug(adc.v1,   Theme.green, "V1")
            drawBug(adc.vr,   Theme.green, "VR")
            drawBug(adc.v2,   Theme.green, "V2")
            drawBug(adc.greenDot, Theme.green, "●")
            drawBug(adc.slatRetract, Theme.amber, "S")
            drawBug(adc.flapRetract, Theme.amber, "F")
        }

        // ── Speed trend vector ────────────────────────────────────────────
        if (adc && Math.abs(adc.speedTrend) > 0.5) {
            var trendPx = adc.speedTrend * pxPerKt * 10
            ctx.strokeStyle = Theme.cyan
            ctx.lineWidth = 2
            ctx.beginPath(); ctx.moveTo(w * 0.22, cy); ctx.lineTo(w * 0.22, cy - trendPx); ctx.stroke()
        }

        // ── Current IAS box ───────────────────────────────────────────────
        ctx.fillStyle = "#000000"
        ctx.fillRect(0, cy - 12, w, 24)
        ctx.strokeStyle = Theme.white
        ctx.lineWidth = 1.5
        ctx.strokeRect(0, cy - 12, w, 24)
        ctx.fillStyle = Theme.white
        ctx.font = "bold 15px Consolas"
        ctx.textAlign = "center"
        ctx.fillText(Math.round(ias), w / 2, cy + 1)

        // ── Managed speed target (magenta triangle on right edge) ─────────────
        var targetSpd = adc ? adc.selectedSpeed : 280
        var ty = cy - (targetSpd - ias) * pxPerKt
        if (ty >= 0 && ty <= h) {
            ctx.fillStyle = Theme.magenta
            ctx.beginPath()
            ctx.moveTo(w, ty)
            ctx.lineTo(w - 10, ty - 5)
            ctx.lineTo(w - 10, ty + 5)
            ctx.closePath()
            ctx.fill()
        }

        // ── Cyan selected-speed readout box above IAS ─────────────────────────
        ctx.fillStyle = Theme.cyan
        ctx.strokeStyle = Theme.cyan
        ctx.lineWidth = 1
        ctx.strokeRect(1, cy - 28, w - 2, 14)
        ctx.font = "bold 10px Consolas"
        ctx.textAlign = "center"
        ctx.fillText(Math.round(targetSpd), w / 2, cy - 21)
    }
}
