import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: labelOverlay

    property int labelId: -1  // Add label ID for deletion
    property int startIndex: 0
    property int endIndex: 0
    property string labelText: ""
    property string labelColor: "#FF0000"
    property rect chartArea: Qt.rect(0, 0, 0, 0)
    property real sampleRate: 1000.0
    property var chart: null
    property var lineSeries: null
    property bool isSelected: false

    signal deleteRequested(int labelId)
    signal hoverChanged(int labelId, bool isHovered)
    signal labelSelected(int labelId)

    color: Qt.rgba(
        parseInt(labelColor.substr(1, 2), 16) / 255,
        parseInt(labelColor.substr(3, 2), 16) / 255,
        parseInt(labelColor.substr(5, 2), 16) / 255,
        0.3
    )
    border.color: labelColor
    border.width: 2

    // Highlight on hover and selection
    states: [
        State {
            name: "selected"
            when: isSelected
            PropertyChanges {
                target: labelOverlay
                color: Qt.rgba(
                    parseInt(labelColor.substr(1, 2), 16) / 255,
                    parseInt(labelColor.substr(3, 2), 16) / 255,
                    parseInt(labelColor.substr(5, 2), 16) / 255,
                    0.6
                )
                border.width: 4
            }
        },
        State {
            name: "hovered"
            when: mouseArea.containsMouse && !isSelected
            PropertyChanges {
                target: labelOverlay
                color: Qt.rgba(
                    parseInt(labelColor.substr(1, 2), 16) / 255,
                    parseInt(labelColor.substr(3, 2), 16) / 255,
                    parseInt(labelColor.substr(5, 2), 16) / 255,
                    0.5
                )
                border.width: 3
            }
        }
    ]

    // Mouse area for interaction
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                console.log("Right-click - requesting delete for ID:", labelId)
                deleteRequested(labelId)
            } else if (mouse.button === Qt.LeftButton) {
                console.log("Left-click - selecting label ID:", labelId)
                labelSelected(labelId)
            }
        }

        onEntered: {
            hoverChanged(labelId, true)
        }

        onExited: {
            hoverChanged(labelId, false)
        }

        ToolTip.visible: containsMouse
        ToolTip.text: "Left-click to select, Right-click to delete '" + labelText + "'"
        ToolTip.delay: 500
    }

    // Calculate position based on time values
    // Parent container is already positioned at plotArea, so we use local coordinates
    y: 0
    height: parent.height

    x: {
        if (!chart || !lineSeries || sampleRate <= 0) return 0
        var startTime = startIndex / sampleRate
        var pos = chart.mapToPosition(Qt.point(startTime, 0), lineSeries)
        // Subtract plotArea offset since we're inside a container at plotArea position
        return pos.x - chartArea.x
    }

    width: {
        if (!chart || !lineSeries || sampleRate <= 0) return 0
        var startTime = startIndex / sampleRate
        var endTime = endIndex / sampleRate
        var startPos = chart.mapToPosition(Qt.point(startTime, 0), lineSeries)
        var endPos = chart.mapToPosition(Qt.point(endTime, 0), lineSeries)
        return Math.abs(endPos.x - startPos.x)
    }

    // Label text display
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 2
        width: labelTextItem.width + 8
        height: labelTextItem.height + 4
        color: labelColor
        radius: 2

        Text {
            id: labelTextItem
            anchors.centerIn: parent
            text: labelText
            color: "white"
            font.pixelSize: 9
            font.bold: true
        }
    }
}
