import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets
import "../dockerUtils.js" as DockerUtils

Rectangle {
    id: containerDelegate
    property var containerData: model
    property bool expanded: false

    width: ListView.view.width - (ListView.view.ScrollBar.vertical ? 10 : 0)
    // Implicit height of layout + margins
    height: contentLayout.implicitHeight + (2 * Style.marginM)
    
    color: Color.mSurfaceVariant
    radius: Style.radiusM

    signal requestStart(string id)
    signal requestStop(string id)
    signal requestRestart(string id)
    signal requestRemove(string id)

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: 0

        // Header Section
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: headerRow.implicitHeight

            MouseArea {
                anchors.fill: parent
                onClicked: containerDelegate.expanded = !containerDelegate.expanded
                cursorShape: Qt.PointingHandCursor
                z: 0 
            }

            RowLayout {
                id: headerRow
                anchors.fill: parent
                spacing: Style.marginM

                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: DockerUtils.getStatusColor(model.state)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "" + model.name
                        font.bold: true
                        color: Color.mOnSurface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "" + model.image + " (" + model.status + ")"
                        color: Color.mOnSurfaceVariant
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Row {
                    spacing: 5

                    NButton {
                        icon: model.state === "running" ? "player-stop" : "player-play"
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        onClicked: model.state === "running" ? requestStop(model.id) : requestStart(model.id)
                    }

                    NButton {
                        icon: "refresh"
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        visible: model.state === "running"
                        onClicked: requestRestart(model.id)
                    }

                    NButton {
                        icon: "trash"
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        visible: model.state !== "running"
                        onClicked: requestRemove(model.id)
                    }
                }
            }
        }

        // Details Section
        Item {
            id: detailsWrapper
            Layout.fillWidth: true
            Layout.preferredHeight: containerDelegate.expanded ? detailsLayout.implicitHeight : 0
            clip: true

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }

            ColumnLayout {
                id: detailsLayout
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                
                spacing: 5
                
                // Add top margin inside the layout so it animates nicely
                Item { height: 5; width: 1 }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Color.mOutline
                    opacity: 0.2
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 2
                    columnSpacing: 10

                    Text {
                        text: "Container ID:"
                        color: Color.mOnSurfaceVariant
                        font.bold: true
                    }
                    Text {
                        text: model.id
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.family: "Monospace"
                    }

                    Text {
                        text: "Image:"
                        color: Color.mOnSurfaceVariant
                        font.bold: true
                    }
                    Text {
                        text: model.image
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "Command:"
                        color: Color.mOnSurfaceVariant
                        font.bold: true
                    }
                    Text {
                        text: model.command || "N/A"
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.family: "Monospace"
                    }

                    Text {
                        text: "State:"
                        color: Color.mOnSurfaceVariant
                        font.bold: true
                    }
                    Text {
                        text: model.state
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
