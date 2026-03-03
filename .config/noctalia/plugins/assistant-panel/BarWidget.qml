import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI
import qs.Services.System
import "Constants.js" as Constants

Item {
  id: root

  property var pluginApi: null

  // Required properties for bar widgets
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  // Access main instance for state
  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property bool isGenerating: mainInstance?.isGenerating || false
  readonly property int messageCount: mainInstance?.messages?.length || 0

  // Property to check if an API key is configured
  readonly property bool hasApiKey: {
    var provider = pluginApi?.pluginSettings?.ai?.provider || Constants.Providers.GOOGLE;

    // Check environment variable first (generic key check)
    var envVarName = provider === Constants.Providers.GOOGLE ? "NOCTALIA_AP_GOOGLE_API_KEY" : "NOCTALIA_AP_OPENAI_COMPATIBLE_API_KEY";

    var envKey = Quickshell.env(envVarName) || "";
    if (envKey !== "")
      return true;

    // Check specific provider setting
    var settingsKey = pluginApi?.pluginSettings?.ai?.apiKeys?.[provider] || "";

    // For OpenAI Compatible Local mode, key is not required
    if (provider === Constants.Providers.OPENAI_COMPATIBLE) {
      var isLocal = pluginApi?.pluginSettings?.ai?.openaiLocal ?? false;
      if (isLocal)
        return true;
    }

    return settingsKey.trim() !== "";
  }

  // Per-screen bar properties
  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real barHeight: Style.getBarHeightForScreen(screenName)
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  readonly property real contentWidth: capsuleHeight
  readonly property real contentHeight: capsuleHeight

  // Plugin UI scale (per-plugin setting)
  readonly property real uiScale: pluginApi?.pluginSettings?.scale ?? pluginApi?.manifest?.metadata?.defaultSettings?.scale ?? 1

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    NIcon {
      id: iconWidget
      anchors.centerIn: parent
      icon: root.isGenerating ? "loader-2" : "sparkles"
      color: {
        if (root.isGenerating)
          return Color.mPrimary;
        if (!root.hasApiKey)
          return Color.mOnSurfaceVariant;
        return Color.mOnSurface;
      }
      applyUiScale: false

      // Rotation animation when generating
      RotationAnimation on rotation {
        running: root.isGenerating
        from: 0
        to: 360
        duration: 1000
        loops: Animation.Infinite
      }

      // Reset rotation when not generating
      Binding {
        target: iconWidget
        property: "rotation"
        value: 0
        when: !root.isGenerating
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onEntered: {
      TooltipService.show(root, buildTooltip(), BarService.getTooltipDirection());
    }

    onExited: {
      TooltipService.hide();
    }

    onClicked: function (mouse) {
      if (mouse.button === Qt.LeftButton) {
        if (pluginApi) {
          pluginApi.openPanel(root.screen, root);
        }
      } else if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen);
      }
    }
  }

  NPopupContextMenu {
    id: contextMenu

    model: [
      {
        "label": pluginApi?.tr("menu.openPanel") || "Open Panel",
        "action": "open",
        "icon": "external-link"
      },
      {
        "label": pluginApi?.tr("menu.clearHistory") || "Clear History",
        "action": "clear",
        "icon": "trash"
      },
      {
        "label": pluginApi?.tr("menu.settings") || "Settings",
        "action": "settings",
        "icon": "settings"
      }
    ]

    onTriggered: function (action) {
      contextMenu.close();
      PanelService.closeContextMenu(screen);

      if (action === "open") {
        pluginApi?.openPanel(root.screen, root);
      } else if (action === "clear") {
        if (mainInstance) {
          mainInstance.clearMessages();
          ToastService.showNotice(pluginApi?.tr("toast.historyCleared") || "Chat history cleared");
        }
      } else if (action === "settings") {
        BarService.openPluginSettings(screen, pluginApi.manifest);
      }
    }
  }

  function buildTooltip() {
    var tooltip = pluginApi?.tr("widget.tooltipTitle") || "AI Assistant";

    if (!hasApiKey) {
      tooltip += "\n" + (pluginApi?.tr("widget.noApiKey") || "Configure API key in settings");
      return tooltip;
    }

    var provider = pluginApi?.pluginSettings?.ai?.provider || Constants.Providers.GOOGLE;
    var providerName = mainInstance?.providers?.[provider]?.name || provider;

    tooltip += "\n" + (pluginApi?.tr("widget.provider") || "Provider") + ": " + providerName;

    if (messageCount > 0) {
      tooltip += "\n" + (pluginApi?.tr("widget.messages") || "Messages") + ": " + messageCount;
    }

    if (isGenerating) {
      tooltip += "\n" + (pluginApi?.tr("widget.generating") || "Generating response...");
    }

    tooltip += "\n\n" + (pluginApi?.tr("widget.rightClickHint") || "Right-click for options");

    return tooltip;
  }

  Component.onCompleted: {
    Logger.i("AssistantPanel", "BarWidget initialized");
  }
}
