import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// POSITION INIT — 1:1 port of React PosInitPage.tsx
McduPage {
    id: page
    title: "POSITION INIT"

    McduRow { left: "<LAT"; right: "___°__._ _";  leftColor: Theme.mcduCyan }
    McduRow { left: "<LON"; right: "____°__._ _"; leftColor: Theme.mcduCyan }
    McduSep {}
    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "IRS POSITION"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 11 }
    McduRow { left: "LAT/LON"; right: "N40°38.42'"; rightColor: Theme.mcduCyan }
    McduRow { left: "";        right: "W073°46.71'"; rightColor: Theme.mcduCyan }
    McduSep {}
    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "GPS POSITION"; color: Theme.mcduWhite; font.family: Theme.fontFms; font.pixelSize: 11 }
    McduRow { left: "LAT/LON"; right: "N40°38.40'"; rightColor: Theme.mcduCyan }
    McduRow { left: "";        right: "W073°46.69'"; rightColor: Theme.mcduCyan }
    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "Format: N/S DD°MM.M' E/W DDD°MM.M'"; color: Theme.mcduAmber; font.family: Theme.fontFms; font.pixelSize: 9 }
    Item { Layout.fillHeight: true }
}
