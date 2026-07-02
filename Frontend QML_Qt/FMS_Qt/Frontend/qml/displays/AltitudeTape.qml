import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0

// AltitudeTape — barometric altitude tape with target bug
Canvas {
    id: root
    renderTarget: Canvas.Image
    renderStrategy: Canvas.Immediate
    property var adc
    property real altitude: adc ? adc.altitude : 32000

    onAltitudeChanged: requestPaint()
    onWidthChanged:  requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        var w = width, h = height
        ctx.clearRect(0, 0, w, h)

        ctx.fillStyle = "#0a0c10"
        ctx.fillRect(0, 0, w, h)

        var cy = h / 2
        var pxPerFt = h / 1200   // 1200 ft visible range

        // ── Tape graduation ───────────────────────────────────────────────
        ctx.strokeStyle = Theme.white
        ctx.fillStyle   = Theme.white
        ctx.font = "bold 8px Consolas"
        ctx.textAlign = "left"
        ctx.textBaseline = "middle"

        var minAlt = altitude - 600
        var maxAlt = altitude + 600

        for (var alt = Math.ceil(minAlt / 100) * 100; alt <= maxAlt; alt += 100) {
            var y = cy + (altitude - alt) * pxPerFt
            ctx.lineWidth = (alt % 500 === 0) ? 1.5 : 0.8
            ctx.beginPath()
            ctx.moveTo(w * 0.55, y)
            ctx.lineTo(w * 0.78, y)
            ctx.stroke()
            if (alt % 500 === 0) {
                ctx.fillText(alt, 1, y)
            }
        }

        // ── Target altitude bug ───────────────────────────────────────────
        var targetAlt = adc ? adc.selectedAltitude : 32000
        var ty = cy + (altitude - targetAlt) * pxPerFt
        if (ty >= 0 && ty <= h) {
            ctx.fillStyle  = Theme.magenta
            ctx.strokeStyle = Theme.magenta
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.moveTo(w * 0.55, ty)
            ctx.lineTo(w * 0.45, ty - 6)
            ctx.lineTo(w * 0.35, ty - 6)
            ctx.lineTo(w * 0.35, ty + 6)
            ctx.lineTo(w * 0.45, ty + 6)
            ctx.closePath()
            ctx.fill()
        }

        // ── Cyan selected altitude readout box (above current alt box) ─────────
        var selAlt = adc ? adc.selectedAltitude : 32000
        ctx.fillStyle  = Theme.cyan
        ctx.strokeStyle = Theme.cyan
        ctx.lineWidth  = 1
        ctx.strokeRect(1, cy - 29, w - 2, 14)
        ctx.font = "bold 9px Consolas"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillText(Math.round(selAlt), w / 2, cy - 22)

        // ── Current altitude box ───────────────────────────────────────────────
        ctx.fillStyle = "#000000"
        ctx.fillRect(0, cy - 12, w, 24)
        ctx.strokeStyle = Theme.white
        ctx.lineWidth = 1.5
        ctx.strokeRect(0, cy - 12, w, 24)
        ctx.fillStyle = Theme.white
        ctx.font = "bold 13px Consolas"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillText(Math.round(altitude).toString().padStart(5, ' '), w / 2, cy)

        // ── QNH baro setting strip (bottom of tape) ─────────────────────────
        ctx.fillStyle = "#000000"
        ctx.fillRect(0, h - 18, w, 18)
        ctx.strokeStyle = Theme.cyan
        ctx.lineWidth = 1
        ctx.strokeRect(0, h - 18, w, 18)
        ctx.fillStyle = Theme.cyan
        ctx.font = "bold 8px Consolas"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        var qnh = (typeof FlightDataManager !== "undefined" && FlightDataManager) ? FlightDataManager.qnh.toFixed(0) : "1013"
        ctx.fillText(qnh + " hPa", w / 2, h - 9)
    }
}
