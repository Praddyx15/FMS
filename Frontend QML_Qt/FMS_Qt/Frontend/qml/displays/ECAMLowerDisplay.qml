import QtQuick 2.15
import FmsTrainer 1.0
import FmsBackend 1.0

/*
 * ECAMLowerDisplay — the lower ECAM "System Display" (SD).
 * Faithful 1:1 port of React src/components/displays/ECAMLowerDisplay.tsx.
 * Each page is the exact same SVG drawing, reproduced on a Canvas using the
 * original 500x400 viewBox with xMidYMid-meet scaling. Canvas fillText uses an
 * alphabetic baseline, matching SVG <text> y-coordinates exactly.
 *
 * The SD intentionally uses pure CRT display colours (#00ff00 / #00ffff /
 * #ffaa00) exactly as the React source does — these differ slightly from the
 * Tailwind display-* tokens and are kept verbatim for fidelity.
 */
Canvas {
    id: root
    renderTarget: Canvas.Image
    renderStrategy: Canvas.Immediate
    property var adc
    property string selectedPage: "ENG"
    onSelectedPageChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    Connections {
        target: root.adc
        ignoreUnknownSignals: true
        function onDataChanged() { root.requestPaint(); }
    }

    // Exact SVG colours from the React source
    readonly property string cGreen: "#00ff00"
    readonly property string cCyan:  "#00ffff"
    readonly property string cWhite: "#ffffff"
    readonly property string cAmber: "#ffaa00"

    Connections {
        target: FlightDataManager
        function onSystemsChanged() { root.requestPaint(); }
        function onFlightDataChanged() { root.requestPaint(); }
        function onEfisChanged() { root.requestPaint(); }
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        // black background (bg-black)
        ctx.fillStyle = "#000000";
        ctx.fillRect(0, 0, width, height);

        // xMidYMid meet: uniform scale of the 500x400 viewBox, centred
        var s = Math.min(width / 500, height / 400);
        ctx.save();
        ctx.translate((width - 500 * s) / 2, (height - 400 * s) / 2);
        ctx.scale(s, s);
        ctx.textBaseline = "alphabetic";
        drawPage(ctx, root.selectedPage);
        ctx.restore();
    }

    // ── helpers (mirror SVG primitives) ───────────────────────────────────────
    function txt(ctx, x, y, fill, size, str, anchorMiddle) {
        ctx.fillStyle = fill;
        ctx.font = size + "px monospace";
        ctx.textAlign = anchorMiddle ? "center" : "left";
        ctx.fillText(str, x, y);
    }
    function strokeRect(ctx, x, y, w, h, stroke, lw) {
        ctx.strokeStyle = stroke; ctx.lineWidth = lw;
        ctx.strokeRect(x, y, w, h);
    }
    function fillRect(ctx, x, y, w, h, fill, alpha) {
        ctx.globalAlpha = (alpha === undefined) ? 1.0 : alpha;
        ctx.fillStyle = fill; ctx.fillRect(x, y, w, h);
        ctx.globalAlpha = 1.0;
    }
    function circle(ctx, cx, cy, r, stroke, lw) {
        ctx.strokeStyle = stroke; ctx.lineWidth = lw;
        ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2 * Math.PI); ctx.stroke();
    }
    function line(ctx, x1, y1, x2, y2, stroke, lw) {
        ctx.strokeStyle = stroke; ctx.lineWidth = lw;
        ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke();
    }

    function drawPage(ctx, page) {
        switch (page) {
        case "BLEED": drawBleed(ctx); break;
        case "PRESS": drawPress(ctx); break;
        case "ELEC":  drawElec(ctx);  break;
        case "HYD":   drawHyd(ctx);   break;
        case "FUEL":  drawFuel(ctx);  break;
        case "APU":   drawApu(ctx);   break;
        case "COND":  drawCond(ctx);  break;
        case "DOOR":  drawDoor(ctx);  break;
        case "WHEEL": drawWheel(ctx); break;
        case "F/CTL": drawFctl(ctx);  break;
        case "STS":   drawSts(ctx);   break;
        default:      drawEng(ctx);   break;
        }
    }

    function drawEng(ctx) {
        var n1L = root.adc ? root.adc.n1Left : 85.2;
        var n1R = root.adc ? root.adc.n1Right : 85.5;
        var egtL = root.adc ? root.adc.egtLeft : 715;
        var egtR = root.adc ? root.adc.egtRight : 718;

        txt(ctx, 250, 30, cCyan, 18, "ENG", true);
        txt(ctx, 100, 80, cGreen, 14, "OIL", false);
        txt(ctx, 80, 110, cWhite, 11, "PSI", false);
        txt(ctx, 120, 110, cGreen, 13, "85", false);
        txt(ctx, 80, 130, cWhite, 11, "°C", false);
        txt(ctx, 120, 130, cGreen, 13, "75", false);
        txt(ctx, 380, 110, cGreen, 13, "82", false);
        txt(ctx, 380, 130, cGreen, 13, "72", false);
        
        txt(ctx, 100, 170, cGreen, 14, "VIB", false);
        txt(ctx, 80, 195, cWhite, 11, "N1", false);
        txt(ctx, 120, 195, cGreen, 13, "0.3", false);
        txt(ctx, 80, 215, cWhite, 11, "N2", false);
        txt(ctx, 120, 215, cGreen, 13, "0.2", false);
        txt(ctx, 380, 195, cGreen, 13, "0.4", false);
        txt(ctx, 380, 215, cGreen, 13, "0.3", false);

        txt(ctx, 100, 250, cGreen, 14, "PERFORMANCE", false);
        txt(ctx, 80, 280, cWhite, 11, "N1", false);
        txt(ctx, 120, 280, cGreen, 13, n1L.toFixed(1) + "%", false);
        txt(ctx, 80, 300, cWhite, 11, "EGT", false);
        txt(ctx, 120, 300, cGreen, 13, Math.round(egtL) + "°C", false);

        txt(ctx, 340, 280, cWhite, 11, "N1", false);
        txt(ctx, 380, 280, cGreen, 13, n1R.toFixed(1) + "%", false);
        txt(ctx, 340, 300, cWhite, 11, "EGT", false);
        txt(ctx, 380, 300, cGreen, 13, Math.round(egtR) + "°C", false);
    }

    function drawBleed(ctx) {
        txt(ctx, 250, 30, cCyan, 18, "BLEED", true);
        txt(ctx, 50, 80, cGreen, 12, "ENG 1", false);
        
        var eng1Active = root.adc ? (root.adc.n1Left > 15.0) : true;
        var eng1Bleed = FlightDataManager ? FlightDataManager.engBleed1 : true;
        circle(ctx, 100, 120, 15, (eng1Active && eng1Bleed) ? cGreen : cAmber, 2);
        txt(ctx, 100, 125, (eng1Active && eng1Bleed) ? cGreen : cAmber, 11, (eng1Active && eng1Bleed) ? "ON" : "OFF", true);
        line(ctx, 115, 120, 200, 120, (eng1Active && eng1Bleed) ? cGreen : cAmber, 3);
        
        var apuActive = FlightDataManager ? FlightDataManager.apuActive : false;
        var apuBleed = FlightDataManager ? FlightDataManager.apuBleed : false;
        txt(ctx, 200, 80, (apuActive && apuBleed) ? cGreen : cCyan, 12, "APU", false);
        circle(ctx, 220, 120, 15, (apuActive && apuBleed) ? cGreen : cWhite, 2);
        txt(ctx, 220, 125, (apuActive && apuBleed) ? cGreen : cWhite, 11, (apuActive && apuBleed) ? "ON" : "OFF", true);
        
        var pack1Active = FlightDataManager ? FlightDataManager.pack1Active : true;
        var pack1On = FlightDataManager ? FlightDataManager.pack1On : true;
        var p1State = pack1Active && pack1On;
        txt(ctx, 50, 200, p1State ? cGreen : cAmber, 12, "PACK 1", false);
        strokeRect(ctx, 80, 210, 60, 30, p1State ? cGreen : cAmber, 2);
        txt(ctx, 110, 230, p1State ? cGreen : cAmber, 11, p1State ? "ON" : "OFF", true);
        
        var pack2Active = FlightDataManager ? FlightDataManager.pack2Active : true;
        var pack2On = FlightDataManager ? FlightDataManager.pack2On : true;
        var p2State = pack2Active && pack2On;
        txt(ctx, 350, 200, p2State ? cGreen : cAmber, 12, "PACK 2", false);
        strokeRect(ctx, 360, 210, 60, 30, p2State ? cGreen : cAmber, 2);
        txt(ctx, 390, 230, p2State ? cGreen : cAmber, 11, p2State ? "ON" : "OFF", true);
        
        var eng2Active = root.adc ? (root.adc.n1Right > 15.0) : true;
        var eng2Bleed = FlightDataManager ? FlightDataManager.engBleed2 : true;
        txt(ctx, 400, 80, (eng2Active && eng2Bleed) ? cGreen : cAmber, 12, "ENG 2", false);
        circle(ctx, 400, 120, 15, (eng2Active && eng2Bleed) ? cGreen : cAmber, 2);
        txt(ctx, 400, 125, (eng2Active && eng2Bleed) ? cGreen : cAmber, 11, (eng2Active && eng2Bleed) ? "ON" : "OFF", true);
    }

    function drawPress(ctx) {
        var cabAlt = FlightDataManager ? Math.round(FlightDataManager.cabinAltitude) : 6850;
        var cabVsi = FlightDataManager ? Math.round(FlightDataManager.cabinVsi) : -350;
        var deltaP = FlightDataManager ? FlightDataManager.cabinDeltaP.toFixed(1) : "7.8";
        var outflowPos = FlightDataManager ? Math.round(FlightDataManager.outflowValvePos * 100) : 45;
        var ditching = FlightDataManager ? FlightDataManager.ditchingOverride : false;

        txt(ctx, 250, 30, cCyan, 18, "PRESS", true);
        txt(ctx, 50, 80, cWhite, 12, "CAB ALT", false);
        txt(ctx, 150, 80, cabAlt > 8000 ? cAmber : cGreen, 16, cabAlt.toString(), false);
        txt(ctx, 220, 80, cWhite, 11, "FT", false);
        txt(ctx, 50, 120, cWhite, 12, "CAB V/S", false);
        txt(ctx, 150, 120, Math.abs(cabVsi) > 1000 ? cAmber : cGreen, 16, (cabVsi > 0 ? "+" : "") + cabVsi.toString(), false);
        txt(ctx, 220, 120, cWhite, 11, "FT/MIN", false);
        txt(ctx, 50, 160, cWhite, 12, "DELTA P", false);
        txt(ctx, 150, 160, cGreen, 16, deltaP, false);
        txt(ctx, 200, 160, cWhite, 11, "PSI", false);
        txt(ctx, 50, 220, cWhite, 12, "LDG ELEV", false);
        txt(ctx, 150, 220, cCyan, 14, "AUTO", false);
        txt(ctx, 300, 80, cWhite, 12, "OUTFLOW VLV", false);
        txt(ctx, 400, 80, ditching ? cAmber : cGreen, 14, ditching ? "CLOSED" : outflowPos + "%", false);
        if (ditching) {
            txt(ctx, 300, 120, cAmber, 12, "DITCHING ONLY", false);
        }
    }

    function drawElec(ctx) {
        txt(ctx, 250, 30, cCyan, 18, "ELEC", true);
        
        var gen1 = FlightDataManager ? FlightDataManager.gen1Active : true;
        var gen2 = FlightDataManager ? FlightDataManager.gen2Active : true;
        var ac1Volts = FlightDataManager ? Math.round(FlightDataManager.acBus1) : 115;
        var ac2Volts = FlightDataManager ? Math.round(FlightDataManager.acBus2) : 115;
        var acEssVolts = FlightDataManager ? Math.round(FlightDataManager.acEss) : 115;
        var bat1Volts = FlightDataManager ? FlightDataManager.bat1Voltage.toFixed(1) : "28.0";
        var bat2Volts = FlightDataManager ? FlightDataManager.bat2Voltage.toFixed(1) : "28.0";

        txt(ctx, 80, 80, gen1 ? cGreen : cAmber, 13, "GEN 1", false);
        txt(ctx, 70, 110, gen1 ? cWhite : cAmber, 11, gen1 ? ac1Volts + "V" : "0V", false);
        txt(ctx, 120, 110, gen1 ? cGreen : cAmber, 12, gen1 ? "400Hz" : "0Hz", false);
        
        txt(ctx, 380, 80, gen2 ? cGreen : cAmber, 13, "GEN 2", false);
        txt(ctx, 370, 110, gen2 ? cWhite : cAmber, 11, gen2 ? ac2Volts + "V" : "0V", false);
        txt(ctx, 420, 110, gen2 ? cGreen : cAmber, 12, gen2 ? "400Hz" : "0Hz", false);
        
        strokeRect(ctx, 180, 150, 140, 40, ac1Volts > 50 ? cGreen : cAmber, 2);
        txt(ctx, 250, 175, ac1Volts > 50 ? cGreen : cAmber, 13, "AC BUS 1", true);
        strokeRect(ctx, 180, 210, 140, 40, ac2Volts > 50 ? cGreen : cAmber, 2);
        txt(ctx, 250, 235, ac2Volts > 50 ? cGreen : cAmber, 13, "AC BUS 2", true);
        
        txt(ctx, 50, 300, bat1Volts > 20 ? cGreen : cAmber, 12, "BAT 1", false);
        txt(ctx, 50, 320, bat1Volts > 20 ? cGreen : cAmber, 11, bat1Volts + "V", false);
        txt(ctx, 400, 300, bat2Volts > 20 ? cGreen : cAmber, 12, "BAT 2", false);
        txt(ctx, 400, 320, bat2Volts > 20 ? cGreen : cAmber, 11, bat2Volts + "V", false);
    }

    function drawHyd(ctx) {
        txt(ctx, 250, 30, cCyan, 18, "HYD", true);
        
        var greenPress = FlightDataManager ? Math.round(FlightDataManager.hydraulicGreenPressure) : 3000;
        var bluePress = FlightDataManager ? Math.round(FlightDataManager.hydraulicBluePressure) : 3000;
        var yellowPress = FlightDataManager ? Math.round(FlightDataManager.hydraulicYellowPressure) : 3000;

        var hydG = greenPress > 2000;
        var hydB = bluePress > 2000;
        var hydY = yellowPress > 2000;

        txt(ctx, 80, 80, hydG ? cGreen : cAmber, 14, "GREEN", false);
        txt(ctx, 60, 110, cWhite, 11, "PSI", false);
        txt(ctx, 100, 110, hydG ? cGreen : cAmber, 13, greenPress.toString(), false);
        txt(ctx, 60, 135, cWhite, 11, "QTY", false);
        txt(ctx, 100, 135, hydG ? cGreen : cAmber, 13, hydG ? "12.5" : "0.0", false);
        
        txt(ctx, 220, 80, hydB ? cCyan : cAmber, 14, "BLUE", false);
        txt(ctx, 200, 110, cWhite, 11, "PSI", false);
        txt(ctx, 240, 110, hydB ? cCyan : cAmber, 13, bluePress.toString(), false);
        txt(ctx, 200, 135, cWhite, 11, "QTY", false);
        txt(ctx, 240, 135, hydB ? cCyan : cAmber, 13, hydB ? "6.0" : "0.0", false);
        
        txt(ctx, 360, 80, hydY ? cGreen : cAmber, 14, "YELLOW", false);
        txt(ctx, 340, 110, cWhite, 11, "PSI", false);
        txt(ctx, 390, 110, hydY ? cGreen : cAmber, 13, yellowPress.toString(), false);
        txt(ctx, 340, 135, cWhite, 11, "QTY", false);
        txt(ctx, 390, 135, hydY ? cGreen : cAmber, 13, hydY ? "12.5" : "0.0", false);
        
        txt(ctx, 200, 200, cGreen, 12, "PTU", false);
        txt(ctx, 250, 200, cGreen, 11, "AVAIL", false);
    }

    function drawFuel(ctx) {
        txt(ctx, 250, 30, cCyan, 18, "FUEL", true);
        
        var fLOuter = FlightDataManager ? FlightDataManager.fuelLOuter : 800;
        var fLInner = FlightDataManager ? FlightDataManager.fuelLInner : 5400;
        var fCentre = FlightDataManager ? FlightDataManager.fuelCentre : 6200;
        var fRInner = FlightDataManager ? FlightDataManager.fuelRInner : 5400;
        var fROuter = FlightDataManager ? FlightDataManager.fuelROuter : 800;
        
        var leftFuel = fLOuter + fLInner;
        var rightFuel = fROuter + fRInner;
        var totalFuel = leftFuel + fCentre + rightFuel;
        
        // Draw Left Tank Box
        strokeRect(ctx, 50, 80, 80, 120, cGreen, 2);
        var leftPct = leftFuel / 6200.0;
        fillRect(ctx, 50, 200 - 120 * leftPct, 80, 120 * leftPct, cGreen, 0.3);
        txt(ctx, 90, 60, cGreen, 12, "LEFT", true);
        txt(ctx, 90, 230, cGreen, 14, leftFuel.toString(), true);
        
        // Draw Center Tank Box
        strokeRect(ctx, 210, 80, 80, 120, cGreen, 2);
        var centerPct = fCentre / 6200.0;
        fillRect(ctx, 210, 200 - 120 * centerPct, 80, 120 * centerPct, cGreen, 0.3);
        txt(ctx, 250, 60, cGreen, 12, "CENTER", true);
        txt(ctx, 250, 230, cGreen, 14, fCentre.toString(), true);
        
        // Draw Right Tank Box
        strokeRect(ctx, 370, 80, 80, 120, cGreen, 2);
        var rightPct = rightFuel / 6200.0;
        fillRect(ctx, 370, 200 - 120 * rightPct, 80, 120 * rightPct, cGreen, 0.3);
        txt(ctx, 410, 60, cGreen, 12, "RIGHT", true);
        txt(ctx, 410, 230, cGreen, 14, rightFuel.toString(), true);
        
        txt(ctx, 250, 280, cWhite, 12, "TOTAL", true);
        txt(ctx, 250, 310, cGreen, 16, totalFuel.toString() + " KG", true);
    }

    function drawApu(ctx) {
        txt(ctx, 250, 30, cCyan, 18, "APU", true);
        txt(ctx, 150, 100, cWhite, 12, "N", false);
        txt(ctx, 250, 100, cGreen, 16, "100%", false);
        txt(ctx, 150, 140, cWhite, 12, "EGT", false);
        txt(ctx, 250, 140, cGreen, 16, "620°C", false);
        txt(ctx, 150, 180, cWhite, 12, "FLAP", false);
        txt(ctx, 250, 180, cGreen, 14, "OPEN", false);
        txt(ctx, 150, 220, cWhite, 12, "BLEED", false);
        txt(ctx, 250, 220, cGreen, 14, "ON", false);
    }

    function drawCond(ctx) {
        txt(ctx, 250, 30, cCyan, 18, "COND", true);
        txt(ctx, 100, 80, cWhite, 12, "CKPT", false);
        txt(ctx, 180, 80, cGreen, 14, "24°C", false);
        txt(ctx, 100, 120, cWhite, 12, "FWD", false);
        txt(ctx, 180, 120, cGreen, 14, "23°C", false);
        txt(ctx, 100, 160, cWhite, 12, "AFT", false);
        txt(ctx, 180, 160, cGreen, 14, "24°C", false);
    }

    function drawDoor(ctx) {
        txt(ctx, 250, 30, cCyan, 18, "DOOR", true);
        strokeRect(ctx, 150, 100, 200, 200, cWhite, 2);
        txt(ctx, 120, 140, cGreen, 11, "1L", false);
        fillRect(ctx, 145, 130, 10, 20, cGreen);
        txt(ctx, 360, 140, cGreen, 11, "1R", false);
        fillRect(ctx, 345, 130, 10, 20, cGreen);
        txt(ctx, 120, 260, cGreen, 11, "2L", false);
        fillRect(ctx, 145, 250, 10, 20, cGreen);
        txt(ctx, 360, 260, cGreen, 11, "2R", false);
        fillRect(ctx, 345, 250, 10, 20, cGreen);
        txt(ctx, 250, 340, cGreen, 11, "ALL DOORS CLOSED", true);
    }

    function drawWheel(ctx) {
        txt(ctx, 250, 30, cCyan, 18, "WHEEL", true);
        txt(ctx, 250, 80, cGreen, 12, "NOSE", true);
        circle(ctx, 250, 110, 20, cGreen, 2);
        txt(ctx, 250, 150, cGreen, 11, "UP", true);
        txt(ctx, 150, 220, cGreen, 12, "L MAIN", true);
        circle(ctx, 150, 250, 20, cGreen, 2);
        txt(ctx, 150, 290, cGreen, 11, "UP", true);
        txt(ctx, 350, 220, cGreen, 12, "R MAIN", true);
        circle(ctx, 350, 250, 20, cGreen, 2);
        txt(ctx, 350, 290, cGreen, 11, "UP", true);
    }

    function drawFctl(ctx) {
        txt(ctx, 250, 30, cCyan, 18, "F/CTL", true);
        txt(ctx, 100, 80, cGreen, 12, "ELAC 1", false);
        txt(ctx, 200, 80, cGreen, 11, "ON", false);
        txt(ctx, 100, 110, cGreen, 12, "ELAC 2", false);
        txt(ctx, 200, 110, cGreen, 11, "ON", false);
        txt(ctx, 100, 150, cGreen, 12, "SEC 1", false);
        txt(ctx, 200, 150, cGreen, 11, "ON", false);
        txt(ctx, 100, 180, cGreen, 12, "SEC 2", false);
        txt(ctx, 200, 180, cGreen, 11, "ON", false);
        txt(ctx, 100, 210, cGreen, 12, "SEC 3", false);
        txt(ctx, 200, 210, cGreen, 11, "ON", false);
        txt(ctx, 300, 80, cGreen, 12, "FAC 1", false);
        txt(ctx, 400, 80, cGreen, 11, "ON", false);
        txt(ctx, 300, 110, cGreen, 12, "FAC 2", false);
        txt(ctx, 400, 110, cGreen, 11, "ON", false);
    }

    function drawSts(ctx) {
        txt(ctx, 250, 30, cCyan, 18, "STATUS", true);
        txt(ctx, 50, 80, cGreen, 12, "ALL SYSTEMS NORMAL", false);
        txt(ctx, 50, 140, cWhite, 11, "LAST LEG:", false);
        txt(ctx, 50, 165, cCyan, 11, "LFPG - EGLL", false);
        txt(ctx, 50, 185, cCyan, 11, "FLT TIME: 01:15", false);
    }
}
