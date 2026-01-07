import QtQuick 2.15
import QtQuick.Controls 2.15
import QtCharts 2.15

Rectangle {
    id: chartView
    color: "#fafafa"
    radius: 3

    property bool dataLoaded: false

    function loadChannel(fileIndex, channelIndex) {
        // Clear existing data
        lineSeries.clear()

        // Get original data from filter controller
        var points = filterController.getOriginalData(10000)

        if (points && points.length > 0) {
            // Find min/max for axis scaling
            var minY = points[0].y
            var maxY = points[0].y

            for (var i = 0; i < points.length; i++) {
                lineSeries.append(points[i].x, points[i].y)
                if (points[i].y < minY) minY = points[i].y
                if (points[i].y > maxY) maxY = points[i].y
            }

            // Update axes
            axisX.max = points[points.length - 1].x
            axisY.min = minY - Math.abs(minY * 0.1)
            axisY.max = maxY + Math.abs(maxY * 0.1)

            dataLoaded = true
        } else {
            dataLoaded = false
        }
    }

    function updateWithFilteredData(filteredData) {
        lineSeries.clear()

        if (filteredData && filteredData.length > 0) {
            var minY = filteredData[0].y
            var maxY = filteredData[0].y

            for (var i = 0; i < filteredData.length; i++) {
                lineSeries.append(filteredData[i].x, filteredData[i].y)
                if (filteredData[i].y < minY) minY = filteredData[i].y
                if (filteredData[i].y > maxY) maxY = filteredData[i].y
            }

            // Update Y axis for filtered data
            axisY.min = minY - Math.abs(minY * 0.1)
            axisY.max = maxY + Math.abs(maxY * 0.1)

            dataLoaded = true
        }
    }

    ChartView {
        id: chart
        anchors.fill: parent
        antialiasing: true
        theme: ChartView.ChartThemeLight
        legend.visible: false
        backgroundColor: "transparent"
        plotAreaColor: "white"

        ValueAxis {
            id: axisX
            titleText: "Sample Index"
            labelFormat: "%d"
        }

        ValueAxis {
            id: axisY
            titleText: "Amplitude (mV)"
            labelFormat: "%.2f"
        }

        LineSeries {
            id: lineSeries
            name: "Signal"
            axisX: axisX
            axisY: axisY
            width: 1.5
            color: "#2196F3"
            useOpenGL: true
        }
    }

    // Empty state
    Column {
        anchors.centerIn: parent
        spacing: 10
        visible: !dataLoaded

        Text {
            text: "📈"
            font.pixelSize: 48
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: 0.3
        }

        Text {
            text: "No data to display"
            font.pixelSize: 14
            color: "#999"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Controls overlay
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        width: controlsColumn.width + 20
        height: controlsColumn.height + 20
        color: "#f0f0f0"
        radius: 5
        opacity: 0.9
        visible: dataLoaded

        Column {
            id: controlsColumn
            anchors.centerIn: parent
            spacing: 5

            Button {
                text: "Zoom In"
                onClicked: chart.zoom(1.2)
            }

            Button {
                text: "Zoom Out"
                onClicked: chart.zoom(0.8)
            }

            Button {
                text: "Reset Zoom"
                onClicked: chart.zoomReset()
            }
        }
    }
}
