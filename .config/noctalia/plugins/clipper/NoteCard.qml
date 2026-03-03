import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Rectangle {
    id: root

    // Properties
    property var pluginApi: null
    property var note: null
    property int noteIndex: 0

    // Color schemes
    property var colorSchemes: ({
        "yellow": {
            bg: "#FFF9C4",
            fg: "#000000",
            header: "#FDD835"
        },
        "pink": {
            bg: "#FCE4EC",
            fg: "#000000",
            header: "#F06292"
        },
        "blue": {
            bg: "#E3F2FD",
            fg: "#000000",
            header: "#42A5F5"
        },
        "green": {
            bg: "#E8F5E9",
            fg: "#000000",
            header: "#66BB6A"
        },
        "purple": {
            bg: "#F3E5F5",
            fg: "#000000",
            header: "#AB47BC"
        }
    })

    // Constants for sizing
    readonly property int minHeight: 200
    readonly property int maxHeight: 600
    readonly property int headerHeight: 40
    readonly property int margins: 24

    // Position and size from note data
    x: note ? note.x : 0
    y: note ? note.y : 0
    width: note ? note.width : 350
    height: note ? note.height : minHeight
    z: note ? note.zIndex : 0

    // Color from note data
    color: {
        const noteColor = note ? note.color : "yellow";
        const scheme = colorSchemes[noteColor];
        return scheme ? scheme.bg : "#FFF9C4";
    }
    border.color: Color.mOnSurfaceVariant
    border.width: 1
    radius: Style.radiusM

    // Main layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            id: headerBar
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight
            color: {
                const noteColor = note ? note.color : "yellow";
                const scheme = colorSchemes[noteColor];
                return scheme ? scheme.header : "#FDD835";
            }
            topLeftRadius: Style.radiusM
            topRightRadius: Style.radiusM
            bottomLeftRadius: 0
            bottomRightRadius: 0


            RowLayout {
                id: headerContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10
                anchors.rightMargin: 6
                spacing: 10
                z: 1

                // Icon - DRAG HANDLE
                Item {
                    Layout.preferredWidth: 24
                    Layout.fillHeight: true

                    NIcon {
                        anchors.centerIn: parent
                        icon: "note"
                        pointSize: 15
                        color: {
                            const noteColor = note ? note.color : "yellow";
                            const scheme = colorSchemes[noteColor];
                            return scheme ? scheme.fg : "#000000";
                        }
                    }

                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        cursorShape: Qt.SizeAllCursor

                        drag.target: root
                        drag.axis: Drag.XAndYAxis
                        drag.minimumX: 0
                        drag.maximumX: root.parent ? (root.parent.width - root.width) : 1200
                        drag.minimumY: 0
                        drag.maximumY: root.parent ? (root.parent.height - root.height) : 700

                        onPressed: {
                            if (root.pluginApi && root.pluginApi.mainInstance) {
                                root.pluginApi.mainInstance.bringNoteToFront(root.note.id);
                            }
                        }

                        onReleased: {
                            if (root.pluginApi && root.pluginApi.mainInstance) {
                                root.pluginApi.mainInstance.updateNoteCard(
                                    root.note.id,
                                    { x: root.x, y: root.y }
                                );
                            }
                        }
                    }
                }

                // Title
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 150

                    TextInput {
                        id: titleInput
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignLeft
                        color: {
                            const noteColor = note ? note.color : "yellow";
                            const scheme = colorSchemes[noteColor];
                            return scheme ? scheme.fg : "#000000";
                        }
                        font.pixelSize: 14
                        font.bold: false
                        selectByMouse: true
                        clip: true

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            text: pluginApi?.tr("notecards.untitled-placeholder") || "Untitled"
                            color: parent.color
                            opacity: 0.5
                            visible: titleInput.text.length === 0
                            font: titleInput.font
                        }

                        Component.onCompleted: {
                            if (note) {
                                text = note.title || "";
                            }
                        }

                        onAccepted: {
                            root.syncChanges();
                            titleInput.focus = false;
                        }
                    }

                }
                NIconButton {
                    icon: "palette"
                    tooltipText: pluginApi?.tr("notecards.change-color") || "Change Color"
                    colorFg: {
                        const noteColor = note ? note.color : "yellow";
                        const scheme = colorSchemes[noteColor];
                        return scheme ? scheme.fg : "#000000";
                    }
                    colorBg: "transparent"
                    colorBgHover: Qt.rgba(0,0,0,0.1)
                    colorBorder: "transparent"
                    colorBorderHover: "transparent"

                    onClicked: {
                        const colors = ["yellow", "pink", "blue", "green", "purple"];
                        const noteColor = (root.note && root.note.color) ? root.note.color : "yellow";
                        const currentIndex = colors.indexOf(noteColor);
                        const nextIndex = (currentIndex + 1) % colors.length;
                        const nextColor = colors[nextIndex];

                        if (root.pluginApi && root.pluginApi.mainInstance) {
                            root.pluginApi.mainInstance.updateNoteCard(
                                root.note.id,
                                { color: nextColor }
                            );
                        }
                    }
                }

                NIconButton {
                    icon: "file-export"
                    tooltipText: pluginApi?.tr("notecards.export") || "Export to .txt"
                    colorFg: {
                        const noteColor = note ? note.color : "yellow";
                        const scheme = colorSchemes[noteColor];
                        return scheme ? scheme.fg : "#000000";
                    }
                    colorBg: "transparent"
                    colorBgHover: Qt.rgba(0,0,0,0.1)
                    colorBorder: "transparent"
                    colorBorderHover: "transparent"

                    onClicked: {
                        if (root.pluginApi && root.pluginApi.mainInstance) {
                            root.pluginApi.mainInstance.exportNoteCard(root.note.id);
                        }
                    }
                }

                NIconButton {
                    icon: "trash"
                    tooltipText: pluginApi?.tr("notecards.delete") || "Delete Note"
                    colorFg: {
                        const noteColor = note ? note.color : "yellow";
                        const scheme = colorSchemes[noteColor];
                        return scheme ? scheme.fg : "#000000";
                    }
                    colorBg: "transparent"
                    colorBgHover: Qt.rgba(0,0,0,0.1)
                    colorBorder: "transparent"
                    colorBorderHover: "transparent"

                    onClicked: {
                        if (root.pluginApi && root.pluginApi.mainInstance) {
                            root.pluginApi.mainInstance.deleteNoteCard(root.note.id);
                        }
                    }
                }
            }
        }

        // Separator
        Rectangle {
            width: parent.width - 10
            Layout.alignment: Qt.AlignHCenter
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { 
                    position: 0.5
                    color: {
                        const noteColor = note ? note.color : "yellow";
                        const scheme = colorSchemes[noteColor];
                        return scheme ? scheme.header : "#FDD835";
                    }
                }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Content area with ScrollView
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 12
            clip: true

            ScrollView {
                anchors.fill: parent
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                TextArea {
                    id: textArea
                    width: parent.width
                    wrapMode: TextArea.Wrap
                    selectByMouse: true
                    color: {
                        const noteColor = note ? note.color : "yellow";
                        const scheme = colorSchemes[noteColor];
                        return scheme ? scheme.fg : "#000000";
                    }
                    font.pixelSize: 14
                    background: Rectangle { color: "transparent" }

                    Component.onCompleted: {
                        if (note) {
                            text = note.content || "";
                        }
                        // Check if we need to expand card on load
                        Qt.callLater(checkAndExpandHeight);
                    }

                    onTextChanged: {
                        if (note) {
                            note.content = text;
                        }
                    }
                }
            }
        }
    }

    // Check if card needs to be expanded to fit content
    function checkAndExpandHeight() {
        if (!textArea || !note) return;
        
        const contentHeight = textArea.contentHeight;
        const availableHeight = root.height - root.headerHeight - root.margins - 1; // 1 = separator
        
        // If content doesn't fit, expand card
        if (contentHeight > availableHeight) {
            let newHeight = root.headerHeight + root.margins + contentHeight + 1;
            newHeight = Math.min(newHeight, root.maxHeight);
            
            if (newHeight !== root.height && root.pluginApi && root.pluginApi.mainInstance) {
                root.pluginApi.mainInstance.updateNoteCard(
                    root.note.id,
                    { height: newHeight }
                );
            }
        }
    }

    function syncChanges() {
        if (root.pluginApi && root.pluginApi.mainInstance && note) {
            root.pluginApi.mainInstance.updateNoteCard(
                note.id,
                {
                    title: titleInput.text,
                    content: textArea.text
                }
            );
        }
    }
    Component.onDestruction: {
        root.syncChanges();
    }
}
