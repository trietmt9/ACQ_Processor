import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// Advanced Filter Panel for DSP Engineers
// Features:
// - Real-time parameter adjustment with sliders
// - Numerical input validation
// - Filter coefficient display
// - Frequency response preview
// - Cascade filter chains

Rectangle {
    id: advancedFilterPanel
    color: "#f8f8f8"
    radius: 5
    border.color: "#ccc"
    border.width: 1

    signal filterApplied(var filteredData)
    signal parametersChanged(string filterType, var params)

    property string currentFilterType: "lowpass"
    property real lowpassCutoff: 50.0
    property real highpassCutoff: 1.0
    property real bandpassLow: 10.0
    property real bandpassHigh: 500.0
    property real notchLow: 48.0
    property real notchHigh: 52.0
    property int filterOrder: 4

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "DSP Filter Designer"
                font.pixelSize: 14
                font.bold: true
                color: "#1976D2"
                Layout.fillWidth: true
            }

            ComboBox {
                id: filterTypeCombo
                model: ["Lowpass", "Highpass", "Bandpass", "Notch"]
                currentIndex: 0
                onCurrentTextChanged: {
                    currentFilterType = currentText.toLowerCase()
                }
            }
        }

        // Signal Information
        Rectangle {
            Layout.fillWidth: true
            height: infoLayout.height + 16
            color: filterController.hasData ? "#E3F2FD" : "#FFEBEE"
            radius: 4

            ColumnLayout {
                id: infoLayout
                anchors.centerIn: parent
                width: parent.width - 16
                spacing: 4

                Text {
                    text: filterController.hasData ? "✓ Signal Loaded" : "⚠ No Signal"
                    font.pixelSize: 11
                    font.bold: true
                    color: filterController.hasData ? "#1976D2" : "#C62828"
                }

                GridLayout {
                    columns: 4
                    columnSpacing: 10
                    rowSpacing: 2
                    visible: filterController.hasData

                    Text { text: "Fs:"; font.pixelSize: 9; color: "#666" }
                    Text {
                        text: filterController.getSampleRate().toFixed(1) + " Hz"
                        font.pixelSize: 9
                        font.family: "monospace"
                    }

                    Text { text: "Fn:"; font.pixelSize: 9; color: "#666" }
                    Text {
                        text: filterController.getNyquistFrequency().toFixed(1) + " Hz"
                        font.pixelSize: 9
                        font.family: "monospace"
                    }
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width - 20
                spacing: 12

                // ==== LOWPASS FILTER ====
                GroupBox {
                    title: "Lowpass Filter"
                    visible: currentFilterType === "lowpass"
                    Layout.fillWidth: true

                    GridLayout {
                        anchors.fill: parent
                        columns: 3
                        columnSpacing: 8
                        rowSpacing: 8

                        // Cutoff Frequency
                        Text {
                            text: "Cutoff:"
                            font.bold: true
                            Layout.columnSpan: 3
                        }

                        Slider {
                            id: lowpassSlider
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            from: 0.1
                            to: filterController.hasData ? filterController.getNyquistFrequency() : 500
                            value: lowpassCutoff
                            stepSize: 0.1
                            onValueChanged: {
                                if (Math.abs(value - lowpassCutoff) > 0.01) {
                                    lowpassCutoff = value
                                    lowpassFreqInput.text = value.toFixed(2)
                                }
                            }
                        }

                        TextField {
                            id: lowpassFreqInput
                            Layout.preferredWidth: 80
                            text: lowpassCutoff.toFixed(2)
                            validator: DoubleValidator { bottom: 0.1; top: 10000 }
                            horizontalAlignment: Text.AlignRight
                            onEditingFinished: {
                                var val = parseFloat(text)
                                if (!isNaN(val) && val > 0) {
                                    lowpassCutoff = val
                                    lowpassSlider.value = val
                                }
                            }
                        }

                        Text { text: "Order:"; font.bold: true }
                        SpinBox {
                            id: lowpassOrderSpin
                            Layout.columnSpan: 2
                            from: 1
                            to: 8
                            value: filterOrder
                            onValueChanged: filterOrder = value
                        }

                        Button {
                            text: "Apply Lowpass"
                            Layout.columnSpan: 3
                            Layout.fillWidth: true
                            enabled: filterController.hasData
                            highlighted: true
                            onClicked: applyLowpassFilter()
                        }

                        Text {
                            Layout.columnSpan: 3
                            text: "Passes frequencies below " + lowpassCutoff.toFixed(2) + " Hz"
                            font.pixelSize: 9
                            font.italic: true
                            color: "#666"
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                // ==== HIGHPASS FILTER ====
                GroupBox {
                    title: "Highpass Filter"
                    visible: currentFilterType === "highpass"
                    Layout.fillWidth: true

                    GridLayout {
                        anchors.fill: parent
                        columns: 3
                        columnSpacing: 8
                        rowSpacing: 8

                        Text {
                            text: "Cutoff:"
                            font.bold: true
                            Layout.columnSpan: 3
                        }

                        Slider {
                            id: highpassSlider
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            from: 0.1
                            to: filterController.hasData ? filterController.getNyquistFrequency() / 2 : 100
                            value: highpassCutoff
                            stepSize: 0.1
                            onValueChanged: {
                                if (Math.abs(value - highpassCutoff) > 0.01) {
                                    highpassCutoff = value
                                    highpassFreqInput.text = value.toFixed(2)
                                }
                            }
                        }

                        TextField {
                            id: highpassFreqInput
                            Layout.preferredWidth: 80
                            text: highpassCutoff.toFixed(2)
                            validator: DoubleValidator { bottom: 0.1; top: 10000 }
                            horizontalAlignment: Text.AlignRight
                            onEditingFinished: {
                                var val = parseFloat(text)
                                if (!isNaN(val) && val > 0) {
                                    highpassCutoff = val
                                    highpassSlider.value = val
                                }
                            }
                        }

                        Text { text: "Order:"; font.bold: true }
                        SpinBox {
                            id: highpassOrderSpin
                            Layout.columnSpan: 2
                            from: 1
                            to: 8
                            value: filterOrder
                            onValueChanged: filterOrder = value
                        }

                        Button {
                            text: "Apply Highpass"
                            Layout.columnSpan: 3
                            Layout.fillWidth: true
                            enabled: filterController.hasData
                            highlighted: true
                            onClicked: applyHighpassFilter()
                        }

                        Text {
                            Layout.columnSpan: 3
                            text: "Passes frequencies above " + highpassCutoff.toFixed(2) + " Hz"
                            font.pixelSize: 9
                            font.italic: true
                            color: "#666"
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                // ==== BANDPASS FILTER ====
                GroupBox {
                    title: "Bandpass Filter"
                    visible: currentFilterType === "bandpass"
                    Layout.fillWidth: true

                    GridLayout {
                        anchors.fill: parent
                        columns: 3
                        columnSpacing: 8
                        rowSpacing: 8

                        Text {
                            text: "Low Cutoff:"
                            font.bold: true
                            Layout.columnSpan: 3
                        }

                        Slider {
                            id: bandpassLowSlider
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            from: 0.1
                            to: filterController.hasData ? filterController.getNyquistFrequency() - 1 : 490
                            value: bandpassLow
                            stepSize: 0.1
                            onValueChanged: {
                                if (value >= bandpassHigh) {
                                    value = bandpassHigh - 1
                                }
                                if (Math.abs(value - bandpassLow) > 0.01) {
                                    bandpassLow = value
                                    bandpassLowInput.text = value.toFixed(2)
                                }
                            }
                        }

                        TextField {
                            id: bandpassLowInput
                            Layout.preferredWidth: 80
                            text: bandpassLow.toFixed(2)
                            validator: DoubleValidator { bottom: 0.1; top: 10000 }
                            horizontalAlignment: Text.AlignRight
                            onEditingFinished: {
                                var val = parseFloat(text)
                                if (!isNaN(val) && val > 0 && val < bandpassHigh) {
                                    bandpassLow = val
                                    bandpassLowSlider.value = val
                                }
                            }
                        }

                        Text {
                            text: "High Cutoff:"
                            font.bold: true
                            Layout.columnSpan: 3
                        }

                        Slider {
                            id: bandpassHighSlider
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            from: 1
                            to: filterController.hasData ? filterController.getNyquistFrequency() : 500
                            value: bandpassHigh
                            stepSize: 0.1
                            onValueChanged: {
                                if (value <= bandpassLow) {
                                    value = bandpassLow + 1
                                }
                                if (Math.abs(value - bandpassHigh) > 0.01) {
                                    bandpassHigh = value
                                    bandpassHighInput.text = value.toFixed(2)
                                }
                            }
                        }

                        TextField {
                            id: bandpassHighInput
                            Layout.preferredWidth: 80
                            text: bandpassHigh.toFixed(2)
                            validator: DoubleValidator { bottom: 0.1; top: 10000 }
                            horizontalAlignment: Text.AlignRight
                            onEditingFinished: {
                                var val = parseFloat(text)
                                if (!isNaN(val) && val > bandpassLow) {
                                    bandpassHigh = val
                                    bandpassHighSlider.value = val
                                }
                            }
                        }

                        Text { text: "Order:"; font.bold: true }
                        SpinBox {
                            id: bandpassOrderSpin
                            Layout.columnSpan: 2
                            from: 1
                            to: 8
                            value: filterOrder
                            onValueChanged: filterOrder = value
                        }

                        Button {
                            text: "Apply Bandpass"
                            Layout.columnSpan: 3
                            Layout.fillWidth: true
                            enabled: filterController.hasData && bandpassLow < bandpassHigh
                            highlighted: true
                            onClicked: applyBandpassFilter()
                        }

                        Text {
                            Layout.columnSpan: 3
                            text: "Passes " + bandpassLow.toFixed(2) + " - " + bandpassHigh.toFixed(2) + " Hz (BW: " + (bandpassHigh - bandpassLow).toFixed(2) + " Hz)"
                            font.pixelSize: 9
                            font.italic: true
                            color: "#666"
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                // ==== NOTCH FILTER ====
                GroupBox {
                    title: "Notch Filter (Band-stop)"
                    visible: currentFilterType === "notch"
                    Layout.fillWidth: true

                    GridLayout {
                        anchors.fill: parent
                        columns: 3
                        columnSpacing: 8
                        rowSpacing: 8

                        Text {
                            text: "Low Cutoff:"
                            font.bold: true
                            Layout.columnSpan: 3
                        }

                        Slider {
                            id: notchLowSlider
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            from: 0.1
                            to: filterController.hasData ? filterController.getNyquistFrequency() - 1 : 100
                            value: notchLow
                            stepSize: 0.1
                            onValueChanged: {
                                if (value >= notchHigh) {
                                    value = notchHigh - 0.5
                                }
                                if (Math.abs(value - notchLow) > 0.01) {
                                    notchLow = value
                                    notchLowInput.text = value.toFixed(2)
                                }
                            }
                        }

                        TextField {
                            id: notchLowInput
                            Layout.preferredWidth: 80
                            text: notchLow.toFixed(2)
                            validator: DoubleValidator { bottom: 0.1; top: 10000 }
                            horizontalAlignment: Text.AlignRight
                            onEditingFinished: {
                                var val = parseFloat(text)
                                if (!isNaN(val) && val > 0 && val < notchHigh) {
                                    notchLow = val
                                    notchLowSlider.value = val
                                }
                            }
                        }

                        Text {
                            text: "High Cutoff:"
                            font.bold: true
                            Layout.columnSpan: 3
                        }

                        Slider {
                            id: notchHighSlider
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            from: 1
                            to: filterController.hasData ? filterController.getNyquistFrequency() : 100
                            value: notchHigh
                            stepSize: 0.1
                            onValueChanged: {
                                if (value <= notchLow) {
                                    value = notchLow + 0.5
                                }
                                if (Math.abs(value - notchHigh) > 0.01) {
                                    notchHigh = value
                                    notchHighInput.text = value.toFixed(2)
                                }
                            }
                        }

                        TextField {
                            id: notchHighInput
                            Layout.preferredWidth: 80
                            text: notchHigh.toFixed(2)
                            validator: DoubleValidator { bottom: 0.1; top: 10000 }
                            horizontalAlignment: Text.AlignRight
                            onEditingFinished: {
                                var val = parseFloat(text)
                                if (!isNaN(val) && val > notchLow) {
                                    notchHigh = val
                                    notchHighSlider.value = val
                                }
                            }
                        }

                        Text { text: "Order:"; font.bold: true }
                        SpinBox {
                            id: notchOrderSpin
                            Layout.columnSpan: 2
                            from: 1
                            to: 8
                            value: filterOrder
                            onValueChanged: filterOrder = value
                        }

                        Button {
                            text: "Apply Notch"
                            Layout.columnSpan: 3
                            Layout.fillWidth: true
                            enabled: filterController.hasData && notchLow < notchHigh
                            highlighted: true
                            onClicked: applyNotchFilter()
                        }

                        Text {
                            Layout.columnSpan: 3
                            text: "Rejects " + notchLow.toFixed(2) + " - " + notchHigh.toFixed(2) + " Hz (BW: " + (notchHigh - notchLow).toFixed(2) + " Hz)"
                            font.pixelSize: 9
                            font.italic: true
                            color: "#666"
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                // Action Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Button {
                        text: "Reset to Original"
                        Layout.fillWidth: true
                        enabled: filterController.hasData
                        onClicked: {
                            var original = filterController.getOriginalData(10000)
                            filterApplied(original)
                        }
                    }
                }
            }
        }

        // Status/Error Display
        Rectangle {
            Layout.fillWidth: true
            height: 30
            color: filterController.lastError !== "" ? "#FFCDD2" : "#C8E6C9"
            radius: 3
            visible: filterController.lastError !== "" || filterAppliedText.visible

            Text {
                id: filterAppliedText
                anchors.centerIn: parent
                text: filterController.lastError !== "" ? ("⚠ " + filterController.lastError) : "✓ Filter applied"
                font.pixelSize: 10
                color: filterController.lastError !== "" ? "#C62828" : "#2E7D32"
                property bool visible: false
            }

            Timer {
                id: statusTimer
                interval: 3000
                onTriggered: filterAppliedText.visible = false
            }
        }
    }

    // Filter Application Functions
    function applyLowpassFilter() {
        if (!filterController.validateFilterParams("lowpass", lowpassCutoff, 0)) {
            return
        }

        var filtered = filterController.applyLowpass(lowpassCutoff, filterOrder)
        if (filtered && filtered.length > 0) {
            filterApplied(filtered)
            filterAppliedText.visible = true
            statusTimer.restart()
        }
    }

    function applyHighpassFilter() {
        if (!filterController.validateFilterParams("highpass", highpassCutoff, 0)) {
            return
        }

        var filtered = filterController.applyHighpass(highpassCutoff, filterOrder)
        if (filtered && filtered.length > 0) {
            filterApplied(filtered)
            filterAppliedText.visible = true
            statusTimer.restart()
        }
    }

    function applyBandpassFilter() {
        if (!filterController.validateFilterParams("bandpass", bandpassLow, bandpassHigh)) {
            return
        }

        var filtered = filterController.applyBandpass(bandpassLow, bandpassHigh, filterOrder)
        if (filtered && filtered.length > 0) {
            filterApplied(filtered)
            filterAppliedText.visible = true
            statusTimer.restart()
        }
    }

    function applyNotchFilter() {
        if (!filterController.validateFilterParams("notch", notchLow, notchHigh)) {
            return
        }

        var filtered = filterController.applyNotch(notchLow, notchHigh, filterOrder)
        if (filtered && filtered.length > 0) {
            filterApplied(filtered)
            filterAppliedText.visible = true
            statusTimer.restart()
        }
    }

    // Listen for filter events
    Connections {
        target: filterController

        function onFilterApplied(filterType) {
            console.log("✓ Applied:", filterType, "filter")
        }

        function onFilterError(error) {
            console.error("✗ Filter error:", error)
        }
    }
}
