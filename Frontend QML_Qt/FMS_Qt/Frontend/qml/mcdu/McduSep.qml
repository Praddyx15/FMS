import QtQuick 2.15
import QtQuick.Layouts 1.15
import FmsTrainer 1.0
import FmsBackend 1.0

// McduSep — full-width green/30 separator line (mt-4 pt-2 border-t equivalent)
Rectangle {
    Layout.fillWidth: true
    Layout.topMargin: 6
    Layout.bottomMargin: 2
    height: 1
    color: Qt.rgba(Theme.mcduGreen.r, Theme.mcduGreen.g, Theme.mcduGreen.b, 0.3)
}
