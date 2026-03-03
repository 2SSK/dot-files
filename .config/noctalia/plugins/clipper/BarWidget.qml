import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

NIconButton {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    icon: "clipboard"
    tooltipText: pluginApi?.tr("bar.tooltip") || "Clipboard History"
    tooltipDirection: BarService.getTooltipDirection(screen?.name)
    baseSize: Style.getCapsuleHeightForScreen(screen?.name)
    applyUiScale: false
    customRadius: Style.radiusL

    colorBg: Style.capsuleColor
    colorFg: Color.mOnSurface
    colorBgHover: Color.mHover
    colorFgHover: Color.mOnHover
    colorBorder: "transparent"
    colorBorderHover: "transparent"

    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": pluginApi?.tr("context.toggle") || "Toggle Clipper",
                "action": "toggle-clipper",
                "icon": "clipboard"
            },
            {
                "label": pluginApi?.tr("context.settings") || "Open Settings",
                "action": "open-settings",
                "icon": "settings"
            },
        ]

        onTriggered: action => {
            contextMenu.close();
            PanelService.closeContextMenu(screen);

            if (action === "toggle-clipper") {
                if (pluginApi?.togglePanel) {
                    pluginApi.togglePanel(screen);
                }
            } else if (action === "open-settings") {
                if (pluginApi?.manifest) {
                    BarService.openPluginSettings(screen, pluginApi.manifest);
                }
            }
        }
    }

    onClicked: {
        if (pluginApi?.openPanel) {
            pluginApi.openPanel(screen);
        }
    }

    onRightClicked: {
        PanelService.showContextMenu(contextMenu, root, screen);
    }
}
