import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs

Rectangle {
    id: fileSelector
    color: "white"
    radius: 5
    border.color: "#ddd"
    border.width: 1

    signal fileSelected(int index)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Files"
                font.pixelSize: 16
                font.bold: true
                Layout.fillWidth: true
            }

            Button {
                text: "Load Metadata"
                onClicked: fileDialog.open()
            }
        }

        // File list
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: fileListView
                width: parent.width
                model: dataController.fileList
                spacing: 2

                delegate: Rectangle {
                    width: fileListView.width
                    height: 40
                    color: mouseArea.containsMouse ? "#e3f2fd" : "transparent"
                    radius: 3

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            fileListView.currentIndex = index
                            fileSelected(index)
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 5

                        Rectangle {
                            Layout.preferredWidth: 4
                            Layout.fillHeight: true
                            color: fileListView.currentIndex === index ? "#2196F3" : "transparent"
                            radius: 2
                        }

                        Column {
                            Layout.fillWidth: true

                            Text {
                                text: modelData
                                font.pixelSize: 12
                                font.bold: fileListView.currentIndex === index
                                elide: Text.ElideMiddle
                                width: parent.width
                            }

                            Text {
                                text: dataController.getChannelCount(index) + " channel(s)"
                                font.pixelSize: 10
                                color: "#666"
                            }
                        }
                    }
                }

                // Empty state
                Text {
                    anchors.centerIn: parent
                    visible: fileListView.count === 0
                    text: "No files loaded\n\nClick 'Load Metadata' to begin"
                    horizontalAlignment: Text.AlignHCenter
                    color: "#999"
                    font.pixelSize: 12
                }
            }
        }
    }

    // File dialog
    FileDialog {
        id: fileDialog
        title: "Select metadata.json file"
        nameFilters: ["JSON files (*.json)"]
        onAccepted: {
            var path = fileDialog.selectedFile.toString()
            // Remove file:// prefix
            path = path.replace(/^file:\/\//, "")
            dataController.metadataPath = path
            dataController.loadMetadata()
        }
    }
}
