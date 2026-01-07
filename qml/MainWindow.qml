import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs

Item {
    id: mainWindow
    focus: true

    // Keyboard shortcuts for zoom
    Keys.onPressed: function(event) {
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) {
                if (appController.hasData) {
                    waveformView.zoomIn()
                    event.accepted = true
                }
            } else if (event.key === Qt.Key_Minus) {
                if (appController.hasData) {
                    waveformView.zoomOut()
                    event.accepted = true
                }
            } else if (event.key === Qt.Key_0) {
                if (appController.hasData) {
                    waveformView.resetZoom()
                    event.accepted = true
                }
            }
        }
    }

    // Filter design window
    FilterDesignWindow {
        id: filterDesignWindow
    }

    Rectangle {
        anchors.fill: parent
        color: "#0a0e1a"  // Dark navy background

        // Top menu bar
        Rectangle {
            id: topMenuBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 40
            color: "#1a1f2e"
            border.color: "#2a3f5f"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 15
                spacing: 20

                // App logo/title
                Row {
                    spacing: 10

                    Rectangle {
                        width: 24
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter
                        color: "transparent"
                        border.color: "#00aaff"
                        border.width: 2
                        radius: 4

                        Text {
                            anchors.centerIn: parent
                            text: "A"
                            color: "#00aaff"
                            font.bold: true
                            font.pixelSize: 14
                        }
                    }

                    Text {
                        text: "ACQ Signal Processor"
                        font.pixelSize: 14
                        font.bold: true
                        color: "#e0e0e0"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Menu items
                Text {
                    text: "File"
                    font.pixelSize: 12
                    color: "#b0b0b0"
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = "#00aaff"
                        onExited: parent.color = "#b0b0b0"
                    }
                }

                Text {
                    text: "Edit"
                    font.pixelSize: 12
                    color: "#b0b0b0"
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = "#00aaff"
                        onExited: parent.color = "#b0b0b0"
                    }
                }

                Text {
                    text: "View"
                    font.pixelSize: 12
                    color: "#b0b0b0"
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = "#00aaff"
                        onExited: parent.color = "#b0b0b0"
                    }
                }

                Text {
                    text: "Analysis"
                    font.pixelSize: 12
                    color: "#b0b0b0"
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = "#00aaff"
                        onExited: parent.color = "#b0b0b0"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                }

                // Current file indicator
                Text {
                    visible: appController.hasData
                    text: appController.currentFile ? appController.currentFile.split('/').pop() : ""
                    font.pixelSize: 11
                    color: "#707070"
                }
            }
        }

        RowLayout {
            anchors.top: topMenuBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 0

            // Left sidebar
            Rectangle {
                id: leftSidebar
                Layout.preferredWidth: 200
                Layout.fillHeight: true
                color: "#13182b"
                border.color: "#2a3f5f"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 15

                    // ACTIVE SESSION section
                    Column {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "ACTIVE SESSION"
                            font.pixelSize: 10
                            font.bold: true
                            color: "#707070"
                            font.letterSpacing: 1
                        }

                        Rectangle {
                            width: parent.width
                            height: 80
                            color: appController.hasData ? "#1a2844" : "#1a1f2e"
                            border.color: appController.hasData ? "#00aaff" : "#2a3f5f"
                            border.width: appController.hasData ? 2 : 1
                            radius: 4

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 4

                                Text {
                                    text: appController.currentFile ? appController.currentFile.split('/').pop() : "No file loaded"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: appController.hasData ? "#00aaff" : "#505050"
                                    elide: Text.ElideMiddle
                                    width: parent.width
                                }

                                Text {
                                    visible: appController.hasData
                                    text: "Captured: " + Qt.formatDateTime(new Date(), "MMM dd, hh:mm AP")
                                    font.pixelSize: 9
                                    color: "#707070"
                                }

                                Text {
                                    visible: appController.hasData
                                    text: "Duration: " + (appController.numSamples / appController.sampleRate).toFixed(1) + "s"
                                    font.pixelSize: 9
                                    color: "#707070"
                                }
                            }
                        }
                    }

                    // CHANNELS section
                    Column {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8

                        Row {
                            width: parent.width
                            spacing: 5

                            Text {
                                text: "CHANNELS"
                                font.pixelSize: 10
                                font.bold: true
                                color: "#707070"
                                font.letterSpacing: 1
                            }

                            Rectangle {
                                width: 40
                                height: 16
                                anchors.verticalCenter: parent.verticalCenter
                                color: "transparent"
                                border.color: "#00aaff"
                                border.width: 1
                                radius: 3

                                Text {
                                    anchors.centerIn: parent
                                    text: "Config"
                                    font.pixelSize: 8
                                    color: "#00aaff"
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 60
                            color: appController.hasData ? "#1a2844" : "#1a1f2e"
                            border.color: appController.hasData ? "#00aaff" : "#2a3f5f"
                            border.width: 1
                            radius: 4

                            Column {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 3

                                Row {
                                    spacing: 5

                                    Rectangle {
                                        width: 12
                                        height: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: appController.hasData ? "#00aaff" : "#2a3f5f"
                                        radius: 2
                                    }

                                    Text {
                                        text: "Ch 1: Signal Data"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: appController.hasData ? "#e0e0e0" : "#505050"
                                    }
                                }

                                Text {
                                    text: appController.hasData ? "Active • " + appController.sampleRate.toFixed(0) + "Hz" : "Inactive"
                                    font.pixelSize: 9
                                    color: "#707070"
                                    leftPadding: 17
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    // Action buttons
                    Column {
                        Layout.fillWidth: true
                        spacing: 8

                        Button {
                            width: parent.width
                            height: 36
                            text: "Load ACQ File"

                            background: Rectangle {
                                color: parent.hovered ? "#0099dd" : "#00aaff"
                                radius: 4
                            }

                            contentItem: Text {
                                text: parent.text
                                font.pixelSize: 12
                                font.bold: true
                                color: "#0a0e1a"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: fileDialog.open()
                        }

                        Button {
                            width: parent.width
                            height: 32
                            text: "Signal Processing"
                            enabled: appController.hasData

                            background: Rectangle {
                                color: parent.enabled ? (parent.hovered ? "#2a3f5f" : "#1a2844") : "#1a1f2e"
                                border.color: parent.enabled ? "#00aaff" : "#2a3f5f"
                                border.width: 1
                                radius: 4
                            }

                            contentItem: Text {
                                text: parent.text
                                font.pixelSize: 11
                                color: parent.enabled ? "#00aaff" : "#505050"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: filterDesignWindow.show()
                        }

                        Button {
                            id: labelButton
                            width: parent.width
                            height: 32
                            text: labelingTools.visible ? "Hide Labels" : "Show Labels"
                            enabled: appController.hasData

                            background: Rectangle {
                                color: parent.checked ? "#2a3f5f" : (parent.enabled ? (parent.hovered ? "#2a3f5f" : "#1a2844") : "#1a1f2e")
                                border.color: parent.enabled ? "#00aaff" : "#2a3f5f"
                                border.width: 1
                                radius: 4
                            }

                            contentItem: Text {
                                text: parent.text
                                font.pixelSize: 11
                                color: parent.enabled ? "#00aaff" : "#505050"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            checkable: true
                            checked: labelingTools.visible
                            onClicked: {
                                labelingTools.visible = !labelingTools.visible
                            }
                        }
                    }
                }
            }

            // Main content area
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // Toolbar with controls
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    color: "#13182b"
                    border.color: "#2a3f5f"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 12

                        // Zoom controls
                        Row {
                            spacing: 4

                            Button {
                                width: 32
                                height: 32
                                text: "+"
                                enabled: appController.hasData

                                background: Rectangle {
                                    color: parent.enabled ? (parent.hovered ? "#2a3f5f" : "#1a2844") : "#1a1f2e"
                                    border.color: "#2a3f5f"
                                    border.width: 1
                                    radius: 3
                                }

                                contentItem: Text {
                                    text: parent.text
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: parent.enabled ? "#b0b0b0" : "#505050"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: waveformView.zoomIn()
                            }

                            Button {
                                width: 32
                                height: 32
                                text: "−"
                                enabled: appController.hasData

                                background: Rectangle {
                                    color: parent.enabled ? (parent.hovered ? "#2a3f5f" : "#1a2844") : "#1a1f2e"
                                    border.color: "#2a3f5f"
                                    border.width: 1
                                    radius: 3
                                }

                                contentItem: Text {
                                    text: parent.text
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: parent.enabled ? "#b0b0b0" : "#505050"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: waveformView.zoomOut()
                            }

                            Button {
                                width: 32
                                height: 32
                                text: "⟲"
                                enabled: appController.hasData

                                background: Rectangle {
                                    color: parent.enabled ? (parent.hovered ? "#2a3f5f" : "#1a2844") : "#1a1f2e"
                                    border.color: "#2a3f5f"
                                    border.width: 1
                                    radius: 3
                                }

                                contentItem: Text {
                                    text: parent.text
                                    font.pixelSize: 14
                                    color: parent.enabled ? "#b0b0b0" : "#505050"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: waveformView.resetZoom()
                            }
                        }

                        Rectangle {
                            width: 1
                            height: parent.height - 8
                            color: "#2a3f5f"
                        }

                        // Signal info
                        Row {
                            visible: appController.hasData
                            spacing: 15

                            Column {
                                spacing: 2
                                Text {
                                    text: "SAMPLE RATE"
                                    font.pixelSize: 8
                                    color: "#707070"
                                    font.bold: true
                                }
                                Text {
                                    text: appController.sampleRate.toFixed(0) + " Hz"
                                    font.pixelSize: 11
                                    color: "#e0e0e0"
                                }
                            }

                            Column {
                                spacing: 2
                                Text {
                                    text: "TOTAL SAMPLES"
                                    font.pixelSize: 8
                                    color: "#707070"
                                    font.bold: true
                                }
                                Text {
                                    text: appController.numSamples.toLocaleString()
                                    font.pixelSize: 11
                                    color: "#e0e0e0"
                                }
                            }

                            Column {
                                spacing: 2
                                Text {
                                    text: "DURATION"
                                    font.pixelSize: 8
                                    color: "#707070"
                                    font.bold: true
                                }
                                Text {
                                    text: {
                                        if (appController.sampleRate > 0) {
                                            var duration = appController.numSamples / appController.sampleRate
                                            return duration.toFixed(2) + " s"
                                        }
                                        return "N/A"
                                    }
                                    font.pixelSize: 11
                                    color: "#e0e0e0"
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                        }

                        // Zoom mode toggle
                        Button {
                            width: 90
                            height: 32
                            text: "Zoom to Region"
                            checkable: true
                            checked: waveformView.zoomModeActive
                            enabled: appController.hasData
                            ToolTip.visible: hovered
                            ToolTip.text: "Click and drag to select a time region to zoom into"
                            ToolTip.delay: 500

                            background: Rectangle {
                                color: parent.checked ? "#00aaff" : (parent.enabled ? (parent.hovered ? "#2a3f5f" : "#1a2844") : "#1a1f2e")
                                border.color: parent.enabled ? "#00aaff" : "#2a3f5f"
                                border.width: 1
                                radius: 4
                            }

                            contentItem: Text {
                                text: parent.text
                                font.pixelSize: 9
                                color: parent.checked ? "#0a0e1a" : (parent.enabled ? "#00aaff" : "#505050")
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.bold: parent.checked
                            }

                            onClicked: {
                                waveformView.zoomModeActive = !waveformView.zoomModeActive
                            }
                        }

                        Rectangle {
                            width: 1
                            height: 24
                            color: "#2a3f5f"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Zoom controls
                        Column {
                            spacing: 2
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: "Time Scale"
                                font.pixelSize: 9
                                color: "#707070"
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: {
                                    if (!appController.hasData) return "---"
                                    var zoomPercent = (100 / waveformView.zoomLevel).toFixed(0)
                                    return zoomPercent + "%"
                                }
                                font.pixelSize: 10
                                color: "#00aaff"
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        Rectangle {
                            width: 1
                            height: 24
                            color: "#2a3f5f"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Export button
                        Button {
                            width: 100
                            height: 32
                            text: "Export CSV"
                            enabled: appController.hasData

                            background: Rectangle {
                                color: parent.enabled ? (parent.hovered ? "#2a3f5f" : "#1a2844") : "#1a1f2e"
                                border.color: parent.enabled ? "#00aaff" : "#2a3f5f"
                                border.width: 1
                                radius: 4
                            }

                            contentItem: Text {
                                text: parent.text
                                font.pixelSize: 10
                                color: parent.enabled ? "#00aaff" : "#505050"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                console.log("Export CSV button clicked")
                                csvExportDialog.open()
                            }
                        }
                    }
                }

                // Waveform view
                WaveformView {
                    id: waveformView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    labelingModeActive: labelingTools.visible
                    currentLabelColor: labelingTools.visible ? labelingTools.currentColor : "#FF0000"
                }

                // Bottom status bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    color: "#13182b"
                    border.color: "#2a3f5f"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 15
                        anchors.rightMargin: 15
                        spacing: 15

                        Text {
                            text: appController.statusMessage
                            font.pixelSize: 10
                            color: "#b0b0b0"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                        }

                        Text {
                            visible: labelingTools.visible
                            text: "Labeling Mode"
                            font.pixelSize: 10
                            color: "#00ff88"
                            font.bold: true
                        }


                        Text {
                            visible: appController.hasData
                            text: "Sample Rate: " + appController.sampleRate.toFixed(0) + " Hz"
                            font.pixelSize: 9
                            color: "#707070"
                        }

                        BusyIndicator {
                            visible: appController.isLoading
                            running: appController.isLoading
                            implicitWidth: 16
                            implicitHeight: 16
                        }
                    }
                }
            }

            // Right sidebar - Labeling tools
            LabelingTools {
                id: labelingTools
                Layout.preferredWidth: 220
                Layout.fillHeight: true
                visible: false

                currentSelectionStart: waveformView.selectionStart
                currentSelectionEnd: waveformView.selectionEnd

                onLabelCreated: function(startIdx, endIdx, labelText, color) {
                    waveformView.addLabel(startIdx, endIdx, labelText, color)
                    waveformView.selectionStart = -1
                    waveformView.selectionEnd = -1
                }

                onSaveLabelsRequested: {
                    console.log("Opening save dialog")
                    saveDialog.open()
                }
            }
        }
    }

    // File dialog for loading ACQ files
    FileDialog {
        id: fileDialog
        title: "Select ACQ File"
        nameFilters: ["ACQ files (*.acq)", "All files (*)"]
        onAccepted: {
            var path = fileDialog.selectedFile.toString()
            path = path.replace(/^file:\/\//, "")
            appController.loadACQFile(path)
        }
    }

    // Save dialog for labels
    FileDialog {
        id: saveDialog
        title: "Save Labels as JSON"
        fileMode: FileDialog.SaveFile
        nameFilters: ["JSON files (*.json)", "All files (*)"]
        defaultSuffix: "json"

        currentFolder: {
            if (appController.currentFile && appController.currentFile.length > 0) {
                var folder = appController.currentFile.substring(0, appController.currentFile.lastIndexOf('/'))
                return "file://" + folder
            }
            return ""
        }

        selectedFile: {
            if (appController.currentFile && appController.currentFile.length > 0) {
                var fullPath = appController.currentFile
                var lastSlash = fullPath.lastIndexOf('/')
                var fileName = fullPath.substring(lastSlash + 1)
                var lastDot = fileName.lastIndexOf('.')
                var baseName = lastDot > 0 ? fileName.substring(0, lastDot) : fileName
                var folder = fullPath.substring(0, lastSlash)
                return "file://" + folder + "/" + baseName + "_labels.json"
            }
            return ""
        }

        onAccepted: {
            var path = saveDialog.selectedFile.toString()
            console.log("Save dialog accepted, raw path:", path)
            path = path.replace(/^file:\/\//, "")
            console.log("Cleaned path:", path)
            console.log("Saving", labelManager.labelCount, "labels to:", path)

            if (labelManager.saveToFile(path)) {
                console.log("✓ SUCCESS: Saved", labelManager.labelCount, "labels to", path)
                console.log("✓ You can now open the file:", path)
            } else {
                console.error("✗ ERROR: Failed to save labels to", path)
            }
        }

        onRejected: {
            console.log("Save dialog cancelled by user")
        }
    }

    // CSV export dialog
    FileDialog {
        id: csvExportDialog
        title: "Export Waveform as CSV"
        fileMode: FileDialog.SaveFile
        nameFilters: ["CSV files (*.csv)", "All files (*)"]
        defaultSuffix: "csv"

        currentFolder: {
            if (appController.currentFile && appController.currentFile.length > 0) {
                var folder = appController.currentFile.substring(0, appController.currentFile.lastIndexOf('/'))
                return "file://" + folder
            }
            return ""
        }

        selectedFile: {
            if (appController.currentFile && appController.currentFile.length > 0) {
                var fullPath = appController.currentFile
                var lastSlash = fullPath.lastIndexOf('/')
                var fileName = fullPath.substring(lastSlash + 1)
                var lastDot = fileName.lastIndexOf('.')
                var baseName = lastDot > 0 ? fileName.substring(0, lastDot) : fileName
                var folder = fullPath.substring(0, lastSlash)
                return "file://" + folder + "/" + baseName + "_export.csv"
            }
            return ""
        }

        onAccepted: {
            var path = csvExportDialog.selectedFile.toString()
            console.log("CSV export dialog accepted, raw path:", path)
            path = path.replace(/^file:\/\//, "")
            console.log("Cleaned path:", path)

            if (appController.exportToCSV(path)) {
                console.log("✓ SUCCESS: Exported waveform to", path)
            } else {
                console.error("✗ ERROR: Failed to export waveform to", path)
            }
        }

        onRejected: {
            console.log("CSV export dialog cancelled by user")
        }
    }

    // Listen to application events
    Connections {
        target: appController

        function onConversionComplete() {
            waveformView.loadWaveform()
        }

        function onConversionFailed(error) {
            console.error("Conversion failed:", error)
        }

        function onWaveformUpdated() {
            waveformView.refreshWaveform()
        }
    }
}
