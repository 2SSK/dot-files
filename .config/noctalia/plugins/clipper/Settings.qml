import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: 0

    property var pluginApi: null

    // ToDo integration
    property bool todoPluginAvailable: false
    property bool enableTodoIntegration: pluginApi?.pluginSettings?.enableTodoIntegration ?? false

    // Available card types
    readonly property var cardTypes: [
        { key: "Text", name: "Text" },
        { key: "Image", name: "Image" },
        { key: "Link", name: "Link" },
        { key: "Code", name: "Code" },
        { key: "Color", name: "Color" },
        { key: "Emoji", name: "Emoji" },
        { key: "File", name: "File" }
    ]

    // Available colors from Color scheme
    readonly property var colorOptions: [
        { key: "mPrimary", name: "Primary" },
        { key: "mOnPrimary", name: "On Primary" },
        { key: "mSecondary", name: "Secondary" },
        { key: "mOnSecondary", name: "On Secondary" },
        { key: "mTertiary", name: "Tertiary" },
        { key: "mOnTertiary", name: "On Tertiary" },
        { key: "mSurface", name: "Surface" },
        { key: "mOnSurface", name: "On Surface" },
        { key: "mSurfaceVariant", name: "Surface Variant" },
        { key: "mOnSurfaceVariant", name: "On Surface Variant" },
        { key: "mOutline", name: "Outline" },
        { key: "mError", name: "Error" },
        { key: "mOnError", name: "On Error" },
        { key: "mHover", name: "Hover" },
        { key: "mOnHover", name: "On Hover" },
        { key: "custom", name: "Custom..." }
    ]

    // Currently selected card type for editing
    property string selectedCardType: "Text"

    // Default colors per card type
    readonly property var defaultCardColors: {
        "Text": { bg: "mOutline", separator: "mSurface", fg: "mOnSurface" },
        "Image": { bg: "mTertiary", separator: "mSurface", fg: "mOnTertiary" },
        "Link": { bg: "mPrimary", separator: "mSurface", fg: "mOnPrimary" },
        "Code": { bg: "mSecondary", separator: "mSurface", fg: "mOnSecondary" },
        "Color": { bg: "mSecondary", separator: "mSurface", fg: "mOnSecondary" },
        "Emoji": { bg: "mHover", separator: "mSurface", fg: "mOnHover" },
        "File": { bg: "mError", separator: "mSurface", fg: "mOnError" }
    }

    // Current card colors (loaded from settings or defaults)
    property var cardColors: JSON.parse(JSON.stringify(defaultCardColors))

    // Custom color values (when "custom" is selected)
    property var customColors: {
        "Text": { bg: "#555555", separator: "#000000", fg: "#e9e4f0" },
        "Image": { bg: "#e0b7c9", separator: "#000000", fg: "#20161f" },
        "Link": { bg: "#c7a1d8", separator: "#000000", fg: "#1a151f" },
        "Code": { bg: "#a984c4", separator: "#000000", fg: "#f3edf7" },
        "Color": { bg: "#a984c4", separator: "#000000", fg: "#f3edf7" },
        "Emoji": { bg: "#e0b7c9", separator: "#000000", fg: "#20161f" },
        "File": { bg: "#e9899d", separator: "#000000", fg: "#1e1418" }
    }

    // Home directory for path resolution
    readonly property string homeDir: Quickshell.env("HOME") || ""



    // Check if ToDo plugin is installed and enabled
    FileView {
        id: pluginsConfigFile
        path: root.homeDir + "/.config/noctalia/plugins.json"
        printErrors: false
        watchChanges: true
        onLoaded: {
            try {
                const content = text();
                if (content && content.length > 0) {
                    const config = JSON.parse(content);
                    root.todoPluginAvailable = config?.states?.todo?.enabled === true;
                }
            } catch (e) {
                root.todoPluginAvailable = false;
            }
        }
    }

    Component.onCompleted: {
        // Load saved settings
        if (pluginApi?.pluginSettings?.cardColors) {
            try {
                cardColors = JSON.parse(JSON.stringify(pluginApi.pluginSettings.cardColors));
            } catch (e) {
            }
        }
        if (pluginApi?.pluginSettings?.customColors) {
            try {
                customColors = JSON.parse(JSON.stringify(pluginApi.pluginSettings.customColors));
            } catch (e) {
            }
        }
        if (pluginApi?.pluginSettings?.enableTodoIntegration !== undefined) {
            enableTodoIntegration = pluginApi.pluginSettings.enableTodoIntegration;
        }
    }

    // Helper to get actual color value
    function getColorValue(colorKey, cardType, colorType) {
        if (colorKey === "custom") {
            return customColors[cardType]?.[colorType] || "#888888";
        }
        if (typeof Color !== "undefined" && Color[colorKey]) {
            return Color[colorKey];
        }
        return "#888888";
    }

    // Get current colors for preview
    function getPreviewBg() {
        return getColorValue(cardColors[selectedCardType]?.bg || "mOutline", selectedCardType, "bg");
    }
    function getPreviewSeparator() {
        return getColorValue(cardColors[selectedCardType]?.separator || "mSurface", selectedCardType, "separator");
    }
    function getPreviewFg() {
        return getColorValue(cardColors[selectedCardType]?.fg || "mOnSurface", selectedCardType, "fg");
    }

    // Tab bar
    NTabBar {
        id: tabBar
        Layout.fillWidth: true
        Layout.bottomMargin: Style.marginM
        distributeEvenly: true
        currentIndex: tabView.currentIndex

        NTabButton {
            text: pluginApi?.tr("settings.tab-general") || "General"
            tabIndex: 0
            checked: tabBar.currentIndex === 0
        }
        NTabButton {
            text: pluginApi?.tr("settings.tab-appearance") || "Appearance"
            tabIndex: 1
            checked: tabBar.currentIndex === 1
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: Style.marginS
    }

    // Tab view
    NTabView {
        id: tabView
        currentIndex: tabBar.currentIndex

        // TAB 1: GENERAL
        ColumnLayout {
            spacing: Style.marginL

    // ===== INTEGRATIONS SECTION =====
    NText {
        text: pluginApi?.tr("settings.integrations") || "Integrations"
        font.bold: true
        font.pointSize: Style.fontSizeL
    }

    // ToDo Integration Toggle
    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.todo-integration") || "ToDo Plugin Integration"
        description: root.todoPluginAvailable
            ? (pluginApi?.tr("settings.todo-description") || "Add clipboard items directly to your ToDo list")
            : (pluginApi?.tr("settings.todo-disabled") || "ToDo plugin is not installed or disabled")
        enabled: root.todoPluginAvailable
        checked: root.enableTodoIntegration
        onToggled: checked => {
            root.enableTodoIntegration = checked;
            root.saveSettings();
        }
    }

    NDivider {
        Layout.fillWidth: true
    }

    // ===== FEATURES SECTION =====
    NText {
        text: pluginApi?.tr("settings.features") || "Features"
        font.bold: true
        font.pointSize: Style.fontSizeL
    }

    // PinCards Enable Toggle
    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.pincards-enabled") || "Enable Pin Cards"
        description: pluginApi?.tr("settings.pincards-desc") || "Show pinned items panel and allow pinning clipboard items"
        checked: pluginApi?.pluginSettings?.pincardsEnabled ?? true
        onToggled: checked => {
            if (pluginApi) {
                pluginApi.pluginSettings.pincardsEnabled = checked;
                pluginApi.saveSettings();
            }
        }
    }

    // Pinned items count display
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM
        visible: pluginApi?.pluginSettings?.pincardsEnabled ?? true

        NText {
            text: pluginApi?.tr("settings.pincards-items-count") || "Pinned Items"
            font.bold: true
        }

        Item { Layout.fillWidth: true }

        NText {
            text: {
                const count = pluginApi?.mainInstance?.pinnedItems?.length || 0;
                const max = pluginApi?.mainInstance?.maxPinnedItems || 20;
                return count + " / " + max;
            }
            color: {
                const count = pluginApi?.mainInstance?.pinnedItems?.length || 0;
                const max = pluginApi?.mainInstance?.maxPinnedItems || 20;
                return count >= max ? Color.mError : Color.mOnSurface;
            }
        }
    }

    // Clear all pinned items button
    NButton {
        Layout.alignment: Qt.AlignRight
        text: pluginApi?.tr("settings.clear-all-pinned") || "Clear All Pinned Items"
        icon: "trash"
        visible: pluginApi?.pluginSettings?.pincardsEnabled ?? true
        enabled: (pluginApi?.mainInstance?.pinnedItems?.length || 0) > 0
        onClicked: {
            if (pluginApi?.mainInstance) {
                // Clear all pinned items
                pluginApi.mainInstance.pinnedItems = [];
                pluginApi.mainInstance.savePinnedFile();
                pluginApi.mainInstance.pinnedRevision++;
                ToastService.showNotice(pluginApi?.tr("toast.pinned-cleared") || "All pinned items cleared");
            }
        }
    }

    // NoteCards Enable Toggle
    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.notecards-enabled") || "Enable NoteCards"
        description: pluginApi?.tr("settings.notecards-desc") || "Show notecards panel for quick notes and sticky notes"
        checked: pluginApi?.pluginSettings?.notecardsEnabled ?? true
        onToggled: checked => {
            if (pluginApi) {
                pluginApi.pluginSettings.notecardsEnabled = checked;
                pluginApi.saveSettings();
            }
        }
    }

    // Notes count display
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM
        visible: pluginApi?.pluginSettings?.notecardsEnabled ?? true

        NText {
            text: pluginApi?.tr("settings.notecards-notes-count") || "Current Notes"
            font.bold: true
        }

        Item { Layout.fillWidth: true }

        NText {
            text: {
                const count = pluginApi?.mainInstance?.noteCards?.length || 0;
                const max = pluginApi?.mainInstance?.maxNoteCards || 20;
                return count + " / " + max;
            }
            color: {
                const count = pluginApi?.mainInstance?.noteCards?.length || 0;
                const max = pluginApi?.mainInstance?.maxNoteCards || 20;
                return count >= max ? Color.mError : Color.mOnSurface;
            }
        }
    }

    // Clear all notes button
    NButton {
        Layout.alignment: Qt.AlignRight
        text: pluginApi?.tr("settings.clear-all-notes") || "Clear All Notes"
        icon: "trash"
        visible: pluginApi?.pluginSettings?.notecardsEnabled ?? true
        enabled: (pluginApi?.mainInstance?.noteCards?.length || 0) > 0
        onClicked: {
            if (pluginApi?.mainInstance) {
                // Clear all notes
                pluginApi.mainInstance.noteCards = [];
                pluginApi.mainInstance.saveNoteCards();
                pluginApi.mainInstance.noteCardsRevision++;
                ToastService.showNotice(pluginApi?.tr("toast.notes-cleared") || "All notes cleared");
            }
        }
    }

    NDivider {
        Layout.fillWidth: true
    }

    // Show close button toggle
    NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.show-close-button") || "Show Close Button"
        description: pluginApi?.tr("settings.show-close-button-desc") || "Display an X button at the top-right corner to close the panel"
        checked: pluginApi?.pluginSettings?.showCloseButton ?? false
        onToggled: checked => {
            if (pluginApi) {
                pluginApi.pluginSettings.showCloseButton = checked;
                pluginApi.saveSettings();
                // Update mainInstance property for immediate effect
                pluginApi.mainInstance.showCloseButton = checked;
            }
        }
    }

        }  // End General Tab

        // TAB 2: APPEARANCE
        ColumnLayout {
            spacing: Style.marginL

    // ===== APPEARANCE SECTION =====
    NText {
        text: pluginApi?.tr("settings.appearance") || "Card Appearance"
        font.bold: true
        font.pointSize: Style.fontSizeL
    }

    // Card type selector
    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.card-type") || "Card Type"
        description: pluginApi?.tr("settings.card-type-desc") || "Select card type to customize"
        model: root.cardTypes
        currentKey: root.selectedCardType
        onSelected: key => root.selectedCardType = key
    }

    // Live Preview
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 280
        color: (typeof Color !== "undefined") ? Color.mSurfaceVariant : "#333333"
        radius: Style.radiusM

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginS

            NText {
                text: pluginApi?.tr("settings.preview") || "Preview"
                font.bold: true
                color: root.getPreviewFg()
            }

            // Preview card
            Rectangle {
                Layout.preferredWidth: 250
                Layout.preferredHeight: 220
                Layout.alignment: Qt.AlignHCenter
                color: root.getPreviewBg()
                radius: Style.radiusM
                border.width: 2
                border.color: root.getPreviewBg()

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        color: root.getPreviewBg()
                        radius: Style.radiusM

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: parent.radius
                            color: parent.color
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            NIcon {
                                icon: root.selectedCardType === "Image" ? "photo" :
                                      root.selectedCardType === "Link" ? "link" :
                                      root.selectedCardType === "Code" ? "code" :
                                      root.selectedCardType === "Color" ? "palette" :
                                      root.selectedCardType === "Emoji" ? "mood-smile" :
                                      root.selectedCardType === "File" ? "file" : "align-left"
                                pointSize: 12
                                color: root.getPreviewFg()
                            }

                            NText {
                                text: root.selectedCardType
                                font.bold: true
                                color: root.getPreviewFg()
                            }

                            Item { Layout.fillWidth: true }

                            NIcon {
                                icon: "trash"
                                pointSize: 12
                                color: root.getPreviewFg()
                            }
                        }
                    }

                    // Separator
                    Rectangle {
                        Layout.preferredWidth: parent.width - 10
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 1
                        color: root.getPreviewSeparator()
                    }

                    // Content area
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.margins: 8

                        NText {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            text: pluginApi?.tr("settings.sample-content") || "Sample content preview..."
                            wrapMode: Text.Wrap
                            color: root.getPreviewFg()
                            verticalAlignment: Text.AlignTop
                        }
                    }
                }
            }
        }
    }

    // Color settings
    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.bg-color") || "Background Color"
        description: pluginApi?.tr("settings.bg-color-desc") || "Card background color"
        model: root.colorOptions
        currentKey: root.cardColors[root.selectedCardType]?.bg || "mOutline"
        onSelected: key => {
            if (!root.cardColors[root.selectedCardType]) {
                root.cardColors[root.selectedCardType] = {};
            }
            root.cardColors[root.selectedCardType].bg = key;
            root.cardColorsChanged();
            root.saveSettings();
        }
    }

    NColorPicker {
        visible: root.cardColors[root.selectedCardType]?.bg === "custom"
        Layout.preferredWidth: Style.sliderWidth
        Layout.preferredHeight: Style.baseWidgetSize
        selectedColor: root.customColors[root.selectedCardType]?.bg || "#888888"
        onColorSelected: color => {
            if (!root.customColors[root.selectedCardType]) {
                root.customColors[root.selectedCardType] = {};
            }
            root.customColors[root.selectedCardType].bg = color.toString();
            root.customColorsChanged();
            root.saveSettings();
        }
    }

    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.separator-color") || "Separator Color"
        description: pluginApi?.tr("settings.separator-color-desc") || "Line between header and content"
        model: root.colorOptions
        currentKey: root.cardColors[root.selectedCardType]?.separator || "mSurface"
        onSelected: key => {
            if (!root.cardColors[root.selectedCardType]) {
                root.cardColors[root.selectedCardType] = {};
            }
            root.cardColors[root.selectedCardType].separator = key;
            root.cardColorsChanged();
            root.saveSettings();
        }
    }

    NColorPicker {
        visible: root.cardColors[root.selectedCardType]?.separator === "custom"
        Layout.preferredWidth: Style.sliderWidth
        Layout.preferredHeight: Style.baseWidgetSize
        selectedColor: root.customColors[root.selectedCardType]?.separator || "#000000"
        onColorSelected: color => {
            if (!root.customColors[root.selectedCardType]) {
                root.customColors[root.selectedCardType] = {};
            }
            root.customColors[root.selectedCardType].separator = color.toString();
            root.customColorsChanged();
            root.saveSettings();
        }
    }

    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.fg-color") || "Foreground Color"
        description: pluginApi?.tr("settings.fg-color-desc") || "Title, icons and content text color"
        model: root.colorOptions
        currentKey: root.cardColors[root.selectedCardType]?.fg || "mOnSurface"
        onSelected: key => {
            if (!root.cardColors[root.selectedCardType]) {
                root.cardColors[root.selectedCardType] = {};
            }
            root.cardColors[root.selectedCardType].fg = key;
            root.cardColorsChanged();
            root.saveSettings();
        }
    }

    NColorPicker {
        visible: root.cardColors[root.selectedCardType]?.fg === "custom"
        Layout.preferredWidth: Style.sliderWidth
        Layout.preferredHeight: Style.baseWidgetSize
        selectedColor: root.customColors[root.selectedCardType]?.fg || "#e9e4f0"
        onColorSelected: color => {
            if (!root.customColors[root.selectedCardType]) {
                root.customColors[root.selectedCardType] = {};
            }
            root.customColors[root.selectedCardType].fg = color.toString();
            root.customColorsChanged();
            root.saveSettings();
        }
    }

    // Reset button
    NButton {
        Layout.alignment: Qt.AlignRight
        text: pluginApi?.tr("settings.reset-defaults") || "Reset to Defaults"
        icon: "refresh"
        onClicked: {
            root.cardColors = JSON.parse(JSON.stringify(root.defaultCardColors));
            root.customColors = {
                "Text": { bg: "#555555", separator: "#000000", fg: "#e9e4f0" },
                "Image": { bg: "#e0b7c9", separator: "#000000", fg: "#20161f" },
                "Link": { bg: "#c7a1d8", separator: "#000000", fg: "#1a151f" },
                "Code": { bg: "#a984c4", separator: "#000000", fg: "#f3edf7" },
                "Color": { bg: "#a984c4", separator: "#000000", fg: "#f3edf7" },
                "Emoji": { bg: "#e0b7c9", separator: "#000000", fg: "#20161f" },
                "File": { bg: "#e9899d", separator: "#000000", fg: "#1e1418" }
            };
            root.saveSettings();
        }
    }

        }  // End Appearance Tab

    }  // End NTabView

    function saveSettings() {
        if (!pluginApi) {
            return;
        }

        pluginApi.pluginSettings.cardColors = JSON.parse(JSON.stringify(root.cardColors));
        pluginApi.pluginSettings.customColors = JSON.parse(JSON.stringify(root.customColors));
        pluginApi.pluginSettings.enableTodoIntegration = root.enableTodoIntegration;

        pluginApi.saveSettings();
    }
}
