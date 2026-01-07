import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: dataViewer
    color: "white"
    radius: 5
    border.color: "#ddd"
    border.width: 1

    property int currentFileIndex: -1
    property int currentChannelIndex: 0

    function loadFile(fileIndex) {
        currentFileIndex = fileIndex
        currentChannelIndex = 0

        // Load binary data for this file
        var success = dataController.loadBinaryData(fileIndex)

        if (success) {
            updateChannelList()
            if (dataController.getChannelCount(fileIndex) > 0) {
                loadChannel(0)
            }
        }
    }

    function updateChannelList() {
        channelModel.clear()
        if (currentFileIndex >= 0) {
            var count = dataController.getChannelCount(currentFileIndex)
            for (var i = 0; i < count; i++) {
                var name = dataController.getChannelName(currentFileIndex, i)
                channelModel.append({
                    channelName: name,
                    channelIndex: i
                })
            }
        }
    }

    function loadChannel(channelIndex) {
        currentChannelIndex = channelIndex

        // Load data first
        var success = dataController.loadBinaryData(currentFileIndex)
        if (success) {
            // Pass channel data to filter controller via C++
            // The FilterController will get the data through the shared pointer
            setFilterControllerData(currentFileIndex, channelIndex)

            // Load into chart
            chartView.loadChannel(currentFileIndex, channelIndex)
        }
    }

    // Helper function to set filter controller data from C++
    function setFilterControllerData(fileIndex, channelIndex) {
        // Load channel data into filter controller via C++
        var success = dataController.loadChannelToFilter(fileIndex, channelIndex)
        if (success) {
            console.log("✓ Loaded channel", channelIndex, "from file", fileIndex, "into filter controller")
        } else {
            console.error("✗ Failed to load channel into filter controller")
        }
    }

    ListModel {
        id: channelModel
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Header with channel selector
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Data View"
                font.pixelSize: 16
                font.bold: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#ddd"
            }

            Text {
                text: "Channel:"
                font.pixelSize: 12
                visible: channelModel.count > 0
            }

            ComboBox {
                id: channelCombo
                Layout.preferredWidth: 200
                visible: channelModel.count > 0
                model: channelModel
                textRole: "channelName"
                onCurrentIndexChanged: {
                    if (currentFileIndex >= 0 && currentIndex >= 0) {
                        loadChannel(currentIndex)
                    }
                }
            }
        }

        // Main content area with chart and filters
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // Chart view
            ChartView {
                id: chartView
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // Advanced Filter panel for DSP engineers
            AdvancedFilterPanel {
                id: filterPanel
                Layout.preferredWidth: 340
                Layout.fillHeight: true
                visible: currentFileIndex >= 0

                onFilterApplied: function(filteredData) {
                    chartView.updateWithFilteredData(filteredData)
                }
            }
        }

        // Info panel
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: "#f9f9f9"
            radius: 3
            border.color: "#ddd"
            border.width: 1
            visible: currentFileIndex >= 0

            GridLayout {
                anchors.fill: parent
                anchors.margins: 10
                columns: 4
                rowSpacing: 5
                columnSpacing: 15

                Text {
                    text: "File:"
                    font.bold: true
                    font.pixelSize: 11
                }
                Text {
                    text: currentFileIndex >= 0 ? dataController.getFileName(currentFileIndex) : "-"
                    font.pixelSize: 11
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                }

                Text {
                    text: "Samples:"
                    font.bold: true
                    font.pixelSize: 11
                }
                Text {
                    text: chartController.dataSize.toString()
                    font.pixelSize: 11
                }

                Text {
                    text: "Channel:"
                    font.bold: true
                    font.pixelSize: 11
                }
                Text {
                    text: channelCombo.currentText
                    font.pixelSize: 11
                    Layout.fillWidth: true
                }

                Text {
                    text: "Points:"
                    font.bold: true
                    font.pixelSize: 11
                }
                Text {
                    text: chartController.hasData ? chartController.dataSize.toString() : "0"
                    font.pixelSize: 11
                }
            }
        }
    }

    // Empty state
    Column {
        anchors.centerIn: parent
        spacing: 10
        visible: currentFileIndex < 0

        Text {
            text: "📊"
            font.pixelSize: 48
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "No file selected"
            font.pixelSize: 16
            color: "#999"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Select a file from the list to view its data"
            font.pixelSize: 12
            color: "#bbb"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
