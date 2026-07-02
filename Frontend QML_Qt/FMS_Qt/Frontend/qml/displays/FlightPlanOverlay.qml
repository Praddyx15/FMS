import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0

// FlightPlanOverlay — draws waypoints and route on the ND
Canvas {
    id: root
    renderTarget: Canvas.Image
    renderStrategy: Canvas.Immediate
    property var adc
    property string ndMode: "ARC"

    property var waypoints: FlightDataManager ? FlightDataManager.waypoints : []
    onWaypointsChanged: requestPaint()
    onNdModeChanged:    requestPaint()
    onWidthChanged:     requestPaint()
    onHeightChanged:    requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        var w = width, h = height
        ctx.clearRect(0, 0, w, h)
        if (!waypoints || waypoints.length < 2) return

        var cx = w / 2
        var cy = (ndMode === "ARC") ? h * 0.7 : h / 2
        var range = FlightDataManager ? FlightDataManager.ndRange : 80  // nm
        var scale = Math.min(w, h) * 0.44 / range  // px per nm

        // Convert lat/lon to screen pixels (simple equirectangular for short range)
        var ownLat = adc ? adc.latitude : 50.0379
        var ownLon = adc ? adc.longitude : 8.5622

        var centerLat = ownLat
        var centerLon = ownLon
        var hdg = adc ? adc.heading : 0

        if (ndMode === "PLAN") {
            var activeIdx = adc ? adc.activeWaypointIndex : 0
            if (waypoints && activeIdx >= 0 && activeIdx < waypoints.length) {
                centerLat = waypoints[activeIdx].lat
                centerLon = waypoints[activeIdx].lon
            }
            hdg = 0 // static North-up
        }

        function toScreen(lat, lon) {
            var dnm = (lat - centerLat) * 60   // nm
            var enm = (lon - centerLon) * 60 * Math.cos(centerLat * Math.PI / 180)
            
            // Rotate by heading
            var rad = (hdg - 90) * Math.PI / 180
            var sx = enm * Math.cos(-rad) - dnm * Math.sin(-rad)
            var sy = enm * Math.sin(-rad) + dnm * Math.cos(-rad)
            
            return { x: cx + sx * scale, y: cy - sy * scale }
        }

        // ── Route line ────────────────────────────────────────────────────
        ctx.strokeStyle = Theme.cyan
        ctx.lineWidth = 1.5
        ctx.setLineDash([])
        ctx.beginPath()
        var first = toScreen(waypoints[0].lat, waypoints[0].lon)
        ctx.moveTo(first.x, first.y)
        for (var i = 1; i < waypoints.length; i++) {
            var pt = toScreen(waypoints[i].lat, waypoints[i].lon)
            ctx.lineTo(pt.x, pt.y)
        }
        ctx.stroke()

        // ── Waypoint symbols + labels ─────────────────────────────────────
        waypoints.forEach(function(wp, idx) {
            var pt = toScreen(wp.lat, wp.lon)
            if (pt.x < 0 || pt.x > w || pt.y < 0 || pt.y > h) return

            ctx.fillStyle = Theme.cyan
            ctx.strokeStyle = Theme.cyan
            ctx.lineWidth = 1.2

            // Triangle symbol
            ctx.beginPath()
            ctx.moveTo(pt.x, pt.y - 6)
            ctx.lineTo(pt.x - 4, pt.y + 4)
            ctx.lineTo(pt.x + 4, pt.y + 4)
            ctx.closePath()
            ctx.stroke()

            // Label
            ctx.fillStyle = "#e0f7fa"
            ctx.font = "bold 9px Consolas"
            ctx.textAlign = "left"
            ctx.textBaseline = "middle"
            ctx.fillText(wp.name, pt.x + 6, pt.y - 4)

            // Altitude constraint
            if (wp.altitude > 0) {
                ctx.fillStyle = Theme.amber
                ctx.font = "8px Consolas"
                ctx.fillText("FL" + Math.round(wp.altitude / 100), pt.x + 6, pt.y + 6)
            }
        })
    }
}
