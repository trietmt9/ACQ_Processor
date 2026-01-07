import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: root
    width: 1400
    height: 800
    visible: true
    title: "ACQ Signal Processor"

    // Color scheme
    readonly property color backgroundColor: "#f5f5f5"
    readonly property color primaryColor: "#1976D2"
    readonly property color accentColor: "#FF6F00"

    MainWindow {
        anchors.fill: parent
    }
}
