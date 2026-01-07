import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs

Rectangle {
    id: labelingTools
    color: "#13182b"
    border.color: "#2a3f5f"
    border.width: 1

    signal labelCreated(int startIdx, int endIdx, string labelText, string color)
    signal saveLabelsRequested()

    property int currentSelectionStart: -1
    property int currentSelectionEnd: -1
    property string currentColor: availableColors[colorSelector.currentIndex]

    // Debug: Monitor selection changes
    onCurrentSelectionStartChanged: {
        console.log("LabelingTools: currentSelectionStart changed to", currentSelectionStart)
    }
    onCurrentSelectionEndChanged: {
        console.log("LabelingTools: currentSelectionEnd changed to", currentSelectionEnd)
    }

    property var availableColors: [
        "#FF0000", "#00FF00", "#0000FF",
        "#FF00FF", "#FFFF00", "#00FFFF",
        "#FF8800", "#8800FF", "#00FF88"
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        Text {
            text: "Labeling Tools"
            font.pixelSize: 16
            font.bold: true
            color: "#e0e0e0"
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#2a3f5f"
        }

        // Create label section
        Column {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "Create Label"
                font.pixelSize: 13
                font.bold: true
                color: "#e0e0e0"
            }

            Column {
                width: parent.width
                spacing: 8

                Text {
                    text: "Label Name"
                    font.pixelSize: 10
                    color: "#b0b0b0"
                }

                TextField {
                    id: labelNameInput
                    width: parent.width
                    height: 32
                    placeholderText: "Enter label..."

                    background: Rectangle {
                        color: "#1a2844"
                        border.color: labelNameInput.activeFocus ? "#00aaff" : "#2a3f5f"
                        border.width: 1
                        radius: 4
                    }

                    color: "#e0e0e0"
                    font.pixelSize: 11
                    leftPadding: 10
                    placeholderTextColor: "#505050"
                }
            }

            Column {
                width: parent.width
                spacing: 8

                Text {
                    text: "Color"
                    font.pixelSize: 10
                    color: "#b0b0b0"
                }

                ComboBox {
                    id: colorSelector
                    width: parent.width
                    height: 32
                    model: availableColors

                    background: Rectangle {
                        color: "#1a2844"
                        border.color: "#2a3f5f"
                        border.width: 1
                        radius: 4
                    }

                    delegate: ItemDelegate {
                        width: parent.width
                        height: 32

                        background: Rectangle {
                            color: parent.hovered ? "#2a3f5f" : "#1a2844"
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            color: modelData
                            radius: 3

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: "white"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }

                    contentItem: Rectangle {
                        color: availableColors[colorSelector.currentIndex]
                        radius: 3
                        anchors.margins: 4

                        Text {
                            anchors.centerIn: parent
                            text: availableColors[colorSelector.currentIndex]
                            color: "white"
                            font.bold: true
                            font.pixelSize: 10
                        }
                    }
                }
            }

            Button {
                width: parent.width
                height: 40
                text: "Add Label from Selection"
                enabled: {
                    var hasName = labelNameInput.text.length > 0
                    var hasStart = currentSelectionStart >= 0
                    var hasEnd = currentSelectionEnd >= 0
                    var validRange = currentSelectionStart < currentSelectionEnd

                    console.log("Button enabled check: hasName=" + hasName +
                                ", hasStart=" + hasStart +
                                ", hasEnd=" + hasEnd +
                                ", validRange=" + validRange +
                                ", start=" + currentSelectionStart +
                                ", end=" + currentSelectionEnd)

                    return hasName && hasStart && hasEnd && validRange
                }

                background: Rectangle {
                    color: parent.enabled ? (parent.hovered ? "#0099dd" : "#00aaff") : "#1a2844"
                    radius: 4
                }

                contentItem: Text {
                    text: parent.text
                    font.pixelSize: 12
                    font.bold: true
                    color: parent.enabled ? "#0a0e1a" : "#505050"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    labelCreated(currentSelectionStart, currentSelectionEnd,
                               labelNameInput.text,
                               availableColors[colorSelector.currentIndex])
                    labelNameInput.text = ""
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#2a3f5f"
        }

        // Label list section
        Column {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Row {
                width: parent.width

                Text {
                    text: "EVENT TYPES"
                    font.pixelSize: 10
                    font.bold: true
                    color: "#707070"
                    font.letterSpacing: 1
                }

                Text {
                    text: " (" + labelManager.labelCount + ")"
                    font.pixelSize: 10
                    color: "#00aaff"
                    font.bold: true
                }
            }

            ScrollView {
                width: parent.width
                height: parent.height - 30
                clip: true

                ListView {
                    id: labelListView
                    width: parent.width
                    model: labelManager.labels
                    spacing: 8

                    delegate: Rectangle {
                        width: labelListView.width
                        height: 60
                        color: "#1a2844"
                        radius: 4
                        border.color: "#2a3f5f"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 4
                                Layout.fillHeight: true
                                color: modelData.color
                                radius: 2
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: modelData.label
                                    font.bold: true
                                    font.pixelSize: 12
                                    color: "#e0e0e0"
                                }

                                Text {
                                    text: {
                                        if (appController.sampleRate > 0) {
                                            var startTime = (modelData.startIndex / appController.sampleRate).toFixed(3)
                                            var endTime = (modelData.endIndex / appController.sampleRate).toFixed(3)
                                            var duration = ((modelData.endIndex - modelData.startIndex) / appController.sampleRate).toFixed(3)
                                            return startTime + "s - " + endTime + "s"
                                        }
                                        return modelData.startIndex + " - " + modelData.endIndex
                                    }
                                    font.pixelSize: 9
                                    color: "#b0b0b0"
                                }

                                Text {
                                    visible: appController.sampleRate > 0
                                    text: {
                                        var duration = ((modelData.endIndex - modelData.startIndex) / appController.sampleRate).toFixed(3)
                                        return "Duration: " + duration + "s"
                                    }
                                    font.pixelSize: 9
                                    color: "#707070"
                                }
                            }

                            Button {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                text: "×"

                                background: Rectangle {
                                    color: parent.hovered ? "#aa0000" : "#882200"
                                    radius: 16
                                }

                                contentItem: Text {
                                    text: parent.text
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: "#ffffff"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: {
                                    labelManager.removeLabel(modelData.id)
                                }
                            }
                        }
                    }

                    // Empty state
                    Rectangle {
                        anchors.centerIn: parent
                        visible: labelManager.labelCount === 0
                        width: parent.width
                        height: 100
                        color: "transparent"

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: "No labels yet"
                                color: "#505050"
                                font.pixelSize: 13
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "Select a region to create labels"
                                color: "#505050"
                                font.pixelSize: 10
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
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

        // Bottom actions
        Button {
            Layout.fillWidth: true
            height: 36
            text: "Clear All Labels"
            enabled: labelManager.labelCount > 0

            background: Rectangle {
                color: parent.enabled ? (parent.hovered ? "#aa2200" : "#882200") : "#1a2844"
                border.color: "#2a3f5f"
                border.width: 1
                radius: 4
            }

            contentItem: Text {
                text: parent.text
                font.pixelSize: 11
                color: parent.enabled ? "#ffffff" : "#505050"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: labelManager.clearLabels()
        }

        Button {
            Layout.fillWidth: true
            height: 40
            text: "Save Labels"
            enabled: labelManager.labelCount > 0

            background: Rectangle {
                color: parent.enabled ? (parent.hovered ? "#0099dd" : "#00aaff") : "#1a2844"
                radius: 4
            }

            contentItem: Text {
                text: parent.text
                font.pixelSize: 12
                font.bold: true
                color: parent.enabled ? "#0a0e1a" : "#505050"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: {
                console.log("Save Labels button clicked")
                saveLabelsRequested()
            }
        }
    }
}
