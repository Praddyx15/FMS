import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0

// VSIndicator — Vertical Speed Indicator needle gauge (-6000 to +6000 fpm)
Canvas {
    id: root
    renderTarget: Canvas.Image
    renderStrategy: Canvas.Immediate
    property var adc
    property real vsi: adc ? adc.vsi : 0

    onVsiChanged: requestPaint()
    onWidthChanged:  requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        var w = width, h = height
        ctx.clearRect(0, 0, w, h)

        ctx.fillStyle = "#0a0c10"
        ctx.fillRect(0, 0, w, h)

        var cx = w / 2, cy = h / 2
        var r  = Math.min(w, h) * 0.42

        // ── Gauge arc ─────────────────────────────────────────────────────
        ctx.strokeStyle = "#37474f"
        ctx.lineWidth = 4
        ctx.beginPath()
        ctx.arc(cx, cy, r, -Math.PI * 0.85, Math.PI * 0.85)
        ctx.stroke()

        // Tick marks
        var ticks = [-6000, -4000, -2000, -1000, 0, 1000, 2000, 4000, 6000]
        ticks.forEach(function(vs) {
            var pct = vs / 6000
            var angle = pct * Math.PI * 0.85
            var cos = Math.cos(angle - Math.PI / 2)
            var sin = Math.sin(angle - Math.PI / 2)
            var isMajor = (vs % 2000 === 0)
            var innerR = isMajor ? r - 8 : r - 5
            ctx.strokeStyle = Theme.mutedFg
            ctx.lineWidth = isMajor ? 1.5 : 0.8
            ctx.beginPath()
            ctx.moveTo(cx + innerR * cos, cy + innerR * sin)
            ctx.lineTo(cx + r * cos, cy + r * sin)
            ctx.stroke()
            if (isMajor) {
                ctx.fillStyle = Theme.mutedFg
                ctx.font = "bold 7px Consolas"
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                var labelR = r - 16
                ctx.fillText(Math.abs(vs / 1000), cx + labelR * cos, cy + labelR * sin)
            }
        })

        // ── Needle ────────────────────────────────────────────────────────
        var vsiClamped = Math.max(-6000, Math.min(6000, vsi))
        var pct = vsiClamped / 6000
        var angle = pct * Math.PI * 0.85 - Math.PI / 2
        var needleColor = (vsi > 0) ? Theme.green : (vsi < 0) ? Theme.red : Theme.mutedFg

        ctx.strokeStyle = needleColor
        ctx.lineWidth = 2.5
        ctx.lineCap = "round"
        ctx.beginPath()
        ctx.moveTo(cx, cy)
        ctx.lineTo(cx + (r - 6) * Math.cos(angle), cy + (r - 6) * Math.sin(angle))
        ctx.stroke()

        // Centre dot
        ctx.fillStyle = Theme.white
        ctx.beginPath()
        ctx.arc(cx, cy, 3, 0, Math.PI * 2)
        ctx.fill()

        // ── Digital readout ───────────────────────────────────────────────
        ctx.fillStyle = (Math.abs(vsi) > 200) ? needleColor : "#546e7a"
        ctx.font = "bold 9px Consolas"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        var vs = Math.round(Math.abs(vsi) / 50) * 50
        ctx.fillText((vsi >= 0 ? "+" : "-") + vs, cx, cy + r * 0.55)
    }
}
