import QtQuick
import Quickshell
import qs.Services.UI
import qs.Widgets

NIconButtonHot {
  property ShellScreen screen
  property var pluginApi: null

  icon: "clipboard-check"

  function getTooltipText() {
    if (!pluginApi)
      return "Todo List";
    var todoCount = pluginApi.pluginSettings?.count || 0;
    var completedCount = pluginApi.pluginSettings?.completedCount || 0;
    var activeCount = todoCount - completedCount;
    var key = activeCount === 1 ? "bar_widget.todo_count_singular" : "bar_widget.todo_count_plural";
    return pluginApi.tr(key).replace("{count}", activeCount);
  }

  tooltipText: getTooltipText()

  onClicked: {
    if (pluginApi) {
      pluginApi.togglePanel(screen, this);
    }
  }

  onRightClicked: {
    if (pluginApi && pluginApi.manifest) {
      BarService.openPluginSettings(screen, pluginApi.manifest);
    }
  }
}
