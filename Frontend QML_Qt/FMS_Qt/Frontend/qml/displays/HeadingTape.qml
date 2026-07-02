import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0

// HeadingTape — horizontal Canvas strip (A320 PFD lower tape)
// Shows ±30° of heading with:
//   • Cyan   — current heading (centre)
//   • Magenta — selected heading bug
//   • Green  — ILS course pointer (when ILS armed)
Canvas {
    id: root
    renderTarget:   Canvas.Image
    renderStrategy: Canvas.Immediate
    property var adc

    property real hdg:      adc ? adc.heading         : 0
    property real selHdg:   adc ? adc.selectedHeading : 0
    property bool ilsArmed: adc ? adc.ilsArmed        : false
    property real ilsCrs:   284.0   // fixed ILS course (update via FDM later)

    onHdgChanged:    requestPaint()
    onSelHdgChanged: requestPaint()
    onIlsArmedChanged: requestPaint()
    onWidthChanged:  requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        var w = width, h = height
        ctx.clearRect(0, 0, w, h)

        // Background
        ctx.fillStyle = "#0d1017"
        ctx.fillRect(0, 0, w, h)

        var cx = w / 2
        var pxPerDeg = w / 60.0   // 60° visible range → full width

        // ── Tick marks and labels ─────────────────────────────────────────────
        ctx.strokeStyle = Theme.white
        ctx.fillStyle   = Theme.white
        ctx.font = "bold 8px Consolas"
        ctx.textAlign = "center"
        ctx.textBaseline = "bottom"

        for (var dDeg = -35; dDeg <= 35; dDeg += 5) {
            var tickHdg = ((hdg + dDeg) % 360 + 360) % 360
            var x = cx + dDeg * pxPerDeg
            var tickH = (tickHdg % 10 === 0) ? h * 0.55 : h * 0.3

            ctx.lineWidth = (tickHdg % 10 === 0) ? 1.5 : 0.8
            ctx.beginPath()
            ctx.moveTo(x, 0)
            ctx.lineTo(x, tickH)
            ctx.stroke()

            if (tickHdg % 10 === 0) {
                // Cardinal abbreviations
                var label = tickHdg.toString()
                if (tickHdg === 0 || tickHdg === 360) label = "N"
                else if (tickHdg === 90)  label = "E"
                else if (tickHdg === 180) label = "S"
                else if (tickHdg === 270) label = "W"
                else label = (tickHdg / 10).toString()   // compact (e.g. "28" for 280)

                ctx.fillStyle = Theme.white
                ctx.fillText(label, x, h - 2)
            }
        }

        // ── Selected heading bug (magenta) ────────────────────────────────────
        var selDiff = selHdg - hdg
        while (selDiff >  180) selDiff -= 360
        while (selDiff < -180) selDiff += 360
        var selX = cx + selDiff * pxPerDeg
        if (selX > 4 && selX < w - 4) {
            ctx.fillStyle = Theme.magenta
            ctx.beginPath()
            ctx.moveTo(selX, 0)
            ctx.lineTo(selX - 6, 12)
            ctx.lineTo(selX + 6, 12)
            ctx.closePath()
            ctx.fill()
        }

        // ── ILS course pointer (green) ────────────────────────────────────────
        if (ilsArmed) {
            var ilsDiff = ilsCrs - hdg
            while (ilsDiff >  180) ilsDiff -= 360
            while (ilsDiff < -180) ilsDiff += 360
            var ilsX = cx + ilsDiff * pxPerDeg
            if (ilsX > 4 && ilsX < w - 4) {
                ctx.strokeStyle = Theme.green
                ctx.lineWidth = 2
                ctx.beginPath()
                ctx.moveTo(ilsX, 0)
                ctx.lineTo(ilsX, h * 0.7)
                ctx.stroke()
                // diamond top
                ctx.fillStyle = Theme.green
                ctx.beginPath()
                ctx.moveTo(ilsX, 0)
                ctx.lineTo(ilsX - 4, 7)
                ctx.lineTo(ilsX + 4, 7)
                ctx.closePath()
                ctx.fill()
            }
        }

        // ── Current heading marker (cyan notch at centre) ─────────────────────
        ctx.fillStyle = Theme.cyan
        ctx.beginPath()
        ctx.moveTo(cx, 0)
        ctx.lineTo(cx - 5, 10)
        ctx.lineTo(cx + 5, 10)
        ctx.closePath()
        ctx.fill()

        // ── Centre bounding box ───────────────────────────────────────────────
        ctx.fillStyle = "#000000"
        ctx.fillRect(cx - 18, h - 18, 36, 18)
        ctx.strokeStyle = Theme.cyan
        ctx.lineWidth = 1
        ctx.strokeRect(cx - 18, h - 18, 36, 18)
        ctx.fillStyle = Theme.cyan
        ctx.font = "bold 10px Consolas"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        ctx.fillText(Math.round(hdg).toString().padStart(3, "0"), cx, h - 9)
    }
}
