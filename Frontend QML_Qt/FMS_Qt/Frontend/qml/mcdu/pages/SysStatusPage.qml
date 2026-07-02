import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// SYS STATUS — 1:1 port of React SysStatusPage.tsx
McduPage {
    id: page
    title: "SYS STATUS"

    McduRow { left: "ENG 1"; right: "NORM"; rightColor: Theme.mcduGreen }
    McduRow { left: "N1";    right: (page.adc ? page.adc.n1Left.toFixed(1) : "0.0") + "%" }
    McduRow { left: "EGT";   right: (page.adc ? page.adc.egtLeft.toFixed(0) : "0") + "°C" }
    McduRow { left: "ENG 2"; right: "NORM"; rightColor: Theme.mcduGreen }
    McduRow { left: "N1";    right: (page.adc ? page.adc.n1Right.toFixed(1) : "0.0") + "%" }
    McduRow { left: "EGT";   right: (page.adc ? page.adc.egtRight.toFixed(0) : "0") + "°C" }
    McduRow { left: "HYD G"; right: "NORM"; rightColor: Theme.mcduGreen }
    McduRow { left: "HYD B"; right: "NORM"; rightColor: Theme.mcduGreen }
    McduRow { left: "HYD Y"; right: "NORM"; rightColor: Theme.mcduGreen }
    McduRow { left: "ELEC";  right: "NORM"; rightColor: Theme.mcduGreen }
    McduRow { left: "FUEL";  right: (FlightDataManager ? FlightDataManager.tripFuel.toFixed(0) : "0") + " KG" }
    Item { Layout.fillHeight: true }
}
