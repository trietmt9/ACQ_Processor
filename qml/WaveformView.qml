import QtQuick 2.15
import QtQuick.Controls 2.15
import QtCharts 2.15

Rectangle {
    id: waveformView
    color: "#0a0e1a"  // Dark navy background

    // Enable keyboard focus
    focus: true

    property bool dataLoaded: false
    property int selectionStart: -1
    property int selectionEnd: -1
    property bool labelingModeActive: false
    property string currentLabelColor: "#FF0000"
    property int hoveredLabelId: -1
    property int selectedLabelId: -1
    property bool zoomModeActive: false
    property real zoomBoxStartX: -1
    property real zoomBoxEndX: -1

    // Update overlay selection when selectedLabelId changes
    onSelectedLabelIdChanged: {
        for (var i = 0; i < labelOverlayContainer.children.length; i++) {
            var overlay = labelOverlayContainer.children[i]
            if (overlay.labelId !== undefined) {
                overlay.isSelected = (overlay.labelId === selectedLabelId)
            }
        }
    }

    // Debug: Monitor selection changes
    onSelectionStartChanged: {
        console.log("WaveformView: selectionStart changed to", selectionStart)
    }
    onSelectionEndChanged: {
        console.log("WaveformView: selectionEnd changed to", selectionEnd)
    }

    // Clear selection when exiting labeling mode
    onLabelingModeActiveChanged: {
        if (!labelingModeActive) {
            console.log("Exiting labeling mode - clearing selection")
            selectionStart = -1
            selectionEnd = -1
        }
    }

    // Keyboard event handler
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
            if (selectedLabelId >= 0) {
                console.log("Delete key pressed - removing selected label ID:", selectedLabelId)
                labelManager.removeLabel(selectedLabelId)
                selectedLabelId = -1
                event.accepted = true
            }
        }
    }

    // Store original axis ranges for Home button
    property real originalXMin: 0
    property real originalXMax: 0
    property real originalYMin: 0
    property real originalYMax: 0

    // Zoom level property - synchronized for both axes
    property real zoomLevel: 1.0

    // Pan/position properties (0.0-1.0, where 0.5 is center)
    property real xPanPosition: 0.5
    property real yPanPosition: 0.5

    function loadWaveform() {
        lineSeries.clear()

        var points = appController.getWaveformData(10000)
        var sampleRate = appController.sampleRate

        if (points && points.length > 0 && sampleRate > 0) {
            var minY = points[0].y
            var maxY = points[0].y

            for (var i = 0; i < points.length; i++) {
                var timeInSeconds = points[i].x / sampleRate
                lineSeries.append(timeInSeconds, points[i].y)
                if (points[i].y < minY) minY = points[i].y
                if (points[i].y > maxY) maxY = points[i].y
            }

            var totalTimeInSeconds = (points[points.length - 1].x) / sampleRate
            axisX.max = totalTimeInSeconds
            axisY.min = minY - Math.abs(minY * 0.1)
            axisY.max = maxY + Math.abs(maxY * 0.1)

            originalXMin = axisX.min
            originalXMax = axisX.max
            originalYMin = axisY.min
            originalYMax = axisY.max

            xPanPosition = 0.5
            yPanPosition = 0.5

            dataLoaded = true

            updateYAxisForVisibleRange()

            console.log("Waveform loaded successfully")
            console.log("  Time range:", axisX.min, "-", axisX.max, "seconds")
            console.log("  Voltage range:", axisY.min, "-", axisY.max, "mV")
        }
    }

    function refreshWaveform() {
        console.log("Refreshing waveform display...")
        loadWaveform()
        updateLabelOverlays()
    }

    property var visibleData: []

    function updateYAxisForVisibleRange() {
        var startTime = axisX.min
        var endTime = axisX.max

        var startIdx = Math.floor(startTime * appController.sampleRate)
        var endIdx = Math.ceil(endTime * appController.sampleRate)

        var minVoltage = Number.MAX_VALUE
        var maxVoltage = -Number.MAX_VALUE

        for (var i = 0; i < visibleData.length; i++) {
            var point = visibleData[i]
            var sampleIdx = point.x
            var voltage = point.y

            if (sampleIdx >= startIdx && sampleIdx <= endIdx) {
                minVoltage = Math.min(minVoltage, voltage)
                maxVoltage = Math.max(maxVoltage, voltage)
            }
        }

        if (minVoltage === Number.MAX_VALUE || maxVoltage === -Number.MAX_VALUE) {
            return
        }

        var voltageRange = maxVoltage - minVoltage

        var zoomFactor = (originalXMax - originalXMin) / (endTime - startTime)
        var paddingPercent = Math.max(0.03, 0.1 / Math.sqrt(zoomFactor))
        var padding = voltageRange * paddingPercent

        axisY.min = minVoltage - padding
        axisY.max = maxVoltage + padding

        var displayRange = axisY.max - axisY.min

        if (displayRange < 0.01) {
            axisY.labelFormat = "%.6f"
        } else if (displayRange < 0.1) {
            axisY.labelFormat = "%.5f"
        } else if (displayRange < 1.0) {
            axisY.labelFormat = "%.4f"
        } else if (displayRange < 10.0) {
            axisY.labelFormat = "%.3f"
        } else {
            axisY.labelFormat = "%.2f"
        }
    }

    function zoomIn() {
        var step = zoomLevel > 0.5 ? 0.1 : 0.05
        zoomLevel = Math.max(0.01, zoomLevel - step)
        applyZoomFromSliders()
    }

    function zoomOut() {
        var step = zoomLevel >= 0.5 ? 0.1 : 0.05
        zoomLevel = Math.min(10.0, zoomLevel + step)
        applyZoomFromSliders()
    }

    function resetZoom() {
        zoomLevel = 1.0
        xPanPosition = 0.5
        yPanPosition = 0.5
        applyZoomFromSliders()
    }

    function zoomToTimeRange(startTime, endTime) {
        if (!dataLoaded) return
        if (startTime >= endTime) return

        var xRange = originalXMax - originalXMin
        var selectedRange = endTime - startTime

        // Calculate zoom level based on selected range
        zoomLevel = selectedRange / xRange

        // Calculate pan position to center the selection
        var selectionCenter = (startTime + endTime) / 2
        xPanPosition = (selectionCenter - originalXMin) / xRange

        // Apply the zoom
        applyZoomFromSliders()
    }

    function applyZoomFromSliders() {
        if (!dataLoaded) return

        var xRange = originalXMax - originalXMin
        var visibleXRange = xRange * zoomLevel

        var xCenter = originalXMin + xRange * xPanPosition
        axisX.min = xCenter - visibleXRange / 2
        axisX.max = xCenter + visibleXRange / 2

        if (axisX.min < originalXMin) {
            axisX.min = originalXMin
            axisX.max = originalXMin + visibleXRange
        }
        if (axisX.max > originalXMax) {
            axisX.max = originalXMax
            axisX.min = originalXMax - visibleXRange
        }

        var yRange = originalYMax - originalYMin
        var visibleYRange = yRange * zoomLevel

        var yCenter = originalYMin + yRange * yPanPosition
        axisY.min = yCenter - visibleYRange / 2
        axisY.max = yCenter + visibleYRange / 2

        if (axisY.min < originalYMin) {
            axisY.min = originalYMin
            axisY.max = originalYMin + visibleYRange
        }
        if (axisY.max > originalYMax) {
            axisY.max = originalYMax
            axisY.min = originalYMax - visibleYRange
        }

        updateYAxisForVisibleRange()
        updateLabelOverlays()  // Update label positions when zoom/pan changes
    }

    function addLabel(startIdx, endIdx, labelText, color) {
        console.log("WaveformView.addLabel called:", "Start:", startIdx, "End:", endIdx, "Label:", labelText, "Color:", color)
        labelManager.addLabel(startIdx, endIdx, labelText, color)
        console.log("After addLabel, labelManager.labels.length:", labelManager.labels.length)
        updateLabelOverlays()
        console.log("updateLabelOverlays() completed")
    }

    function updateLabelOverlays() {
        for (var i = labelOverlayContainer.children.length - 1; i >= 0; i--) {
            labelOverlayContainer.children[i].destroy()
        }

        var labels = labelManager.labels
        console.log("Updating label overlays, count:", labels.length)

        for (var j = 0; j < labels.length; j++) {
            var label = labels[j]
            console.log("  Label #" + j + ": ID=" + label.id + ", Name='" + label.label + "', Color=" + label.color + ", Indices=" + label.startIndex + "-" + label.endIndex)

            var startTime = label.startIndex / appController.sampleRate
            var endTime = label.endIndex / appController.sampleRate

            var startPos = chart.mapToPosition(Qt.point(startTime, 0), lineSeries)
            var endPos = chart.mapToPosition(Qt.point(endTime, 0), lineSeries)

            var overlayX = startPos.x - chart.plotArea.x
            var overlayWidth = endPos.x - startPos.x

            console.log("    Calculated overlay position: x=" + overlayX + ", width=" + overlayWidth + ", startPos.x=" + startPos.x + ", endPos.x=" + endPos.x)

            if (overlayWidth > 0) {
                var overlay = Qt.createComponent("LabelOverlay.qml").createObject(
                    labelOverlayContainer,
                    {
                        labelText: label.label,
                        labelColor: label.color,
                        labelId: label.id,
                        visible: true,
                        isSelected: label.id === selectedLabelId,
                        // Required for LabelOverlay to calculate its own position
                        chart: chart,
                        lineSeries: lineSeries,
                        sampleRate: appController.sampleRate,
                        startIndex: label.startIndex,
                        endIndex: label.endIndex,
                        chartArea: chart.plotArea
                    }
                )

                if (overlay === null) {
                    console.error("    ✗ FAILED to create label overlay!")
                    return
                }

                console.log("    ✓ Created label overlay successfully: x=" + overlay.x + ", width=" + overlay.width + ", visible=" + overlay.visible + ", color=" + overlay.labelColor)

                overlay.deleteRequested.connect(function(id) {
                    console.log("Right-click delete requested for label ID:", id)
                    labelManager.removeLabel(id)
                    if (selectedLabelId === id) {
                        selectedLabelId = -1
                    }
                })

                overlay.labelSelected.connect(function(id) {
                    console.log("Label selected:", id)
                    selectedLabelId = id
                    waveformView.forceActiveFocus()
                })

                overlay.hoverChanged.connect(function(id, isHovered) {
                    if (isHovered) {
                        hoveredLabelId = id
                        waveformView.forceActiveFocus()
                    } else if (hoveredLabelId === id) {
                        hoveredLabelId = -1
                    }
                })
            }
        }
    }

    ChartView {
        id: chart
        anchors.fill: parent
        antialiasing: true
        theme: ChartView.ChartThemeDark
        legend.visible: false
        backgroundColor: "#0a0e1a"
        plotAreaColor: "#0f1421"
        margins.top: 10
        margins.bottom: 10
        margins.left: 10
        margins.right: 10

        ValueAxis {
            id: axisX
            titleText: "Time (s)"
            labelFormat: "%.2f"
            min: 0
            color: "#2a3f5f"
            labelsColor: "#b0b0b0"
            titleFont.pixelSize: 11
            titleFont.bold: true
            gridLineColor: "#1a2844"
            minorGridLineColor: "#13182b"
        }

        ValueAxis {
            id: axisY
            titleText: "Amplitude (mV)"
            labelFormat: "%.2f"
            color: "#2a3f5f"
            labelsColor: "#b0b0b0"
            titleFont.pixelSize: 11
            titleFont.bold: true
            gridLineColor: "#1a2844"
            minorGridLineColor: "#13182b"
        }

        LineSeries {
            id: lineSeries
            name: "Signal"
            axisX: axisX
            axisY: axisY
            width: 1.5
            color: "#00aaff"
            useOpenGL: true
        }

        // Mouse area for selection and zoom
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            cursorShape: {
                if (labelingModeActive) return Qt.CrossCursor
                if (zoomModeActive) return Qt.CrossCursor
                return Qt.OpenHandCursor
            }

            property int pressX: -1
            property int pressStartIdx: -1
            property real dragStartX: -1
            property real dragCurrentX: -1
            property real dragStartY: -1
            property real panStartXPos: 0
            property real panStartYPos: 0

            onPressed: {
                if (!dataLoaded) return

                if (labelingModeActive) {
                    // Label selection mode
                    var pos = chart.mapToValue(Qt.point(mouse.x, mouse.y), lineSeries)
                    pressX = Math.round(pos.x * appController.sampleRate)
                    pressStartIdx = pressX

                    dragStartX = mouse.x - chart.plotArea.x
                    dragCurrentX = dragStartX
                    dragPreview.visible = true
                } else if (zoomModeActive) {
                    // Zoom to region mode
                    zoomBoxStartX = mouse.x
                    zoomBoxEndX = mouse.x
                    zoomBoxPreview.visible = true
                } else {
                    // Pan mode
                    panStartXPos = xPanPosition
                    panStartYPos = yPanPosition
                    dragStartX = mouse.x
                    dragStartY = mouse.y
                    cursorShape = Qt.ClosedHandCursor
                }
            }

            onPositionChanged: {
                if (!dataLoaded) return

                if (labelingModeActive && pressX >= 0) {
                    // Update selection preview
                    dragCurrentX = mouse.x - chart.plotArea.x

                    var startX = Math.min(dragStartX, dragCurrentX)
                    var width = Math.abs(dragCurrentX - dragStartX)
                    dragPreview.x = chart.plotArea.x + startX
                    dragPreview.width = width
                } else if (zoomModeActive && zoomBoxStartX >= 0) {
                    // Update zoom box preview
                    zoomBoxEndX = mouse.x
                    var minX = Math.min(zoomBoxStartX, zoomBoxEndX)
                    var maxX = Math.max(zoomBoxStartX, zoomBoxEndX)
                    zoomBoxPreview.x = minX
                    zoomBoxPreview.width = maxX - minX
                } else if (!labelingModeActive && !zoomModeActive && dragStartX >= 0) {
                    // Pan the graph
                    var xRange = originalXMax - originalXMin
                    var visibleXRange = xRange * zoomLevel
                    var xDelta = (mouse.x - dragStartX) / chart.plotArea.width * visibleXRange / xRange
                    xPanPosition = Math.max(0.0, Math.min(1.0, panStartXPos - xDelta))

                    var yRange = originalYMax - originalYMin
                    var visibleYRange = yRange * zoomLevel
                    var yDelta = (mouse.y - dragStartY) / chart.plotArea.height * visibleYRange / yRange
                    yPanPosition = Math.max(0.0, Math.min(1.0, panStartYPos + yDelta))  // Inverted for natural drag

                    applyZoomFromSliders()
                }
            }

            onReleased: {
                if (!dataLoaded) return

                if (labelingModeActive && pressX >= 0) {
                    // Complete selection
                    var pos = chart.mapToValue(Qt.point(mouse.x, mouse.y), lineSeries)
                    var endIdx = Math.round(pos.x * appController.sampleRate)

                    selectionStart = pressStartIdx
                    selectionEnd = endIdx

                    if (selectionStart > selectionEnd) {
                        var temp = selectionStart
                        selectionStart = selectionEnd
                        selectionEnd = temp
                    }

                    console.log("Selection updated:", selectionStart, "-", selectionEnd)

                    dragPreview.visible = false
                    selectionOverlay.visible = true
                } else if (zoomModeActive && zoomBoxStartX >= 0) {
                    // Zoom to selected region
                    var minX = Math.min(zoomBoxStartX, zoomBoxEndX)
                    var maxX = Math.max(zoomBoxStartX, zoomBoxEndX)

                    // Only zoom if there's a meaningful selection (at least 10 pixels)
                    if (Math.abs(maxX - minX) > 10) {
                        var startPos = chart.mapToValue(Qt.point(minX, chart.plotArea.y), lineSeries)
                        var endPos = chart.mapToValue(Qt.point(maxX, chart.plotArea.y), lineSeries)

                        console.log("Zooming to time range:", startPos.x.toFixed(3), "s -", endPos.x.toFixed(3), "s")
                        zoomToTimeRange(startPos.x, endPos.x)
                    }

                    zoomBoxPreview.visible = false
                    zoomBoxStartX = -1
                    zoomBoxEndX = -1
                }

                // Reset
                pressX = -1
                pressStartIdx = -1
                dragStartX = -1
                cursorShape = labelingModeActive ? Qt.CrossCursor : (zoomModeActive ? Qt.CrossCursor : Qt.OpenHandCursor)
            }

            onWheel: {
                if (!dataLoaded) return

                var delta = wheel.angleDelta.y
                if (delta > 0) {
                    zoomIn()
                } else {
                    zoomOut()
                }
            }
        }
    }

    // Drag preview rectangle (transient)
    Rectangle {
        id: dragPreview
        parent: chart
        y: chart.plotArea.y
        height: chart.plotArea.height
        color: Qt.rgba(
            parseInt(currentLabelColor.substring(1, 3), 16) / 255,
            parseInt(currentLabelColor.substring(3, 5), 16) / 255,
            parseInt(currentLabelColor.substring(5, 7), 16) / 255,
            0.3
        )
        border.color: currentLabelColor
        border.width: 2
        visible: false
        z: 1
    }

    // Selection overlay (persistent after release)
    Rectangle {
        id: selectionOverlay
        parent: chart
        y: chart.plotArea.y
        height: chart.plotArea.height
        color: Qt.rgba(
            parseInt(currentLabelColor.substring(1, 3), 16) / 255,
            parseInt(currentLabelColor.substring(3, 5), 16) / 255,
            parseInt(currentLabelColor.substring(5, 7), 16) / 255,
            0.3
        )
        border.color: currentLabelColor
        border.width: 2
        visible: false
        z: 1

        states: State {
            name: "visible"
            when: labelingModeActive && selectionStart >= 0 && selectionEnd >= 0
            PropertyChanges {
                target: selectionOverlay
                visible: true
                x: {
                    if (!dataLoaded || !appController.sampleRate) return 0
                    var startTime = selectionStart / appController.sampleRate
                    var pos = chart.mapToPosition(Qt.point(startTime, 0), lineSeries)
                    return pos.x
                }
                width: {
                    if (!dataLoaded || !appController.sampleRate) return 0
                    var startTime = selectionStart / appController.sampleRate
                    var endTime = selectionEnd / appController.sampleRate
                    var startPos = chart.mapToPosition(Qt.point(startTime, 0), lineSeries)
                    var endPos = chart.mapToPosition(Qt.point(endTime, 0), lineSeries)
                    return endPos.x - startPos.x
                }
            }
        }
    }

    // Zoom box preview rectangle
    Rectangle {
        id: zoomBoxPreview
        parent: chart
        y: chart.plotArea.y
        height: chart.plotArea.height
        color: Qt.rgba(0.0, 0.67, 1.0, 0.2)  // Light blue with transparency
        border.color: "#00aaff"
        border.width: 2
        visible: false
        z: 1

        // Time labels for zoom box
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 2
            width: startTimeText.width + 8
            height: startTimeText.height + 4
            color: "#00aaff"
            radius: 2
            visible: parent.visible

            Text {
                id: startTimeText
                anchors.centerIn: parent
                text: {
                    if (!zoomModeActive || zoomBoxStartX < 0) return ""
                    var minX = Math.min(zoomBoxStartX, zoomBoxEndX)
                    var pos = chart.mapToValue(Qt.point(minX, chart.plotArea.y), lineSeries)
                    return pos.x.toFixed(3) + "s"
                }
                color: "#0a0e1a"
                font.pixelSize: 9
                font.bold: true
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 2
            width: endTimeText.width + 8
            height: endTimeText.height + 4
            color: "#00aaff"
            radius: 2
            visible: parent.visible

            Text {
                id: endTimeText
                anchors.centerIn: parent
                text: {
                    if (!zoomModeActive || zoomBoxStartX < 0) return ""
                    var maxX = Math.max(zoomBoxStartX, zoomBoxEndX)
                    var pos = chart.mapToValue(Qt.point(maxX, chart.plotArea.y), lineSeries)
                    return pos.x.toFixed(3) + "s"
                }
                color: "#0a0e1a"
                font.pixelSize: 9
                font.bold: true
            }
        }
    }

    // Container for label overlays
    Item {
        id: labelOverlayContainer
        x: chart.x + chart.plotArea.x
        y: chart.y + chart.plotArea.y
        width: chart.plotArea.width
        height: chart.plotArea.height
        z: 2  // Higher z-index to ensure labels always appear above selections
    }

    // Labeling mode indicator
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: labelModeText.width + 20
        height: 35
        color: "#00ff88"
        radius: 4
        visible: labelingModeActive && dataLoaded
        z: 2

        Text {
            id: labelModeText
            anchors.centerIn: parent
            text: "Labeling Mode Active - Drag to select"
            color: "#0a0e1a"
            font.pixelSize: 11
            font.bold: true
        }
    }

    // Zoom mode indicator
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: zoomModeText.width + 20
        height: 35
        color: "#00aaff"
        radius: 4
        visible: zoomModeActive && dataLoaded && !labelingModeActive
        z: 2

        Text {
            id: zoomModeText
            anchors.centerIn: parent
            text: "Zoom Mode Active - Drag to select time region"
            color: "#0a0e1a"
            font.pixelSize: 11
            font.bold: true
        }
    }

    // Empty state
    Column {
        anchors.centerIn: parent
        spacing: 15
        visible: !dataLoaded

        Rectangle {
            width: 80
            height: 80
            anchors.horizontalCenter: parent.horizontalCenter
            color: "transparent"
            border.color: "#2a3f5f"
            border.width: 2
            radius: 40

            Text {
                anchors.centerIn: parent
                text: "~"
                font.pixelSize: 48
                color: "#2a3f5f"
                font.bold: true
            }
        }

        Text {
            text: "No data loaded"
            font.pixelSize: 16
            color: "#505050"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Click 'Load ACQ File' to begin"
            font.pixelSize: 12
            color: "#505050"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Selection indicator
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 10
        anchors.bottomMargin: 60
        width: selectionText.width + 20
        height: 35
        color: "#00aaff"
        radius: 4
        visible: labelingModeActive && selectionStart >= 0 && selectionEnd >= 0
        z: 3

        Text {
            id: selectionText
            anchors.centerIn: parent
            text: {
                if (selectionStart >= 0 && selectionEnd >= 0 && appController.sampleRate > 0) {
                    var startTime = (selectionStart / appController.sampleRate).toFixed(3)
                    var endTime = (selectionEnd / appController.sampleRate).toFixed(3)
                    var duration = ((selectionEnd - selectionStart) / appController.sampleRate).toFixed(3)
                    return "Selected: " + startTime + "s - " + endTime + "s (Duration: " + duration + "s)"
                }
                return ""
            }
            color: "#0a0e1a"
            font.pixelSize: 10
            font.bold: true
        }
    }

    // Listen to label manager changes
    Connections {
        target: labelManager

        function onLabelsChanged() {
            console.log("Labels changed - updating overlays")
            updateLabelOverlays()
        }

        function onLabelRemoved(labelId) {
            console.log("Label removed:", labelId, "- updating overlays")
            updateLabelOverlays()
        }
    }
}
