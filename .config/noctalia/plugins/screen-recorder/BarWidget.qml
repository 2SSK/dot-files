import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Services.System
import qs.Widgets

NIconButton {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    // Bar positioning properties
    readonly property string screenName: screen ? screen.name : ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isVertical: barPosition === "left" || barPosition === "right"
    readonly property real barHeight: Style.getBarHeightForScreen(screenName)
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

    readonly property var mainInstance: pluginApi?.mainInstance
    readonly property bool hideInactive:
        pluginApi?.pluginSettings?.hideInactive ??
        pluginApi?.manifest?.metadata?.defaultSettings?.hideInactive ??
        false

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    readonly property string iconColorKey: cfg.iconColor ?? defaults.iconColor ?? "none"
    readonly property color iconColor: Color.resolveColorKey(iconColorKey)

    readonly property bool shouldShow: !hideInactive || (mainInstance?.isRecording ?? false) || (mainInstance?.isPending ?? false)

    visible: true
    opacity: shouldShow ? 1.0 : 0.0
    implicitWidth: shouldShow ? baseSize : 0
    implicitHeight: shouldShow ? baseSize : 0

    Behavior on opacity {
        NumberAnimation { duration: Style.animationNormal }
    }

    Behavior on implicitWidth {
        NumberAnimation { duration: Style.animationNormal }
    }

    Behavior on implicitHeight {
        NumberAnimation { duration: Style.animationNormal }
    }

    enabled: mainInstance?.isAvailable ?? false
    icon: "camera-video"
    tooltipText: mainInstance?.buildTooltip()
    tooltipDirection: BarService.getTooltipDirection()
    baseSize: root.capsuleHeight
    applyUiScale: false
    customRadius: Style.radiusL
    colorBg: (mainInstance?.isRecording || mainInstance?.isPending) ? Color.mPrimary : Style.capsuleColor
    colorFg: (mainInstance?.isRecording || mainInstance?.isPending) ? Color.mOnPrimary : root.iconColor
    colorBorder: "transparent"
    colorBorderHover: "transparent"
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    onClicked: {
        if (!enabled) {
            ToastService.showError(pluginApi.tr("messages.not-installed"), pluginApi.tr("messages.not-installed-desc"))
            return
        }

        if (mainInstance) {
            mainInstance.toggleRecording()
            if (!mainInstance.isRecording && !mainInstance.isPending) {
                // Recording was stopped, close control center if open
                var controlCenter = PanelService.getPanel("controlCenterPanel", screen)
                if (controlCenter) {
                    controlCenter.close()
                }
            }
        }
    }

    onRightClicked: {
        PanelService.showContextMenu(contextMenu, root, screen);
    }


    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": I18n.tr("actions.widget-settings"),
                "action": "widget-settings",
                "icon": "settings"
            },
        ]

        onTriggered: action => {
            contextMenu.close();
            PanelService.closeContextMenu(screen);

            if (action === "widget-settings") {
                BarService.openPluginSettings(screen, pluginApi.manifest);
            }
        }
    }

}
