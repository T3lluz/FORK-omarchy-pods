pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami

// Canvas-drawn metric icon. We render shapes directly in QML so the
// color binding is instant and there's no dependency on Kirigami.Icon's
// SVG mask recoloring (which is unreliable for non-theme icons and was
// rendering our CPU icon as a solid white square).
//
// Supported kinds: "cpu" "ram" "disk" "down" "up" "temp"
//                  "server" "refresh" "dashboard" "reboot"
//                  "chart" "network" "status" "text" "dots"
//                  "bars" "both" "clock" "battery" "buds" "case"
//                  "headset" "noise" "ear" "hide" "path"
//                  "leftpod" "rightpod"
Item {
    id: root

    property string kind: "cpu"
    property color color: Kirigami.Theme.textColor
    property bool charging: false
    property color boltColor: Kirigami.Theme.textColor
    property real strokeWidth: 1.6
    // Fraction of the box the 24×24 artwork fills. Power-Deck's glyphs draw
    // their SVG art inset inside the box (~18 of 24 units, leaving padding),
    // so our edge-to-edge glyphs are scaled down to the same footprint and
    // read at the same visual size as Power-Deck instead of bigger.
    property real contentScale: 0.8

    implicitWidth: Kirigami.Units.iconSizes.small
    implicitHeight: Kirigami.Units.iconSizes.small

    Canvas {
        id: cv
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            // draw inside a normalized 24×24 box, inset by contentScale so
            // the artwork carries the same padding as Power-Deck's SVGs
            var scale = Math.min(width, height) / 24 * root.contentScale
            ctx.translate((width  - 24 * scale) / 2,
                          (height - 24 * scale) / 2)
            ctx.scale(scale, scale)

            ctx.strokeStyle = root.color
            ctx.fillStyle   = root.color
            ctx.lineWidth   = root.strokeWidth
            ctx.lineCap     = "round"
            ctx.lineJoin    = "round"

            switch (root.kind) {
            case "cpu":      drawCpu(ctx);      break
            case "ram":      drawRam(ctx);      break
            case "disk":     drawDisk(ctx);     break
            case "down":     drawDown(ctx);     break
            case "up":       drawUp(ctx);       break
            case "temp":     drawTemp(ctx);     break
            case "server":   drawServer(ctx);   break
            case "refresh":  drawRefresh(ctx);  break
            case "dashboard":drawDashboard(ctx);break
            case "reboot":   drawReboot(ctx);   break
            case "chart":    drawChart(ctx);    break
            case "network":  drawNetwork(ctx);  break
            case "status":   drawStatus(ctx);   break
            case "text":     drawText(ctx);     break
            case "dots":     drawDots(ctx);     break
            case "bars":     drawBars(ctx);     break
            case "both":     drawBoth(ctx);     break
            case "clock":    drawClock(ctx);    break
            case "battery":  drawBattery(ctx);  break
            case "buds":     drawBuds(ctx);     break
            case "leftpod":  drawLeftPod(ctx);  break
            case "rightpod": drawRightPod(ctx); break
            case "case":     drawCase(ctx);     break
            case "headset":  drawHeadset(ctx);  break
            case "noise":    drawNoise(ctx);    break
            case "ear":      drawEar(ctx);      break
            case "hide":     drawHide(ctx);     break
            case "path":     drawPath(ctx);     break
            }
        }

        // ---- shape primitives -----------------------------------------
        function roundRect(ctx, x, y, w, h, r) {
            ctx.beginPath()
            ctx.moveTo(x + r, y)
            ctx.lineTo(x + w - r, y)
            ctx.quadraticCurveTo(x + w, y, x + w, y + r)
            ctx.lineTo(x + w, y + h - r)
            ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
            ctx.lineTo(x + r, y + h)
            ctx.quadraticCurveTo(x, y + h, x, y + h - r)
            ctx.lineTo(x, y + r)
            ctx.quadraticCurveTo(x, y, x + r, y)
            ctx.closePath()
        }

        // ---- icons -----------------------------------------------------
        function drawCpu(ctx) {
            // outer chip body (stroked square)
            roundRect(ctx, 5, 5, 14, 14, 1.8)
            ctx.stroke()
            // inner core (filled square)
            roundRect(ctx, 9, 9, 6, 6, 1)
            ctx.fill()
            // 2 pins on each of the 4 sides — readable at 16px
            ctx.lineWidth = 1.8
            var pins = [9, 15]
            for (var i = 0; i < pins.length; i++) {
                var p = pins[i]
                ctx.beginPath(); ctx.moveTo(p, 5);  ctx.lineTo(p, 2.5);  ctx.stroke()
                ctx.beginPath(); ctx.moveTo(p, 19); ctx.lineTo(p, 21.5); ctx.stroke()
                ctx.beginPath(); ctx.moveTo(5, p);  ctx.lineTo(2.5, p);  ctx.stroke()
                ctx.beginPath(); ctx.moveTo(19, p); ctx.lineTo(21.5, p); ctx.stroke()
            }
        }

        function drawRam(ctx) {
            // outer rect (stroked)
            roundRect(ctx, 2, 7, 20, 10, 1.4)
            ctx.stroke()
            // memory chips on the top half
            for (var i = 0; i < 4; i++) {
                var x = 4.5 + i * 4
                ctx.fillRect(x, 9.2, 2.8, 3.6)
            }
            // pins on the bottom edge
            ctx.lineWidth = 1.2
            for (var j = 0; j < 4; j++) {
                var px = 5.5 + j * 4
                ctx.beginPath(); ctx.moveTo(px, 17); ctx.lineTo(px, 19); ctx.stroke()
            }
        }

        function drawDisk(ctx) {
            ctx.lineWidth = root.strokeWidth
            // top ellipse, drawn with two bezier curves
            ctx.beginPath()
            ctx.moveTo(4, 6)
            ctx.bezierCurveTo(4, 4, 20, 4, 20, 6)
            ctx.bezierCurveTo(20, 8, 4, 8, 4, 6)
            ctx.stroke()
            // body sides
            ctx.beginPath()
            ctx.moveTo(4, 6);  ctx.lineTo(4, 18)
            ctx.moveTo(20, 6); ctx.lineTo(20, 18)
            ctx.stroke()
            // bottom curve
            ctx.beginPath()
            ctx.moveTo(4, 18)
            ctx.bezierCurveTo(4, 20, 20, 20, 20, 18)
            ctx.stroke()
            // middle dividers
            ctx.beginPath()
            ctx.moveTo(4, 11)
            ctx.bezierCurveTo(4, 13, 20, 13, 20, 11)
            ctx.moveTo(4, 15)
            ctx.bezierCurveTo(4, 17, 20, 17, 20, 15)
            ctx.stroke()
        }

        function drawDown(ctx) {
            // shaft
            ctx.lineWidth = 2.4
            ctx.beginPath(); ctx.moveTo(12, 4); ctx.lineTo(12, 16); ctx.stroke()
            // arrow head (filled triangle)
            ctx.beginPath()
            ctx.moveTo(12, 19)
            ctx.lineTo(7, 13)
            ctx.lineTo(17, 13)
            ctx.closePath()
            ctx.fill()
            // baseline
            ctx.lineWidth = 1.8
            ctx.beginPath(); ctx.moveTo(5, 21.5); ctx.lineTo(19, 21.5); ctx.stroke()
        }

        function drawUp(ctx) {
            // baseline (top)
            ctx.lineWidth = 1.8
            ctx.beginPath(); ctx.moveTo(5, 2.5); ctx.lineTo(19, 2.5); ctx.stroke()
            // arrow head (filled triangle, points up)
            ctx.beginPath()
            ctx.moveTo(12, 5)
            ctx.lineTo(7, 11)
            ctx.lineTo(17, 11)
            ctx.closePath()
            ctx.fill()
            // shaft
            ctx.lineWidth = 2.4
            ctx.beginPath(); ctx.moveTo(12, 8); ctx.lineTo(12, 20); ctx.stroke()
        }

        function drawServer(ctx) {
            roundRect(ctx, 3, 3,  18, 7, 1.4); ctx.stroke()
            roundRect(ctx, 3, 14, 18, 7, 1.4); ctx.stroke()
            ctx.beginPath(); ctx.arc(6.5, 6.5, 0.9, 0, Math.PI * 2); ctx.fill()
            ctx.beginPath(); ctx.arc(6.5, 17.5, 0.9, 0, Math.PI * 2); ctx.fill()
            ctx.fillRect(9, 5.8,  8, 1.4)
            ctx.fillRect(9, 16.8, 8, 1.4)
        }

        function drawRefresh(ctx) {
            ctx.lineWidth = 2
            // arc from 0° (right) sweeping clockwise 270° to up (-π/2)
            ctx.beginPath()
            ctx.arc(12, 12, 7.5, 0, Math.PI * 1.5)
            ctx.stroke()
            // arrow head at the open end (top of circle)
            ctx.beginPath()
            ctx.moveTo(12, 4.5)
            ctx.lineTo(8.5, 7.5)
            ctx.lineTo(12, 9.5)
            ctx.closePath()
            ctx.fill()
        }

        function drawDashboard(ctx) {
            roundRect(ctx, 3,  3,  8,  8,  1.2); ctx.fill()
            roundRect(ctx, 13, 3,  8,  5,  1.2); ctx.fill()
            roundRect(ctx, 13, 10, 8,  11, 1.2); ctx.fill()
            roundRect(ctx, 3,  13, 8,  8,  1.2); ctx.fill()
        }

        function drawReboot(ctx) {
            ctx.lineWidth = 2
            ctx.beginPath(); ctx.moveTo(12, 3); ctx.lineTo(12, 12); ctx.stroke()
            ctx.beginPath()
            ctx.arc(12, 13, 8, -Math.PI * 0.85, Math.PI * 1.85)
            ctx.stroke()
        }

        function drawChart(ctx) {
            // L-shaped axis
            ctx.lineWidth = 1.6
            ctx.beginPath()
            ctx.moveTo(4, 4); ctx.lineTo(4, 20); ctx.lineTo(20, 20)
            ctx.stroke()
            // sparkline trend
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.moveTo(6, 16); ctx.lineTo(10, 11); ctx.lineTo(13, 14); ctx.lineTo(20, 6)
            ctx.stroke()
            // dot at the leading edge
            ctx.beginPath(); ctx.arc(20, 6, 1.7, 0, Math.PI * 2); ctx.fill()
        }

        function drawNetwork(ctx) {
            ctx.lineWidth = root.strokeWidth
            // globe outline
            ctx.beginPath(); ctx.arc(12, 12, 8.5, 0, Math.PI * 2); ctx.stroke()
            // equator
            ctx.beginPath(); ctx.moveTo(3.5, 12); ctx.lineTo(20.5, 12); ctx.stroke()
            // meridians
            ctx.beginPath()
            ctx.moveTo(12, 3.5); ctx.bezierCurveTo(6, 7, 6, 17, 12, 20.5)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(12, 3.5); ctx.bezierCurveTo(18, 7, 18, 17, 12, 20.5)
            ctx.stroke()
        }

        function drawTemp(ctx) {
            ctx.lineWidth = 1.8
            ctx.beginPath()
            ctx.arc(12, 17.2, 4.2, Math.PI * 0.78, Math.PI * 0.22)
            ctx.stroke()
            roundRect(ctx, 9.4, 3.2, 5.2, 12.2, 2.4)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(12, 17.2, 2.3, 0, Math.PI * 2)
            ctx.fill()
            ctx.fillRect(11.15, 8.2, 1.7, 7.2)
        }

        function drawStatus(ctx) {
            ctx.beginPath()
            ctx.arc(12, 12, 7.4, 0, Math.PI * 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(12, 12, 3.5, 0, Math.PI * 2)
            ctx.fill()
        }

        function drawText(ctx) {
            ctx.beginPath(); ctx.moveTo(5, 7);  ctx.lineTo(19, 7);  ctx.stroke()
            ctx.beginPath(); ctx.moveTo(5, 12); ctx.lineTo(16, 12); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(5, 17); ctx.lineTo(13, 17); ctx.stroke()
        }

        function drawDots(ctx) {
            for (var i = 0; i < 3; i++) {
                ctx.beginPath()
                ctx.arc(6 + i * 6, 12, 1.7, 0, Math.PI * 2)
                ctx.fill()
            }
        }

        function drawBars(ctx) {
            roundRect(ctx, 4.5, 13, 4, 6.5, 0.8)
            ctx.fill()
            roundRect(ctx, 10, 7.5, 4, 12, 0.8)
            ctx.fill()
            roundRect(ctx, 15.5, 10, 4, 9.5, 0.8)
            ctx.fill()
        }

        function drawBoth(ctx) {
            roundRect(ctx, 3.5, 5.5, 7.5, 7.5, 1.4)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(13.2, 7)
            ctx.lineTo(20.5, 7)
            ctx.moveTo(13.2, 11)
            ctx.lineTo(18.5, 11)
            ctx.moveTo(3.5, 16.5)
            ctx.lineTo(20.5, 16.5)
            ctx.moveTo(3.5, 19.5)
            ctx.lineTo(15, 19.5)
            ctx.stroke()
        }

        function drawClock(ctx) {
            ctx.beginPath()
            ctx.arc(12, 12, 8, 0, Math.PI * 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(12, 12)
            ctx.lineTo(12, 7.2)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(12, 12)
            ctx.lineTo(16.2, 13.6)
            ctx.stroke()
        }

        function drawBattery(ctx) {
            if (root.charging) {
                roundRect(ctx, 2.2, 7, 14.4, 10, 2.2)
                ctx.stroke()
                roundRect(ctx, 4.2, 9.4, 7.4, 5.2, 1.3)
                ctx.fill()
                ctx.beginPath()
                ctx.moveTo(18.4, 5.2)
                ctx.lineTo(14.6, 12.6)
                ctx.lineTo(17.6, 12.6)
                ctx.lineTo(16.8, 19)
                ctx.lineTo(21.4, 10.4)
                ctx.lineTo(18.2, 10.4)
                ctx.closePath()
                ctx.fill()
                return
            }
            roundRect(ctx, 2.5, 7, 16.5, 10, 2.2)
            ctx.stroke()
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.moveTo(21, 10.5)
            ctx.lineTo(21, 13.5)
            ctx.stroke()
            roundRect(ctx, 4.9, 9.4, 8.7, 5.2, 1.3)
            ctx.fill()
        }

        function drawBuds(ctx) {
            ctx.beginPath()
            ctx.arc(7.2, 9.2, 3.4, 0, Math.PI * 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(7.2, 12.4)
            ctx.lineTo(7.2, 20.2)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(16.8, 9.2, 3.4, 0, Math.PI * 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(16.8, 12.4)
            ctx.lineTo(16.8, 20.2)
            ctx.stroke()
        }

        function drawPod(ctx, cx) {
            ctx.beginPath()
            ctx.arc(cx, 8.2, 4.8, 0, Math.PI * 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(cx, 8.2, 1.8, 0, Math.PI * 2)
            ctx.fill()
            ctx.lineWidth = 2.2
            ctx.beginPath()
            ctx.moveTo(cx, 12.8)
            ctx.lineTo(cx, 20.4)
            ctx.stroke()
            ctx.lineWidth = root.strokeWidth
            ctx.beginPath()
            ctx.arc(cx, 20.5, 1.15, 0, Math.PI * 2)
            ctx.fill()
            if (root.charging)
                drawMiniBolt(ctx)
        }

        function drawLeftPod(ctx) {
            drawPod(ctx, 10.2)
        }

        function drawRightPod(ctx) {
            drawPod(ctx, 13.8)
        }

        function drawMiniBolt(ctx) {
            ctx.fillStyle = root.boltColor
            ctx.beginPath()
            ctx.moveTo(18.6, 3.2)
            ctx.lineTo(15.2, 10.6)
            ctx.lineTo(17.6, 10.6)
            ctx.lineTo(16.4, 17.4)
            ctx.lineTo(21.2, 8.8)
            ctx.lineTo(18.4, 8.8)
            ctx.closePath()
            ctx.fill()
            ctx.fillStyle = root.color
        }

        function drawCase(ctx) {
            roundRect(ctx, 5, 4, 14, 16, 4)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(5, 11.5)
            ctx.lineTo(19, 11.5)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(12, 11.5, 1.3, 0, Math.PI * 2)
            ctx.fill()
        }

        function drawHeadset(ctx) {
            ctx.beginPath()
            ctx.arc(12, 11, 7.4, Math.PI * 1.05, Math.PI * 1.95)
            ctx.stroke()
            roundRect(ctx, 3.2, 10.5, 4.2, 8.2, 1.6)
            ctx.stroke()
            roundRect(ctx, 16.6, 10.5, 4.2, 8.2, 1.6)
            ctx.stroke()
        }

        function drawNoise(ctx) {
            ctx.beginPath()
            ctx.arc(8, 12, 3.2, 0, Math.PI * 2)
            ctx.fill()
            ctx.beginPath()
            ctx.arc(8, 12, 6.2, -Math.PI * 0.45, Math.PI * 0.45)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(8, 12, 9.4, -Math.PI * 0.45, Math.PI * 0.45)
            ctx.stroke()
        }

        function drawEar(ctx) {
            ctx.beginPath()
            ctx.moveTo(14.5, 5)
            ctx.bezierCurveTo(8, 4, 5.5, 9, 7.2, 13)
            ctx.bezierCurveTo(8.6, 16.5, 12.5, 18, 14.2, 20.5)
            ctx.bezierCurveTo(16.8, 16.2, 20, 13.5, 16.5, 8.5)
            ctx.bezierCurveTo(15.6, 6.4, 16, 5.2, 14.5, 5)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(12.6, 11.4, 1.5, 0, Math.PI * 2)
            ctx.fill()
        }

        function drawHide(ctx) {
            ctx.beginPath()
            ctx.arc(12, 12, 7.6, 0, Math.PI * 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(6.2, 17.8)
            ctx.lineTo(17.8, 6.2)
            ctx.stroke()
        }

        function drawPath(ctx) {
            roundRect(ctx, 3, 5, 18, 14, 1.6)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(3, 9)
            ctx.lineTo(21, 9)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(6.5, 13)
            ctx.lineTo(17.5, 13)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(6.5, 16)
            ctx.lineTo(13.5, 16)
            ctx.stroke()
        }
    }

    onColorChanged: cv.requestPaint()
    onKindChanged: cv.requestPaint()
    onChargingChanged: cv.requestPaint()
    onBoltColorChanged: cv.requestPaint()
    onContentScaleChanged: cv.requestPaint()
    onWidthChanged: cv.requestPaint()
    onHeightChanged: cv.requestPaint()
}
