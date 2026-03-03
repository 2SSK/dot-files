import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Services.UI
import qs.Widgets

// Universal selection context menu that appears at cursor position
PanelWindow {
    id: root

    required property ShellScreen screen
    property var pluginApi: null
    property var menuItems: []
    
    signal itemSelected(string action)
    signal cancelled()

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "noctalia-selection-menu-" + (screen?.name || "unknown")
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    property int cursorX: 0
    property int cursorY: 0

    function show(items) {
        menuItems = items || [];
        visible = true;
        getCursorPositionProcess.running = true;
    }

    function close() {
        visible = false;
        contextMenu.visible = false;
    }

    // Get cursor position from hyprctl
    Process {
        id: getCursorPositionProcess
        command: ["hyprctl", "cursorpos", "-j"]
        running: false

        stdout: StdioCollector {
            id: cursorStdout
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                try {
                    const data = JSON.parse(cursorStdout.text);
                    root.cursorX = data.x || 0;
                    root.cursorY = data.y || 0;
                    
                    // Position menu at cursor
                    anchorPoint.x = root.cursorX;
                    anchorPoint.y = root.cursorY;
                    contextMenu.model = root.menuItems;
                    contextMenu.anchorItem = anchorPoint;
                    contextMenu.visible = true;
                } catch(e) {
                    ToastService.showError(pluginApi?.tr("toast.failed-to-get-cursor-position") || "Failed to get cursor position");
                    root.close();
                }
            } else {
                root.close();
            }
        }
    }

    // Context menu
    NPopupContextMenu {
        id: contextMenu
        visible: false
        screen: root.screen
        minWidth: 200

        onTriggered: (action, item) => {
            root.itemSelected(action);
            root.close();
        }
    }

    // Anchor point for menu positioning
    Item {
        id: anchorPoint
        width: 1
        height: 1
        x: 0
        y: 0
    }

    // Fullscreen mouse area to capture outside clicks
    MouseArea {
        id: mouseCapture
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            root.cancelled();
            root.close();
        }
    }

    Component.onDestruction: {
        if (getCursorPositionProcess.running) {
            getCursorPositionProcess.terminate();
        }
        close();
    }
}
