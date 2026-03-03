import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
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

  readonly property real contentWidth: root.isVertical ? root.capsuleHeight : horizontalRow.implicitWidth + Style.marginM * 2
  readonly property real contentHeight: root.isVertical ? root.capsuleHeight : root.capsuleHeight

  readonly property int todoCount: getIntValue(pluginApi?.pluginSettings?.count, getIntValue(pluginApi?.manifest?.metadata?.defaultSettings?.count, 0))
  readonly property int completedCount: getIntValue(pluginApi?.pluginSettings?.completedCount, getIntValue(pluginApi?.manifest?.metadata?.defaultSettings?.completedCount, 0))
  readonly property int activeCount: todoCount - completedCount
  readonly property color contentColor: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface

  // Tooltip text for vertical mode
  readonly property string tooltipText: {
    var count = root.activeCount;
    var key = count === 1 ? "bar_widget.todo_count_singular" : "bar_widget.todo_count_plural";
    return pluginApi?.tr(key).replace("{count}", count);
  }

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  function getIntValue(value, defaultValue) {
    return (typeof value === 'number') ? Math.floor(value) : defaultValue;
  }

  // Visual capsule - pixel-perfect centered
  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    radius: Style.radiusL
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Row {
      id: horizontalRow
      anchors.centerIn: parent
      spacing: Style.marginS
      visible: !root.isVertical

      NIcon {
        anchors.verticalCenter: parent.verticalCenter
        icon: "clipboard-check"
        applyUiScale: false
        color: root.contentColor
      }

      NText {
        anchors.verticalCenter: parent.verticalCenter
        text: {
          var textKey = activeCount === 1 ? "bar_widget.todo_count_singular" : "bar_widget.todo_count_plural";
          var text = pluginApi?.tr(textKey);
          return text.replace("{count}", activeCount);
        }
        color: root.contentColor
        pointSize: root.barFontSize
        applyUiScale: false
      }
    }

    Column {
      id: verticalColumn
      anchors.centerIn: parent
      spacing: Style.marginS
      visible: root.isVertical

      NIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        icon: "clipboard-check"
        applyUiScale: false
        color: root.contentColor
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onPressed: function (mouse) {
      if (mouse.button === Qt.RightButton) {
        // Open settings on right click
        if (pluginApi && pluginApi.manifest) {
          Logger.i("Todo", "Opening plugin settings");
          BarService.openPluginSettings(root.screen, pluginApi.manifest);
        }
      } else if (mouse.button === Qt.LeftButton) {
        // Open panel on left click
        if (pluginApi) {
          Logger.i("Todo", "Opening Todo panel");
          pluginApi.openPanel(root.screen);
        }
      }
    }
    onEntered: {
      if (root.isVertical) {
        TooltipService.show(root, tooltipText, BarService.getTooltipDirection(root.screen?.name));
      }
    }
    onExited: {
      TooltipService.hide();
    }
  }
}
