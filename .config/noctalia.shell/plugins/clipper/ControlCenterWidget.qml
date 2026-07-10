import QtQuick
import Quickshell
import qs.Services.UI
import qs.Widgets

NIconButtonHot {
    property ShellScreen screen
    property var pluginApi: null

    icon: "clipboard-data"
    tooltipText: pluginApi?.tr("bar.tooltip")

    onClicked: {
        if (pluginApi) {
            pluginApi.togglePanel(screen);
        }
    }

    onRightClicked: {
        if (pluginApi && pluginApi.manifest) {
            BarService.openPluginSettings(screen, pluginApi.manifest);
        }
    }
}
