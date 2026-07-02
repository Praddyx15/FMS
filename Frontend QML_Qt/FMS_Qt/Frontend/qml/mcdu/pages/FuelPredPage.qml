import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// FUEL PRED — 1:1 port of React FuelPredPage.tsx
McduPage {
    id: page
    title: "FUEL PRED"
    readonly property real trip: FlightDataManager ? FlightDataManager.tripFuel : 0

    McduRow { left: "FOB";       right: page.trip.toFixed(0) + " KG" }
    McduRow { left: "FUEL FLOW"; right: "2400 KG/H" }
    McduRow { left: "DEST";      right: FlightDataManager ? FlightDataManager.destination : "----" }
    McduRow { left: "EFOB";      right: "5200 KG"; rightColor: Theme.mcduCyan }
    McduRow { left: "ETA";       right: "13:45" }
    McduRow { left: "ALTN";      right: FlightDataManager ? (FlightDataManager.alternate || "----") : "----" }
    McduRow { left: "EFOB";      right: "4400 KG" }
    McduRow { left: "FINAL";     right: (FlightDataManager ? FlightDataManager.finalReserve.toFixed(0) : "0") + " KG" }
    McduRow { left: "EXTRA";     right: "3700 KG"; leftColor: Theme.mcduGreen }
    McduRow { left: "TIME";      right: "1.5 HR" }
    Item { Layout.fillHeight: true }
}
