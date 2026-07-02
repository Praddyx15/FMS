import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// WIND — 1:1 port of React WindPage.tsx
McduPage {
    id: page
    title: "WIND"

    // header
    RowLayout {
        Layout.fillWidth: true; Layout.topMargin: 2
        Text { Layout.fillWidth: true; Layout.preferredWidth: 1; text: "FL";      color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10 }
        Text { Layout.fillWidth: true; Layout.preferredWidth: 1; text: "DIR/SPD"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10 }
        Text { Layout.fillWidth: true; Layout.preferredWidth: 1; text: "TEMP";    color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10 }
        Text { Layout.fillWidth: true; Layout.preferredWidth: 1; text: "ISA";     color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10 }
    }
    Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(Theme.mcduGreen.r, Theme.mcduGreen.g, Theme.mcduGreen.b, 0.3) }

    Repeater {
        model: [
            { fl: "390", ds: "280°/95", t: "-56°C", isa: "-3", ic: Theme.mcduCyan },
            { fl: "350", ds: "275°/85", t: "-52°C", isa: "-2", ic: Theme.mcduCyan },
            { fl: "310", ds: "270°/72", t: "-44°C", isa: "0",  ic: Theme.mcduCyan },
            { fl: "250", ds: "265°/58", t: "-30°C", isa: "+1", ic: Theme.mcduAmber },
            { fl: "180", ds: "255°/40", t: "-12°C", isa: "+3", ic: Theme.mcduAmber },
            { fl: "100", ds: "250°/25", t: "+2°C",  isa: "+5", ic: Theme.mcduAmber },
        ]
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; Layout.preferredWidth: 1; text: modelData.fl; color: Theme.mcduWhite; font.bold: true; font.family: Theme.fontFms; font.pixelSize: 10 }
            Text { Layout.fillWidth: true; Layout.preferredWidth: 1; text: modelData.ds; color: Theme.mcduCyan; font.family: Theme.fontFms; font.pixelSize: 10 }
            Text { Layout.fillWidth: true; Layout.preferredWidth: 1; text: modelData.t;  color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 10 }
            Text { Layout.fillWidth: true; Layout.preferredWidth: 1; text: modelData.isa; color: modelData.ic; font.family: Theme.fontFms; font.pixelSize: 10 }
        }
    }
    Item { Layout.fillHeight: true }
    McduRow { left: "<RETURN"; right: ""; leftColor: Theme.mcduCyan }
}
