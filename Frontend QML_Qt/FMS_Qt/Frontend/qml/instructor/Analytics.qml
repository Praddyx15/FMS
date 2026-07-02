import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCharts 2.15

// Analytics — post-flight telemetry charts (altitude, speed, VSI over time)
Rectangle {
    id: root
    property var adc
    color: "#0d1017"
    radius: 6
    border.color: "#2a2d35"

    // Buffer for recorded telemetry (1 Hz)
    property var altBuffer:  []
    property var iasBuffer:  []
    property var vsiBuffer:  []
    property int maxPoints:  300  // 5 minutes at 1Hz

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            if (!root.adc) return
            // Append new values
            var nowAlt = root.adc.altitude
            var nowIas = root.adc.ias
            var nowVsi = root.adc.vsi

            root.altBuffer.push(nowAlt)
            root.iasBuffer.push(nowIas)
            root.vsiBuffer.push(nowVsi)

            // Trim to max
            if (root.altBuffer.length > root.maxPoints) root.altBuffer.shift()
            if (root.iasBuffer.length > root.maxPoints) root.iasBuffer.shift()
            if (root.vsiBuffer.length > root.maxPoints) root.vsiBuffer.shift()

            // Update series
            altSeries.clear()
            iasSeries.clear()
            vsiSeries.clear()

            for (var i = 0; i < root.altBuffer.length; i++) {
                altSeries.append(i, root.altBuffer[i])
                iasSeries.append(i, root.iasBuffer[i])
                vsiSeries.append(i, root.vsiBuffer[i])
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 12; spacing: 8

        Label { text: "📊  FLIGHT ANALYTICS"; color: "#00e5ff"; font.pixelSize: 14; font.bold: true; font.family: "Consolas" }

        // Stats strip
        RowLayout {
            spacing: 16
            Repeater {
                model: [
                    { label: "ALT",    value: () => root.adc ? Math.round(root.adc.altitude) + " ft" : "---", col: "#00e5ff" },
                    { label: "IAS",    value: () => root.adc ? Math.round(root.adc.ias) + " kt"      : "---", col: "#00e676" },
                    { label: "MACH",   value: () => root.adc ? "M " + root.adc.mach.toFixed(3)       : "---", col: "#ffab40" },
                    { label: "HDG",    value: () => root.adc ? Math.round(root.adc.heading) + "°"    : "---", col: "#b0bec5" },
                    { label: "VSI",    value: () => root.adc ? (root.adc.vsi >= 0 ? "+" : "") + Math.round(root.adc.vsi) + " fpm" : "---",
                      col: root.adc && root.adc.vsi !== 0 ? (root.adc.vsi > 0 ? "#00e676" : "#ff5252") : "#546e7a" },
                    { label: "GS",     value: () => root.adc ? Math.round(root.adc.groundSpeed) + " kt" : "---", col: "#78909c" },
                ]
                Rectangle {
                    Layout.preferredWidth: 110; height: 44; radius: 6
                    color: "#12141a"; border.color: "#2a2d35"
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 2
                        Text { text: modelData.label; color: "#546e7a"; font.pixelSize: 8; font.family: "Consolas"; Layout.alignment: Qt.AlignHCenter }
                        Text { text: modelData.value(); color: modelData.col; font.pixelSize: 13; font.bold: true; font.family: "Consolas"; Layout.alignment: Qt.AlignHCenter }
                    }
                }
            }
        }

        // Charts
        TabBar {
            id: chartTab
            Layout.fillWidth: true; height: 28
            background: Rectangle { color: "#12141a"; border.color: "#2a2d35" }
            Repeater {
                model: ["ALTITUDE / TIME", "AIRSPEED / TIME", "VSI / TIME"]
                TabButton {
                    text: modelData; font.pixelSize: 9; font.family: "Consolas"
                    width: implicitWidth
                    background: Rectangle {
                        color: parent.checked ? "#1a2030" : "#12141a"
                        border.width: parent.checked ? 2 : 0
                        border.color: "#00e5ff"
                    }
                    contentItem: Text { text: parent.text; color: parent.checked ? "#00e5ff" : "#546e7a"; font: parent.font; horizontalAlignment: Text.AlignHCenter }
                }
            }
        }

        StackLayout {
            currentIndex: chartTab.currentIndex
            Layout.fillWidth: true; Layout.fillHeight: true

            // Altitude chart
            ChartView {
                antialiasing: true; theme: ChartView.ChartThemeDark
                backgroundColor: "#0a0c10"; plotAreaColor: "#0a0c10"
                legend.visible: false

                ValueAxis { id: axAltX; labelFormat: "%d s"; labelsColor: "#546e7a"; gridLineColor: "#1a2030"; min: 0; max: root.maxPoints }
                ValueAxis { id: axAltY; labelFormat: "%d ft"; labelsColor: "#00e5ff"; gridLineColor: "#1a2030"; min: 0; max: 45000 }

                LineSeries {
                    id: altSeries
                    axisX: axAltX; axisY: axAltY
                    color: "#00e5ff"; width: 2
                }
            }

            // IAS chart
            ChartView {
                antialiasing: true; theme: ChartView.ChartThemeDark
                backgroundColor: "#0a0c10"; plotAreaColor: "#0a0c10"
                legend.visible: false

                ValueAxis { id: axIasX; labelFormat: "%d s"; labelsColor: "#546e7a"; gridLineColor: "#1a2030"; min: 0; max: root.maxPoints }
                ValueAxis { id: axIasY; labelFormat: "%d kt"; labelsColor: "#00e676"; gridLineColor: "#1a2030"; min: 0; max: 420 }

                LineSeries {
                    id: iasSeries
                    axisX: axIasX; axisY: axIasY
                    color: "#00e676"; width: 2
                }
            }

            // VSI chart
            ChartView {
                antialiasing: true; theme: ChartView.ChartThemeDark
                backgroundColor: "#0a0c10"; plotAreaColor: "#0a0c10"
                legend.visible: false

                ValueAxis { id: axVsiX; labelFormat: "%d s"; labelsColor: "#546e7a"; gridLineColor: "#1a2030"; min: 0; max: root.maxPoints }
                ValueAxis { id: axVsiY; labelFormat: "%d fpm"; labelsColor: "#ff9800"; gridLineColor: "#1a2030"; min: -6000; max: 6000 }

                LineSeries {
                    id: vsiSeries
                    axisX: axVsiX; axisY: axVsiY
                    color: "#ff9800"; width: 2
                }
            }
        }
    }
}
