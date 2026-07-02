import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// DIR TO — 1:1 port of React DirectToPage.tsx
McduPage {
    id: page
    title: "DIR TO"

    McduRow { left: "<WAYPOINT"; right: "----"; leftColor: Theme.mcduCyan; bold: true }
    McduRow { left: "CURR POS";  right: "N40°38.4' W073°46.7'"; rightColor: Theme.mcduCyan; size: 10 }
    Item { Layout.fillHeight: true }
    McduRow { left: "<RETURN"; right: ""; leftColor: Theme.mcduCyan }
}
