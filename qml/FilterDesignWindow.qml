import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtCharts 2.15

Window {
    id: filterWindow
    width: 1100
    height: 650
    minimumWidth: 900
    minimumHeight: 500
    title: "Signal Processing & Filtering Settings"
    modality: Qt.ApplicationModal
    color: "#d0d0d0"

    property string currentFilterType: "bandpass"
    property int lowpassOrderValue: 4
    property int highpassOrderValue: 4
    property int bandpassOrderValue: 4
    property real notchFrequency: 50.0  // Default 50 Hz

    onLowpassOrderValueChanged: updateFrequencyResponse()
    onHighpassOrderValueChanged: updateFrequencyResponse()
    onBandpassOrderValueChanged: updateFrequencyResponse()

    Component.onCompleted: {
        updateFrequencyResponse()
    }

    // Function to update frequency response preview
    function updateFrequencyResponse() {
        frequencyResponseSeries.clear()

        var sampleRate = appController.sampleRate
        if (sampleRate <= 0) sampleRate = 1000  // Default if no data loaded

        var nyquist = sampleRate / 2
        var numPoints = 200

        for (var i = 0; i < numPoints; i++) {
            var freq = (i / numPoints) * nyquist
            var magnitude = calculateFilterMagnitude(freq, sampleRate)
            frequencyResponseSeries.append(freq, magnitude)
        }
    }

    // Calculate filter magnitude response at given frequency
    function calculateFilterMagnitude(freq, sampleRate) {
        var nyquist = sampleRate / 2
        var normalizedFreq = freq / nyquist

        if (lowpassSwitch.checked) {
            var cutoff = lowpassSlider.value / nyquist
            var ratio = normalizedFreq / cutoff
            var order = lowpassOrderValue
            var magnitude = 1.0 / Math.sqrt(1 + Math.pow(ratio, 2 * order))
            return 20 * Math.log10(magnitude)
        } else if (highpassSwitch.checked) {
            var cutoff = highpassSlider.value / nyquist
            var ratio = cutoff / normalizedFreq
            var order = highpassOrderValue
            var magnitude = 1.0 / Math.sqrt(1 + Math.pow(ratio, 2 * order))
            return 20 * Math.log10(magnitude)
        } else if (bandpassSwitch.checked) {
            var lowCutoff = bandpassLowSlider.value / nyquist
            var highCutoff = bandpassHighSlider.value / nyquist
            var order = bandpassOrderValue

            // High-pass component
            var hpRatio = lowCutoff / normalizedFreq
            var hpMag = 1.0 / Math.sqrt(1 + Math.pow(hpRatio, 2 * order))

            // Low-pass component
            var lpRatio = normalizedFreq / highCutoff
            var lpMag = 1.0 / Math.sqrt(1 + Math.pow(lpRatio, 2 * order))

            var magnitude = hpMag * lpMag
            return 20 * Math.log10(magnitude)
        } else if (notchSwitch.checked) {
            var notchFreq = notchFrequency
            var q = 30  // Quality factor
            var bandwidth = notchFreq / q
            var distance = Math.abs(freq - notchFreq)
            var magnitude = distance / Math.sqrt(distance * distance + bandwidth * bandwidth)
            return 20 * Math.log10(magnitude)
        }

        return 0  // No filter active
    }

    Rectangle {
        anchors.fill: parent
        color: "#d0d0d0"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            // Main window frame
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#0a0e1a"
                border.color: "#2a3f5f"
                border.width: 2
                radius: 6

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 0
                    spacing: 0

                    // Top menu bar
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        color: "#13182b"
                        border.color: "#2a3f5f"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15
                            spacing: 15

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
                                        text: "N"
                                        color: "#00aaff"
                                        font.bold: true
                                        font.pixelSize: 14
                                    }
                                }

                                Text {
                                    text: "NeuroSignal DSP"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#e0e0e0"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            TabBar {
                                id: tabBar
                                Layout.fillWidth: true
                                background: Rectangle {
                                    color: "transparent"
                                }

                                TabButton {
                                    text: "Filters"
                                    width: 120
                                    background: Rectangle {
                                        color: parent.checked ? "#1a2844" : "transparent"
                                        border.color: parent.checked ? "#00aaff" : "transparent"
                                        border.width: parent.checked ? 1 : 0
                                    }
                                    contentItem: Text {
                                        text: parent.text
                                        font.pixelSize: 12
                                        color: parent.checked ? "#00aaff" : "#b0b0b0"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                TabButton {
                                    text: "Processing"
                                    width: 120
                                    background: Rectangle {
                                        color: parent.checked ? "#1a2844" : "transparent"
                                        border.color: parent.checked ? "#00aaff" : "transparent"
                                        border.width: parent.checked ? 1 : 0
                                    }
                                    contentItem: Text {
                                        text: parent.text
                                        font.pixelSize: 12
                                        color: parent.checked ? "#00aaff" : "#b0b0b0"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                TabButton {
                                    text: "Analysis"
                                    width: 120
                                    background: Rectangle {
                                        color: parent.checked ? "#1a2844" : "transparent"
                                        border.color: parent.checked ? "#00aaff" : "transparent"
                                        border.width: parent.checked ? 1 : 0
                                    }
                                    contentItem: Text {
                                        text: parent.text
                                        font.pixelSize: 12
                                        color: parent.checked ? "#00aaff" : "#b0b0b0"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                TabButton {
                                    text: "Export"
                                    width: 120
                                    background: Rectangle {
                                        color: parent.checked ? "#1a2844" : "transparent"
                                        border.color: parent.checked ? "#00aaff" : "transparent"
                                        border.width: parent.checked ? 1 : 0
                                    }
                                    contentItem: Text {
                                        text: parent.text
                                        font.pixelSize: 12
                                        color: parent.checked ? "#00aaff" : "#b0b0b0"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }

                            Text {
                                visible: appController.hasData
                                text: appController.currentFile ? appController.currentFile.split('/').pop() : ""
                                font.pixelSize: 10
                                color: "#707070"
                            }

                            Rectangle {
                                width: 20
                                height: 20
                                color: "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "⚙"
                                    font.pixelSize: 14
                                    color: "#b0b0b0"
                                }
                            }

                            Rectangle {
                                width: 20
                                height: 20
                                color: "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "?"
                                    font.pixelSize: 14
                                    color: "#b0b0b0"
                                }
                            }
                        }
                    }

                    // Main content area
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 0

                        // Left side - Preview/Waveform area
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "#0a0e1a"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 15

                                // Signal info bar
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 60
                                    color: "#13182b"
                                    border.color: "#2a3f5f"
                                    border.width: 1
                                    radius: 4

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 15
                                        spacing: 40

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 4

                                            Text {
                                                text: "RMS AMPLITUDE"
                                                font.pixelSize: 9
                                                color: "#707070"
                                                font.bold: true
                                            }

                                            Text {
                                                text: appController.hasData ? "342.5 µV" : "--"
                                                font.pixelSize: 14
                                                color: "#e0e0e0"
                                                font.bold: true
                                            }
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 4

                                            Text {
                                                text: "MEAN FREQ"
                                                font.pixelSize: 9
                                                color: "#707070"
                                                font.bold: true
                                            }

                                            Text {
                                                text: appController.hasData ? appController.sampleRate.toFixed(0) + " Hz" : "--"
                                                font.pixelSize: 14
                                                color: "#e0e0e0"
                                                font.bold: true
                                            }
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 4

                                            Text {
                                                text: "SAMPLE RATE"
                                                font.pixelSize: 9
                                                color: "#707070"
                                                font.bold: true
                                            }

                                            Text {
                                                text: appController.hasData ? appController.sampleRate.toFixed(0) + " Hz" : "--"
                                                font.pixelSize: 14
                                                color: "#e0e0e0"
                                                font.bold: true
                                            }
                                        }
                                    }
                                }

                                // Filter type indicator
                                Text {
                                    Layout.fillWidth: true
                                    text: {
                                        var filterName = "No Filter Active"
                                        if (lowpassSwitch.checked) filterName = "Lowpass Filter (Cutoff: " + lowpassSlider.value.toFixed(0) + " Hz, Order: " + lowpassOrderValue + ")"
                                        else if (highpassSwitch.checked) filterName = "Highpass Filter (Cutoff: " + highpassSlider.value.toFixed(0) + " Hz, Order: " + highpassOrderValue + ")"
                                        else if (bandpassSwitch.checked) filterName = "Bandpass Filter (Low: " + bandpassLowSlider.value.toFixed(0) + " Hz, High: " + bandpassHighSlider.value.toFixed(0) + " Hz, Order: " + bandpassOrderValue + ")"
                                        else if (notchSwitch.checked) filterName = "Notch Filter (" + notchFrequency.toFixed(0) + " Hz)"
                                        return filterName
                                    }
                                    font.pixelSize: 11
                                    color: "#00aaff"
                                    horizontalAlignment: Text.AlignHCenter
                                    font.bold: true
                                }

                                // Frequency Response Chart
                                ChartView {
                                    id: frequencyResponseChart
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    backgroundColor: "#0a0e1a"
                                    theme: ChartView.ChartThemeDark
                                    antialiasing: true
                                    legend.visible: false
                                    margins.top: 0
                                    margins.bottom: 0
                                    margins.left: 0
                                    margins.right: 0

                                    ValueAxis {
                                        id: freqAxis
                                        titleText: "Frequency (Hz)"
                                        min: 0
                                        max: appController.hasData ? (appController.sampleRate / 2) : 500
                                        color: "#505050"
                                        labelsColor: "#b0b0b0"
                                        gridLineColor: "#1a2844"
                                        titleFont.pixelSize: 10
                                        labelsFont.pixelSize: 9
                                    }

                                    ValueAxis {
                                        id: magAxis
                                        titleText: "Magnitude (dB)"
                                        min: -60
                                        max: 5
                                        color: "#505050"
                                        labelsColor: "#b0b0b0"
                                        gridLineColor: "#1a2844"
                                        titleFont.pixelSize: 10
                                        labelsFont.pixelSize: 9
                                    }

                                    LineSeries {
                                        id: frequencyResponseSeries
                                        name: "Frequency Response"
                                        axisX: freqAxis
                                        axisY: magAxis
                                        color: "#00aaff"
                                        width: 2
                                    }

                                    // -3dB reference line
                                    LineSeries {
                                        id: cutoffLine
                                        axisX: freqAxis
                                        axisY: magAxis
                                        color: "#ff6b6b"
                                        width: 1
                                        style: Qt.DashLine
                                    }

                                    Component.onCompleted: {
                                        // Add -3dB reference line
                                        cutoffLine.append(0, -3)
                                        cutoffLine.append(freqAxis.max, -3)
                                    }

                                    Text {
                                        visible: !appController.hasData
                                        anchors.centerIn: parent
                                        text: "Load signal to see filter response"
                                        font.pixelSize: 12
                                        color: "#505050"
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                // Bottom control bar
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    color: "#13182b"
                                    border.color: "#2a3f5f"
                                    border.width: 1
                                    radius: 4

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 15

                                        Button {
                                            width: 30
                                            height: 28
                                            text: "◄◄"

                                            background: Rectangle {
                                                color: parent.hovered ? "#2a3f5f" : "#1a2844"
                                                border.color: "#2a3f5f"
                                                border.width: 1
                                                radius: 3
                                            }

                                            contentItem: Text {
                                                text: parent.text
                                                font.pixelSize: 10
                                                color: "#b0b0b0"
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                        }

                                        Button {
                                            width: 40
                                            height: 28
                                            text: "▶"
                                            enabled: appController.hasData

                                            background: Rectangle {
                                                color: parent.enabled ? "#00aaff" : "#1a2844"
                                                radius: 3
                                            }

                                            contentItem: Text {
                                                text: parent.text
                                                font.pixelSize: 12
                                                color: parent.enabled ? "#0a0e1a" : "#505050"
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                        }

                                        Button {
                                            width: 30
                                            height: 28
                                            text: "►►"

                                            background: Rectangle {
                                                color: parent.hovered ? "#2a3f5f" : "#1a2844"
                                                border.color: "#2a3f5f"
                                                border.width: 1
                                                radius: 3
                                            }

                                            contentItem: Text {
                                                text: parent.text
                                                font.pixelSize: 10
                                                color: "#b0b0b0"
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "00:00:21.4 / 00:00:36.00"
                                            font.pixelSize: 10
                                            font.family: "monospace"
                                            color: "#b0b0b0"
                                        }
                                    }
                                }
                            }
                        }

                        // Right side - Filter controls
                        Rectangle {
                            Layout.preferredWidth: 380
                            Layout.fillHeight: true
                            color: "#13182b"
                            border.color: "#2a3f5f"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 15

                                Text {
                                    text: "Filters"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: "#e0e0e0"
                                }

                                // Configuration preset
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: "CONFIGURATION PRESET"
                                        font.pixelSize: 9
                                        color: "#707070"
                                        font.bold: true
                                    }

                                    ComboBox {
                                        width: parent.width
                                        model: ["Standard EMG Processing", "Custom"]

                                        background: Rectangle {
                                            color: "#1a2844"
                                            border.color: "#2a3f5f"
                                            border.width: 1
                                            radius: 4
                                        }

                                        contentItem: Text {
                                            text: parent.displayText
                                            font.pixelSize: 11
                                            color: "#e0e0e0"
                                            leftPadding: 10
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: "#2a3f5f"
                                }

                                // Lowpass Filter section
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    Row {
                                        width: parent.width
                                        spacing: 10

                                        Rectangle {
                                            width: 3
                                            height: 20
                                            color: "#00aaff"
                                            radius: 2
                                        }

                                        Text {
                                            text: "Lowpass Filter"
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: "#e0e0e0"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Rectangle {
                                            width: parent.width - 200
                                            height: 1
                                        }

                                        Switch {
                                            id: lowpassSwitch
                                            checked: false
                                            anchors.verticalCenter: parent.verticalCenter
                                            onCheckedChanged: updateFrequencyResponse()

                                            indicator: Rectangle {
                                                implicitWidth: 40
                                                implicitHeight: 20
                                                x: parent.leftPadding
                                                y: parent.height / 2 - height / 2
                                                radius: 10
                                                color: parent.checked ? "#00aaff" : "#2a3f5f"
                                                border.color: parent.checked ? "#00aaff" : "#2a3f5f"

                                                Rectangle {
                                                    x: parent.parent.checked ? parent.width - width - 2 : 2
                                                    y: 2
                                                    width: 16
                                                    height: 16
                                                    radius: 8
                                                    color: "#e0e0e0"

                                                    Behavior on x {
                                                        NumberAnimation { duration: 100 }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Cutoff slider
                                    Column {
                                        width: parent.width
                                        spacing: 6
                                        enabled: lowpassSwitch.checked

                                        Row {
                                            width: parent.width
                                            spacing: 10

                                            Text {
                                                text: "Cutoff Frequency"
                                                font.pixelSize: 10
                                                color: parent.parent.enabled ? "#b0b0b0" : "#505050"
                                                width: 160
                                            }

                                            Text {
                                                text: lowpassSlider.value.toFixed(0) + " Hz"
                                                font.pixelSize: 10
                                                color: parent.parent.enabled ? "#00aaff" : "#505050"
                                                font.bold: true
                                            }
                                        }

                                        Slider {
                                            id: lowpassSlider
                                            width: parent.width
                                            from: 10
                                            to: 1000
                                            value: 450
                                            stepSize: 10
                                            onValueChanged: updateFrequencyResponse()

                                            background: Rectangle {
                                                x: lowpassSlider.leftPadding
                                                y: lowpassSlider.topPadding + lowpassSlider.availableHeight / 2 - height / 2
                                                implicitWidth: 200
                                                implicitHeight: 4
                                                width: lowpassSlider.availableWidth
                                                height: implicitHeight
                                                radius: 2
                                                color: "#2a3f5f"

                                                Rectangle {
                                                    width: lowpassSlider.visualPosition * parent.width
                                                    height: parent.height
                                                    color: lowpassSlider.enabled ? "#00aaff" : "#505050"
                                                    radius: 2
                                                }
                                            }

                                            handle: Rectangle {
                                                x: lowpassSlider.leftPadding + lowpassSlider.visualPosition * (lowpassSlider.availableWidth - width)
                                                y: lowpassSlider.topPadding + lowpassSlider.availableHeight / 2 - height / 2
                                                implicitWidth: 16
                                                implicitHeight: 16
                                                radius: 8
                                                color: lowpassSlider.pressed ? "#ffffff" : "#e0e0e0"
                                                border.color: lowpassSlider.enabled ? "#00aaff" : "#505050"
                                                border.width: 2
                                            }
                                        }
                                    }

                                    // Filter Order
                                    Row {
                                        width: parent.width
                                        spacing: 10
                                        enabled: lowpassSwitch.checked

                                        Text {
                                            text: "Filter Order:"
                                            font.pixelSize: 10
                                            color: parent.enabled ? "#b0b0b0" : "#505050"
                                            width: 160
                                        }

                                        SpinBox {
                                            width: 120
                                            height: 28
                                            from: 1
                                            to: 10
                                            value: lowpassOrderValue
                                            onValueChanged: lowpassOrderValue = value
                                            editable: true

                                            background: Rectangle {
                                                color: "#1a2844"
                                                border.color: "#2a3f5f"
                                                border.width: 1
                                                radius: 3
                                            }

                                            contentItem: TextInput {
                                                text: parent.value
                                                font.pixelSize: 10
                                                color: "#b0b0b0"
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                readOnly: !parent.editable
                                                validator: IntValidator {
                                                    bottom: parent.parent.from
                                                    top: parent.parent.to
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: "#2a3f5f"
                                }

                                // Highpass Filter section
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    Row {
                                        width: parent.width
                                        spacing: 10

                                        Rectangle {
                                            width: 3
                                            height: 20
                                            color: "#00aaff"
                                            radius: 2
                                        }

                                        Text {
                                            text: "Highpass Filter"
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: "#e0e0e0"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Rectangle {
                                            width: parent.width - 200
                                            height: 1
                                        }

                                        Switch {
                                            id: highpassSwitch
                                            checked: false
                                            anchors.verticalCenter: parent.verticalCenter
                                            onCheckedChanged: updateFrequencyResponse()

                                            indicator: Rectangle {
                                                implicitWidth: 40
                                                implicitHeight: 20
                                                x: parent.leftPadding
                                                y: parent.height / 2 - height / 2
                                                radius: 10
                                                color: parent.checked ? "#00aaff" : "#2a3f5f"
                                                border.color: parent.checked ? "#00aaff" : "#2a3f5f"

                                                Rectangle {
                                                    x: parent.parent.checked ? parent.width - width - 2 : 2
                                                    y: 2
                                                    width: 16
                                                    height: 16
                                                    radius: 8
                                                    color: "#e0e0e0"

                                                    Behavior on x {
                                                        NumberAnimation { duration: 100 }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Cutoff slider
                                    Column {
                                        width: parent.width
                                        spacing: 6
                                        enabled: highpassSwitch.checked

                                        Row {
                                            width: parent.width
                                            spacing: 10

                                            Text {
                                                text: "Cutoff Frequency"
                                                font.pixelSize: 10
                                                color: parent.parent.enabled ? "#b0b0b0" : "#505050"
                                                width: 160
                                            }

                                            Text {
                                                text: highpassSlider.value.toFixed(0) + " Hz"
                                                font.pixelSize: 10
                                                color: parent.parent.enabled ? "#00aaff" : "#505050"
                                                font.bold: true
                                            }
                                        }

                                        Slider {
                                            id: highpassSlider
                                            width: parent.width
                                            from: 1
                                            to: 500
                                            value: 20
                                            stepSize: 1
                                            onValueChanged: updateFrequencyResponse()

                                            background: Rectangle {
                                                x: highpassSlider.leftPadding
                                                y: highpassSlider.topPadding + highpassSlider.availableHeight / 2 - height / 2
                                                implicitWidth: 200
                                                implicitHeight: 4
                                                width: highpassSlider.availableWidth
                                                height: implicitHeight
                                                radius: 2
                                                color: "#2a3f5f"

                                                Rectangle {
                                                    width: highpassSlider.visualPosition * parent.width
                                                    height: parent.height
                                                    color: highpassSlider.enabled ? "#00aaff" : "#505050"
                                                    radius: 2
                                                }
                                            }

                                            handle: Rectangle {
                                                x: highpassSlider.leftPadding + highpassSlider.visualPosition * (highpassSlider.availableWidth - width)
                                                y: highpassSlider.topPadding + highpassSlider.availableHeight / 2 - height / 2
                                                implicitWidth: 16
                                                implicitHeight: 16
                                                radius: 8
                                                color: highpassSlider.pressed ? "#ffffff" : "#e0e0e0"
                                                border.color: highpassSlider.enabled ? "#00aaff" : "#505050"
                                                border.width: 2
                                            }
                                        }
                                    }

                                    // Filter Order
                                    Row {
                                        width: parent.width
                                        spacing: 10
                                        enabled: highpassSwitch.checked

                                        Text {
                                            text: "Filter Order:"
                                            font.pixelSize: 10
                                            color: parent.enabled ? "#b0b0b0" : "#505050"
                                            width: 160
                                        }

                                        SpinBox {
                                            width: 120
                                            height: 28
                                            from: 1
                                            to: 10
                                            value: highpassOrderValue
                                            onValueChanged: highpassOrderValue = value
                                            editable: true

                                            background: Rectangle {
                                                color: "#1a2844"
                                                border.color: "#2a3f5f"
                                                border.width: 1
                                                radius: 3
                                            }

                                            contentItem: TextInput {
                                                text: parent.value
                                                font.pixelSize: 10
                                                color: "#b0b0b0"
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                readOnly: !parent.editable
                                                validator: IntValidator {
                                                    bottom: parent.parent.from
                                                    top: parent.parent.to
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: "#2a3f5f"
                                }

                                // Bandpass Filter section
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    Row {
                                        width: parent.width
                                        spacing: 10

                                        Rectangle {
                                            width: 3
                                            height: 20
                                            color: "#00aaff"
                                            radius: 2
                                        }

                                        Text {
                                            text: "Bandpass Filter"
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: "#e0e0e0"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Rectangle {
                                            width: parent.width - 200
                                            height: 1
                                        }

                                        Switch {
                                            id: bandpassSwitch
                                            checked: false
                                            anchors.verticalCenter: parent.verticalCenter
                                            onCheckedChanged: updateFrequencyResponse()

                                            indicator: Rectangle {
                                                implicitWidth: 40
                                                implicitHeight: 20
                                                x: parent.leftPadding
                                                y: parent.height / 2 - height / 2
                                                radius: 10
                                                color: parent.checked ? "#00aaff" : "#2a3f5f"
                                                border.color: parent.checked ? "#00aaff" : "#2a3f5f"

                                                Rectangle {
                                                    x: parent.parent.checked ? parent.width - width - 2 : 2
                                                    y: 2
                                                    width: 16
                                                    height: 16
                                                    radius: 8
                                                    color: "#e0e0e0"

                                                    Behavior on x {
                                                        NumberAnimation { duration: 100 }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Low Cutoff
                                    Column {
                                        width: parent.width
                                        spacing: 6
                                        enabled: bandpassSwitch.checked

                                        Row {
                                            width: parent.width
                                            spacing: 10

                                            Text {
                                                text: "Low Cutoff (High Pass)"
                                                font.pixelSize: 10
                                                color: parent.parent.enabled ? "#b0b0b0" : "#505050"
                                                width: 160
                                            }

                                            Text {
                                                text: bandpassLowSlider.value.toFixed(0) + " Hz"
                                                font.pixelSize: 10
                                                color: parent.parent.enabled ? "#00aaff" : "#505050"
                                                font.bold: true
                                            }
                                        }

                                        Slider {
                                            id: bandpassLowSlider
                                            width: parent.width
                                            from: 1
                                            to: 500
                                            value: 20
                                            stepSize: 1
                                            onValueChanged: updateFrequencyResponse()

                                            background: Rectangle {
                                                x: bandpassLowSlider.leftPadding
                                                y: bandpassLowSlider.topPadding + bandpassLowSlider.availableHeight / 2 - height / 2
                                                implicitWidth: 200
                                                implicitHeight: 4
                                                width: bandpassLowSlider.availableWidth
                                                height: implicitHeight
                                                radius: 2
                                                color: "#2a3f5f"

                                                Rectangle {
                                                    width: bandpassLowSlider.visualPosition * parent.width
                                                    height: parent.height
                                                    color: bandpassLowSlider.enabled ? "#00aaff" : "#505050"
                                                    radius: 2
                                                }
                                            }

                                            handle: Rectangle {
                                                x: bandpassLowSlider.leftPadding + bandpassLowSlider.visualPosition * (bandpassLowSlider.availableWidth - width)
                                                y: bandpassLowSlider.topPadding + bandpassLowSlider.availableHeight / 2 - height / 2
                                                implicitWidth: 16
                                                implicitHeight: 16
                                                radius: 8
                                                color: bandpassLowSlider.pressed ? "#ffffff" : "#e0e0e0"
                                                border.color: bandpassLowSlider.enabled ? "#00aaff" : "#505050"
                                                border.width: 2
                                            }
                                        }
                                    }

                                    // High Cutoff
                                    Column {
                                        width: parent.width
                                        spacing: 6
                                        enabled: bandpassSwitch.checked

                                        Row {
                                            width: parent.width
                                            spacing: 10

                                            Text {
                                                text: "High Cutoff (Low Pass)"
                                                font.pixelSize: 10
                                                color: parent.parent.enabled ? "#b0b0b0" : "#505050"
                                                width: 160
                                            }

                                            Text {
                                                text: bandpassHighSlider.value.toFixed(0) + " Hz"
                                                font.pixelSize: 10
                                                color: parent.parent.enabled ? "#00aaff" : "#505050"
                                                font.bold: true
                                            }
                                        }

                                        Slider {
                                            id: bandpassHighSlider
                                            width: parent.width
                                            from: 10
                                            to: 1000
                                            value: 450
                                            stepSize: 10
                                            onValueChanged: updateFrequencyResponse()

                                            background: Rectangle {
                                                x: bandpassHighSlider.leftPadding
                                                y: bandpassHighSlider.topPadding + bandpassHighSlider.availableHeight / 2 - height / 2
                                                implicitWidth: 200
                                                implicitHeight: 4
                                                width: bandpassHighSlider.availableWidth
                                                height: implicitHeight
                                                radius: 2
                                                color: "#2a3f5f"

                                                Rectangle {
                                                    width: bandpassHighSlider.visualPosition * parent.width
                                                    height: parent.height
                                                    color: bandpassHighSlider.enabled ? "#00aaff" : "#505050"
                                                    radius: 2
                                                }
                                            }

                                            handle: Rectangle {
                                                x: bandpassHighSlider.leftPadding + bandpassHighSlider.visualPosition * (bandpassHighSlider.availableWidth - width)
                                                y: bandpassHighSlider.topPadding + bandpassHighSlider.availableHeight / 2 - height / 2
                                                implicitWidth: 16
                                                implicitHeight: 16
                                                radius: 8
                                                color: bandpassHighSlider.pressed ? "#ffffff" : "#e0e0e0"
                                                border.color: bandpassHighSlider.enabled ? "#00aaff" : "#505050"
                                                border.width: 2
                                            }
                                        }
                                    }

                                    // Filter Order
                                    Row {
                                        width: parent.width
                                        spacing: 10
                                        enabled: bandpassSwitch.checked

                                        Text {
                                            text: "Filter Order (Steepness):"
                                            font.pixelSize: 10
                                            color: parent.enabled ? "#b0b0b0" : "#505050"
                                            width: 160
                                        }

                                        SpinBox {
                                            width: 120
                                            height: 28
                                            from: 1
                                            to: 10
                                            value: bandpassOrderValue
                                            onValueChanged: bandpassOrderValue = value
                                            editable: true

                                            background: Rectangle {
                                                color: "#1a2844"
                                                border.color: "#2a3f5f"
                                                border.width: 1
                                                radius: 3
                                            }

                                            contentItem: TextInput {
                                                text: parent.value
                                                font.pixelSize: 10
                                                color: "#b0b0b0"
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                readOnly: !parent.editable
                                                validator: IntValidator {
                                                    bottom: parent.parent.from
                                                    top: parent.parent.to
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: "#2a3f5f"
                                }

                                // Mains Notch section
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    Row {
                                        width: parent.width
                                        spacing: 10

                                        Rectangle {
                                            width: 3
                                            height: 20
                                            color: "#00aaff"
                                            radius: 2
                                        }

                                        Text {
                                            text: "Mains Notch"
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: "#e0e0e0"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Rectangle {
                                            width: parent.width - 200
                                            height: 1
                                        }

                                        Switch {
                                            id: notchSwitch
                                            checked: true
                                            anchors.verticalCenter: parent.verticalCenter
                                            onCheckedChanged: updateFrequencyResponse()

                                            indicator: Rectangle {
                                                implicitWidth: 40
                                                implicitHeight: 20
                                                x: parent.leftPadding
                                                y: parent.height / 2 - height / 2
                                                radius: 10
                                                color: parent.checked ? "#00aaff" : "#2a3f5f"
                                                border.color: parent.checked ? "#00aaff" : "#2a3f5f"

                                                Rectangle {
                                                    x: parent.parent.checked ? parent.width - width - 2 : 2
                                                    y: 2
                                                    width: 16
                                                    height: 16
                                                    radius: 8
                                                    color: "#e0e0e0"

                                                    Behavior on x {
                                                        NumberAnimation { duration: 100 }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Row {
                                        spacing: 10
                                        enabled: notchSwitch.checked

                                        Button {
                                            id: notch50Button
                                            width: 80
                                            height: 32
                                            text: "50 Hz"
                                            checkable: true
                                            checked: true
                                            onClicked: {
                                                notchFrequency = 50.0
                                                notch60Button.checked = false
                                                updateFrequencyResponse()
                                            }

                                            background: Rectangle {
                                                color: parent.checked ? "#00aaff" : "#1a2844"
                                                border.color: "#2a3f5f"
                                                border.width: 1
                                                radius: 4
                                            }

                                            contentItem: Column {
                                                spacing: 0

                                                Text {
                                                    text: parent.parent.text
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: parent.parent.checked ? "#0a0e1a" : "#b0b0b0"
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                }

                                                Text {
                                                    text: "Europe / Asia"
                                                    font.pixelSize: 7
                                                    color: parent.parent.parent.checked ? "#0a0e1a" : "#707070"
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                }
                                            }
                                        }

                                        Button {
                                            id: notch60Button
                                            width: 80
                                            height: 32
                                            text: "60 Hz"
                                            checkable: true
                                            onClicked: {
                                                notchFrequency = 60.0
                                                notch50Button.checked = false
                                                updateFrequencyResponse()
                                            }

                                            background: Rectangle {
                                                color: parent.checked ? "#00aaff" : "#1a2844"
                                                border.color: "#2a3f5f"
                                                border.width: 1
                                                radius: 4
                                            }

                                            contentItem: Column {
                                                spacing: 0

                                                Text {
                                                    text: parent.parent.text
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: parent.parent.checked ? "#0a0e1a" : "#b0b0b0"
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                }

                                                Text {
                                                    text: "Americas"
                                                    font.pixelSize: 7
                                                    color: parent.parent.parent.checked ? "#0a0e1a" : "#707070"
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillHeight: true
                                }

                                // Bottom action buttons
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Button {
                                        width: parent.width
                                        height: 40
                                        text: "Reset Defaults"
                                        enabled: appController.hasData

                                        background: Rectangle {
                                            color: parent.hovered ? "#2a3f5f" : "#1a2844"
                                            border.color: "#2a3f5f"
                                            border.width: 1
                                            radius: 4
                                        }

                                        contentItem: Text {
                                            text: parent.text
                                            font.pixelSize: 11
                                            color: parent.enabled ? "#b0b0b0" : "#505050"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        onClicked: {
                                            console.log("Resetting to default filter settings")
                                            appController.resetToOriginal()
                                        }
                                    }

                                    Button {
                                        width: parent.width
                                        height: 46
                                        text: "Apply Configuration"
                                        enabled: appController.hasData

                                        background: Rectangle {
                                            color: parent.enabled ? (parent.hovered ? "#0099dd" : "#00aaff") : "#1a2844"
                                            radius: 4
                                        }

                                        contentItem: Text {
                                            text: parent.text
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: parent.enabled ? "#0a0e1a" : "#505050"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        onClicked: applyFilter()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function applyFilter() {
        var filtered

        if (lowpassSwitch.checked) {
            var cutoff = lowpassSlider.value
            var order = lowpassOrderValue

            console.log("Applying lowpass filter:", cutoff, "Hz, order", order)
            filtered = filterController.applyLowpass(cutoff, order)
        } else if (highpassSwitch.checked) {
            var cutoff = highpassSlider.value
            var order = highpassOrderValue

            console.log("Applying highpass filter:", cutoff, "Hz, order", order)
            filtered = filterController.applyHighpass(cutoff, order)
        } else if (bandpassSwitch.checked) {
            var low = bandpassLowSlider.value
            var high = bandpassHighSlider.value
            var order = bandpassOrderValue

            console.log("Applying bandpass filter:", low, "-", high, "Hz, order", order)
            filtered = filterController.applyBandpass(low, high, order)
        } else {
            console.log("No filters enabled")
            return
        }

        console.log("Filter returned:", filtered ? filtered.length : 0, "points")

        if (filtered && filtered.length > 0) {
            console.log("Applying filter with", filtered.length, "points")
            appController.applyFilteredData(filtered)
            console.log("Filter applied successfully")
            filterWindow.close()
        } else {
            console.error("Filter failed or returned no data")
            console.error("  Has data:", filterController.hasData)
            console.error("  Sample rate:", filterController.getSampleRate())
        }
    }
}
