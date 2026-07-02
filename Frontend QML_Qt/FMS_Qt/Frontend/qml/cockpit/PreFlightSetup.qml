import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// PreFlightSetup — Glassmorphism-style dashboard for initializing flight parameters
Rectangle {
    id: root
    color: "#0a0b0d"

    signal flightInitialized()

    // Load initial values from FlightDataManager
    Component.onCompleted: {
        flightNumInput.text = FlightDataManager.flightNumber
        depInput.text = FlightDataManager.departure
        destInput.text = FlightDataManager.destination
        altnInput.text = FlightDataManager.alternate
        crzAltInput.text = FlightDataManager.cruiseAltitude.toString()
        zfwInput.text = FlightDataManager.zeroFuelWeight.toString()
        blockFuelInput.text = FlightDataManager.blockFuel.toString()
        costIndexInput.text = FlightDataManager.costIndex.toString()
    }

    // Background decoration (vibrant blue/cyan ambient glows)
    Rectangle {
        width: 600; height: 600; radius: 300
        x: -100; y: -100
        color: Qt.rgba(0.0, 0.5, 1.0, 0.08)
    }
    Rectangle {
        width: 500; height: 500; radius: 250
        x: parent.width - 400; y: parent.height - 400
        color: Qt.rgba(0.0, 0.8, 0.8, 0.05)
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: mainContainer.implicitHeight + 100

        ColumnLayout {
            id: mainContainer
            width: Math.min(parent.width - 40, 800)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 60
            spacing: 24

            // Header Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Label {
                    text: "✈  A320neo FLIGHT SETUP"
                    color: Theme.cyan
                    font.pixelSize: 28; font.bold: true; font.family: "Consolas"
                    Layout.alignment: Qt.AlignHCenter
                }
                Label {
                    text: "Configure Pre-Flight Initialization Parameters below before starting the simulator."
                    color: "#90a4ae"
                    font.pixelSize: 13; font.family: "Consolas"
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // Glassmorphism Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: formGrid.implicitHeight + 40
                color: Qt.rgba(255, 255, 255, 0.03)
                radius: 12
                border.color: Qt.rgba(255, 255, 255, 0.08)
                border.width: 1

                GridLayout {
                    id: formGrid
                    anchors.fill: parent
                    anchors.margins: 20
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 16

                    // Row 1: Flight ID
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Label { text: "Flight Number"; color: "#b0bec5"; font.pixelSize: 11; font.bold: true }
                        TextField {
                            id: flightNumInput
                            Layout.fillWidth: true
                            placeholderText: "e.g. LH1234"
                            selectByMouse: true
                            color: Theme.white
                            background: Rectangle { color: "#161920"; border.color: parent.activeFocus ? Theme.cyan : "#37474f"; border.width: 1; radius: 4 }
                        }
                    }

                    // Row 2: Cost Index
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Label { text: "Cost Index (0-99)"; color: "#b0bec5"; font.pixelSize: 11; font.bold: true }
                        TextField {
                            id: costIndexInput
                            Layout.fillWidth: true
                            placeholderText: "e.g. 35"
                            selectByMouse: true
                            validator: IntValidator { bottom: 0; top: 99 }
                            color: Theme.white
                            background: Rectangle { color: "#161920"; border.color: parent.activeFocus ? Theme.cyan : "#37474f"; border.width: 1; radius: 4 }
                        }
                    }

                    // Row 3: Departure ICAO
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Label { text: "Departure Airport (ICAO)"; color: "#b0bec5"; font.pixelSize: 11; font.bold: true }
                        TextField {
                            id: depInput
                            Layout.fillWidth: true
                            placeholderText: "e.g. EDDF"
                            selectByMouse: true
                            validator: RegularExpressionValidator { regularExpression: /^[A-Za-z]{4}$/ }
                            onTextChanged: text = text.toUpperCase()
                            color: Theme.white
                            background: Rectangle { color: "#161920"; border.color: parent.activeFocus ? Theme.cyan : "#37474f"; border.width: 1; radius: 4 }
                        }
                    }

                    // Row 4: Destination ICAO
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Label { text: "Destination Airport (ICAO)"; color: "#b0bec5"; font.pixelSize: 11; font.bold: true }
                        TextField {
                            id: destInput
                            Layout.fillWidth: true
                            placeholderText: "e.g. LFPG"
                            selectByMouse: true
                            validator: RegularExpressionValidator { regularExpression: /^[A-Za-z]{4}$/ }
                            onTextChanged: text = text.toUpperCase()
                            color: Theme.white
                            background: Rectangle { color: "#161920"; border.color: parent.activeFocus ? Theme.cyan : "#37474f"; border.width: 1; radius: 4 }
                        }
                    }

                    // Row 5: Alternate ICAO
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Label { text: "Alternate Airport (ICAO)"; color: "#b0bec5"; font.pixelSize: 11; font.bold: true }
                        TextField {
                            id: altnInput
                            Layout.fillWidth: true
                            placeholderText: "e.g. EBBR"
                            selectByMouse: true
                            validator: RegularExpressionValidator { regularExpression: /^[A-Za-z]{4}$/ }
                            onTextChanged: text = text.toUpperCase()
                            color: Theme.white
                            background: Rectangle { color: "#161920"; border.color: parent.activeFocus ? Theme.cyan : "#37474f"; border.width: 1; radius: 4 }
                        }
                    }

                    // Row 6: Cruise Altitude
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Label { text: "Cruise Altitude (FT)"; color: "#b0bec5"; font.pixelSize: 11; font.bold: true }
                        TextField {
                            id: crzAltInput
                            Layout.fillWidth: true
                            placeholderText: "e.g. 32000"
                            selectByMouse: true
                            validator: IntValidator { bottom: 1000; top: 41000 }
                            color: Theme.white
                            background: Rectangle { color: "#161920"; border.color: parent.activeFocus ? Theme.cyan : "#37474f"; border.width: 1; radius: 4 }
                        }
                    }

                    // Row 7: Zero Fuel Weight
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Label { text: "Zero Fuel Weight (KG)"; color: "#b0bec5"; font.pixelSize: 11; font.bold: true }
                        TextField {
                            id: zfwInput
                            Layout.fillWidth: true
                            placeholderText: "e.g. 58000"
                            selectByMouse: true
                            validator: DoubleValidator { bottom: 30000; top: 80000 }
                            color: Theme.white
                            background: Rectangle { color: "#161920"; border.color: parent.activeFocus ? Theme.cyan : "#37474f"; border.width: 1; radius: 4 }
                        }
                    }

                    // Row 8: Block Fuel
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Label { text: "Block Fuel (KG)"; color: "#b0bec5"; font.pixelSize: 11; font.bold: true }
                        TextField {
                            id: blockFuelInput
                            Layout.fillWidth: true
                            placeholderText: "e.g. 12000"
                            selectByMouse: true
                            validator: DoubleValidator { bottom: 2000; top: 25000 }
                            color: Theme.white
                            background: Rectangle { color: "#161920"; border.color: parent.activeFocus ? Theme.cyan : "#37474f"; border.width: 1; radius: 4 }
                        }
                    }
                }
            }

            // Error display if validations fail
            Text {
                id: errorText
                color: Theme.red
                font.pixelSize: 12
                font.family: "Consolas"
                Layout.alignment: Qt.AlignHCenter
                visible: text.length > 0
            }

            // Submit Button
            Button {
                text: "INITIALIZE FLIGHT DECK"
                Layout.preferredWidth: 260
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignHCenter

                contentItem: Label {
                    text: parent.text
                    color: parent.hovered ? "#000000" : Theme.cyan
                    font.pixelSize: 13; font.bold: true; font.family: "Consolas"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: parent.hovered ? Theme.cyan : Qt.rgba(0, 0.82, 1.0, 0.08)
                    border.color: Theme.cyan
                    border.width: 1
                    radius: 6
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                onClicked: {
                    if (flightNumInput.text.length === 0 || depInput.text.length < 4 || destInput.text.length < 4) {
                        errorText.text = "Error: Invalid Flight ID or Airport ICAO code."
                        return
                    }

                    // Save values back to singleton FlightDataManager
                    FlightDataManager.flightNumber = flightNumInput.text
                    FlightDataManager.departure = depInput.text
                    FlightDataManager.destination = destInput.text
                    FlightDataManager.alternate = altnInput.text
                    FlightDataManager.cruiseAltitude = parseInt(crzAltInput.text)
                    FlightDataManager.zeroFuelWeight = parseFloat(zfwInput.text)
                    FlightDataManager.blockFuel = parseFloat(blockFuelInput.text)
                    FlightDataManager.costIndex = parseInt(costIndexInput.text)

                    root.flightInitialized()
                }
            }
        }
    }
}
