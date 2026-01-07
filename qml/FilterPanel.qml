import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: filterPanel
    color: "white"
    radius: 5
    border.color: "#ddd"
    border.width: 1

    signal filterApplied(var filteredData)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Header
        Text {
            text: "DSP Filters"
            font.pixelSize: 16
            font.bold: true
            color: "#2196F3"
        }

        // Info section
        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: "#f5f5f5"
            radius: 3

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 3

                Text {
                    text: filterController.hasData ?
                          ("Sample Rate: " + filterController.getSampleRate().toFixed(1) + " Hz") :
                          "No data loaded"
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    text: filterController.hasData ?
                          ("Nyquist Freq: " + filterController.getNyquistFrequency().toFixed(1) + " Hz") :
                          "Load a channel first"
                    font.pixelSize: 10
                    color: "#666"
                }

                Text {
                    visible: filterController.lastError !== ""
                    text: "⚠ " + filterController.lastError
                    font.pixelSize: 9
                    color: "#f44336"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 8

                // Quick Presets
                GroupBox {
                    title: "⚡ Quick Presets"
                    Layout.fillWidth: true
                    font.bold: true

                    GridLayout {
                        anchors.fill: parent
                        columns: 2
                        columnSpacing: 5
                        rowSpacing: 5

                        Button {
                            text: "Remove DC"
                            Layout.fillWidth: true
                            enabled: filterController.hasData
                            onClicked: applyPreset("dc")
                        }

                        Button {
                            text: "Remove 50Hz"
                            Layout.fillWidth: true
                            enabled: filterController.hasData
                            onClicked: applyPreset("50hz")
                        }

                        Button {
                            text: "EMG (10-500Hz)"
                            Layout.fillWidth: true
                            enabled: filterController.hasData
                            onClicked: applyPreset("emg")
                        }

                        Button {
                            text: "Smooth (50Hz)"
                            Layout.fillWidth: true
                            enabled: filterController.hasData
                            onClicked: applyPreset("smooth")
                        }

                        Button {
                            text: "Reset Original"
                            Layout.fillWidth: true
                            Layout.columnSpan: 2
                            enabled: filterController.hasData
                            highlighted: true
                            onClicked: {
                                var original = filterController.getOriginalData(5000)
                                filterApplied(original)
                            }
                        }
                    }
                }

                // Lowpass Filter
                GroupBox {
                    title: "📉 Lowpass Filter"
                    Layout.fillWidth: true

                    GridLayout {
                        anchors.fill: parent
                        columns: 2
                        columnSpacing: 5
                        rowSpacing: 5

                        Label { text: "Cutoff (Hz):" }
                        TextField {
                            id: lowpassCutoff
                            Layout.fillWidth: true
                            placeholderText: "e.g., 50"
                            validator: DoubleValidator { bottom: 0.1; top: 10000 }
                            text: "50"
                        }

                        Label { text: "Order:" }
                        SpinBox {
                            id: lowpassOrder
                            Layout.fillWidth: true
                            from: 1
                            to: 8
                            value: 4
                        }

                        Button {
                            text: "Apply Lowpass"
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            enabled: filterController.hasData && lowpassCutoff.text !== ""
                            onClicked: {
                                var cutoff = parseFloat(lowpassCutoff.text)
                                if (filterController.validateFilterParams("lowpass", cutoff, 0)) {
                                    var filtered = filterController.applyLowpass(cutoff, lowpassOrder.value)
                                    filterApplied(filtered)
                                }
                            }
                        }
                    }
                }

                // Highpass Filter
                GroupBox {
                    title: "📈 Highpass Filter"
                    Layout.fillWidth: true

                    GridLayout {
                        anchors.fill: parent
                        columns: 2
                        columnSpacing: 5
                        rowSpacing: 5

                        Label { text: "Cutoff (Hz):" }
                        TextField {
                            id: highpassCutoff
                            Layout.fillWidth: true
                            placeholderText: "e.g., 1"
                            validator: DoubleValidator { bottom: 0.1; top: 10000 }
                            text: "1"
                        }

                        Label { text: "Order:" }
                        SpinBox {
                            id: highpassOrder
                            Layout.fillWidth: true
                            from: 1
                            to: 8
                            value: 2
                        }

                        Button {
                            text: "Apply Highpass"
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            enabled: filterController.hasData && highpassCutoff.text !== ""
                            onClicked: {
                                var cutoff = parseFloat(highpassCutoff.text)
                                if (filterController.validateFilterParams("highpass", cutoff, 0)) {
                                    var filtered = filterController.applyHighpass(cutoff, highpassOrder.value)
                                    filterApplied(filtered)
                                }
                            }
                        }
                    }
                }

                // Bandpass Filter
                GroupBox {
                    title: "📊 Bandpass Filter"
                    Layout.fillWidth: true

                    GridLayout {
                        anchors.fill: parent
                        columns: 2
                        columnSpacing: 5
                        rowSpacing: 5

                        Label { text: "Low (Hz):" }
                        TextField {
                            id: bandpassLow
                            Layout.fillWidth: true
                            placeholderText: "e.g., 10"
                            validator: DoubleValidator { bottom: 0.1; top: 10000 }
                            text: "10"
                        }

                        Label { text: "High (Hz):" }
                        TextField {
                            id: bandpassHigh
                            Layout.fillWidth: true
                            placeholderText: "e.g., 500"
                            validator: DoubleValidator { bottom: 0.1; top: 10000 }
                            text: "500"
                        }

                        Label { text: "Order:" }
                        SpinBox {
                            id: bandpassOrder
                            Layout.fillWidth: true
                            from: 1
                            to: 8
                            value: 4
                        }

                        Button {
                            text: "Apply Bandpass"
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            enabled: filterController.hasData &&
                                   bandpassLow.text !== "" &&
                                   bandpassHigh.text !== ""
                            onClicked: {
                                var low = parseFloat(bandpassLow.text)
                                var high = parseFloat(bandpassHigh.text)
                                if (filterController.validateFilterParams("bandpass", low, high)) {
                                    var filtered = filterController.applyBandpass(low, high, bandpassOrder.value)
                                    filterApplied(filtered)
                                }
                            }
                        }
                    }
                }

                // Notch Filter
                GroupBox {
                    title: "🔕 Notch Filter"
                    Layout.fillWidth: true

                    GridLayout {
                        anchors.fill: parent
                        columns: 2
                        columnSpacing: 5
                        rowSpacing: 5

                        Label { text: "Low (Hz):" }
                        TextField {
                            id: notchLow
                            Layout.fillWidth: true
                            placeholderText: "e.g., 48"
                            validator: DoubleValidator { bottom: 0.1; top: 10000 }
                            text: "48"
                        }

                        Label { text: "High (Hz):" }
                        TextField {
                            id: notchHigh
                            Layout.fillWidth: true
                            placeholderText: "e.g., 52"
                            validator: DoubleValidator { bottom: 0.1; top: 10000 }
                            text: "52"
                        }

                        Label { text: "Order:" }
                        SpinBox {
                            id: notchOrder
                            Layout.fillWidth: true
                            from: 1
                            to: 8
                            value: 4
                        }

                        Button {
                            text: "Apply Notch"
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            enabled: filterController.hasData &&
                                   notchLow.text !== "" &&
                                   notchHigh.text !== ""
                            onClicked: {
                                var low = parseFloat(notchLow.text)
                                var high = parseFloat(notchHigh.text)
                                if (filterController.validateFilterParams("notch", low, high)) {
                                    var filtered = filterController.applyNotch(low, high, notchOrder.value)
                                    filterApplied(filtered)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Helper function for presets
    function applyPreset(preset) {
        var filtered

        switch(preset) {
        case "dc":
            // Remove DC offset with 1 Hz highpass, order 2
            filtered = filterController.applyHighpass(1.0, 2)
            break
        case "50hz":
            // Remove 50 Hz power line noise
            filtered = filterController.applyNotch(48.0, 52.0, 4)
            break
        case "emg":
            // Standard EMG bandpass 10-500 Hz
            filtered = filterController.applyBandpass(10.0, 500.0, 4)
            break
        case "smooth":
            // Smooth with lowpass 50 Hz
            filtered = filterController.applyLowpass(50.0, 4)
            break
        default:
            console.warn("Unknown preset:", preset)
            return
        }

        if (filtered) {
            filterApplied(filtered)
        }
    }

    // Listen for filter events
    Connections {
        target: filterController

        function onFilterApplied(filterType) {
            console.log("✓ Filter applied:", filterType)
        }

        function onFilterError(error) {
            console.error("✗ Filter error:", error)
        }
    }
}
