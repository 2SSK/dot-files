import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets

Rectangle {
    property bool expanded: false

    width: ListView.view.width - (ListView.view.ScrollBar.vertical ? 10 : 0)
    height: contentLayout.implicitHeight + (2 * Style.marginM)
    color: Color.mSurfaceVariant
    radius: Style.radiusM

    signal requestRun(string repo, string tag)
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
                onClicked: expanded = !expanded
                cursorShape: Qt.PointingHandCursor
                z: 0
            }

            RowLayout {
                id: headerRow
                anchors.fill: parent
                spacing: Style.marginM

                NIcon {
                    icon: "photo"
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    z: 1
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    z: 1

                    Text {
                        text: "" + model.repository + ":" + model.tag
                        font.bold: true
                        color: Color.mOnSurface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "" + model.size + " • " + model.created
                        color: Color.mOnSurfaceVariant
                        font.pixelSize: 11
                        Layout.fillWidth: true
                    }
                }

                Row {
                    spacing: 5
                    z: 1

                    NButton {
                        text: "Run"
                        icon: "player-play"
                        Layout.preferredHeight: 32
                        onClicked: requestRun(model.repository, model.tag)
                    }

                    NButton {
                        icon: "trash"
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        visible: !model.isRunning
                        onClicked: requestRemove(model.id)
                    }
                }
            }
        }

        // Details Section
        Item {
            id: detailsWrapper
            Layout.fillWidth: true
            Layout.preferredHeight: expanded ? detailsLayout.implicitHeight : 0
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
                        text: "Image ID:"
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
                        text: "Size:"
                        color: Color.mOnSurfaceVariant
                        font.bold: true
                    }
                    Text {
                        text: model.size
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "Created:"
                        color: Color.mOnSurfaceVariant
                        font.bold: true
                    }
                    Text {
                        text: model.created
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
