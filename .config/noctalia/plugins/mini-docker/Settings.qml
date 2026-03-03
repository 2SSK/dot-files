import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    property int valueRefreshInterval: (pluginApi && pluginApi.pluginSettings) ? pluginApi.pluginSettings.refreshInterval : 5000

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("MiniDocker", "Cannot save settings: pluginApi is null");
            return ;
        }
        pluginApi.pluginSettings.refreshInterval = root.valueRefreshInterval;
        pluginApi.saveSettings();
        Logger.i("MiniDocker", "Settings saved successfully");
    }

    spacing: Style.marginM
    Component.onCompleted: {
        Logger.i("MiniDocker", "Settings UI loaded");
    }

    ListModel {
        id: intervalModel

        ListElement {
            name: "1 Second"
            key: "1000"
        }

        ListElement {
            name: "5 Seconds"
            key: "5000"
        }

        ListElement {
            name: "10 Seconds"
            key: "10000"
        }

        ListElement {
            name: "30 Seconds"
            key: "30000"
        }

    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: (pluginApi && pluginApi.tr) ? pluginApi.tr("settings.refresh_interval_label") : "Refresh Interval"
            description: (pluginApi && pluginApi.tr) ? pluginApi.tr("settings.refresh_interval_description") : "How often the plugin checks for container status changes"
        }

        NComboBox {
            Layout.fillWidth: true
            model: intervalModel
            currentKey: root.valueRefreshInterval.toString()
            onSelected: {
                root.valueRefreshInterval = parseInt(key);
            }
        }

        Text {
            text: ((pluginApi && pluginApi.tr) ? pluginApi.tr("settings.current_value") : "Selected: {value} ms").replace("{value}", root.valueRefreshInterval)
            color: Color.mOnSurfaceVariant
            font.pointSize: Style.fontSizeS
        }

    }

}
