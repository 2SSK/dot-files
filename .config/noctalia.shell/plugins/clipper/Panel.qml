import QtQuick
import QtQuick.Controls
import Quickshell.Wayland
import Quickshell.Io
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Keyboard
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    // Plugin API (injected by PluginPanelSlot)
    property var pluginApi: null

    // Screen context - store reference for child components
    property var currentScreen: screen

    // Track currently open ToDo context menu
    property var activeContextMenu: null

    // Refresh clipboard list and load notecards when panel becomes visible
    // Save notecards when panel is closed
    onVisibleChanged: {
        if (visible) {
            pluginApi?.mainInstance?.refreshOnPanelOpen();
            pluginApi?.mainInstance?.loadNoteCards();
        } else {
            // Sync all local changes from notecards before saving
            if (noteCardsPanel && noteCardsPanel.children[0] && noteCardsPanel.children[0].syncAllChanges) {
                noteCardsPanel.children[0].syncAllChanges();
            }
            pluginApi?.mainInstance?.saveNoteCards();
        }
    }

    // SmartPanel properties (required for panel behavior)
    readonly property var geometryPlaceholder: mainContainer
    readonly property bool allowAttach: true

    // Panel dimensions - fullscreen transparent container
    property real contentPreferredWidth: (pluginApi?.pluginSettings?.fullscreenMode ?? false)
        ? (screen?.width ?? 1920)
        : (pluginApi?.pluginSettings?.panelWidth ?? 1450) * Style.uiScaleRatio
    property var contentPreferredHeight: {
        if (pluginApi?.pluginSettings?.fullscreenMode ?? false) return screen?.height ?? 900;
        var h = pluginApi?.pluginSettings?.panelHeight ?? 0;
        return h > 0 ? h * Style.uiScaleRatio : undefined;
    }

    // SmartPanel background color - transparent when hidePanelBackground is enabled
    property color panelBackgroundColor: (pluginApi?.pluginSettings?.hidePanelBackground ?? false)
        ? "transparent"
        : ((typeof Color !== "undefined") ? Color.mSurface : "#222222")

    // Keyboard navigation
    property int selectedIndex: 0

    // Filtering
    property string filterType: ""
    property string searchText: ""

    // Reset selection when filter changes
    onFilterTypeChanged: selectedIndex = 0
    onSearchTextChanged: selectedIndex = 0

    // Filtered items (uses shared getItemType from Main.qml)
    readonly property var filteredItems: {
        let items = pluginApi?.mainInstance?.items || [];
        if (!filterType && !searchText)
            return items;

        return items.filter(item => {
            if (filterType) {
                const itemType = pluginApi?.mainInstance?.getItemType(item) || "Text";
                if (itemType !== filterType)
                    return false;
            }
            if (searchText) {
                const preview = item.preview || "";
                if (!preview.toLowerCase().includes(searchText.toLowerCase()))
                    return false;
            }
            return true;
        });
    }

    Keys.onLeftPressed: {
        if (listView.count > 0) {
            selectedIndex = Math.max(0, selectedIndex - 1);
            listView.positionViewAtIndex(selectedIndex, ListView.Contain);
        }
    }

    Keys.onRightPressed: {
        if (listView.count > 0) {
            selectedIndex = Math.min(listView.count - 1, selectedIndex + 1);
            listView.positionViewAtIndex(selectedIndex, ListView.Contain);
        }
    }

    Keys.onReturnPressed: {
        if (listView.count > 0 && selectedIndex >= 0 && selectedIndex < listView.count) {
            const item = root.filteredItems[selectedIndex];
            if (item) {
                pluginApi?.mainInstance?.copyToClipboard(item.id);
                if (pluginApi) {
                    pluginApi.closePanel(screen);
                }
            }
        }
    }

    Keys.onEscapePressed: {
        if (pluginApi) {
            pluginApi.closePanel(screen);
        }
    }

    Keys.onDeletePressed: {
        if (listView.count > 0 && selectedIndex >= 0 && selectedIndex < listView.count) {
            const item = root.filteredItems[selectedIndex];
            if (item) {
                pluginApi?.mainInstance?.deleteById(item.id);
                if (selectedIndex >= listView.count - 1) {
                    selectedIndex = Math.max(0, listView.count - 2);
                }
            }
        }
    }

    Keys.onDigit1Pressed: filterType = ""
    Keys.onDigit2Pressed: filterType = "Text"
    Keys.onDigit3Pressed: filterType = "Image"
    Keys.onDigit4Pressed: filterType = "Color"
    Keys.onDigit5Pressed: filterType = "Link"
    Keys.onDigit6Pressed: filterType = "Code"
    Keys.onDigit7Pressed: filterType = "Emoji"
    Keys.onDigit8Pressed: filterType = "File"

    // Main container - transparent fullscreen
    Item {
        id: mainContainer
        anchors.fill: parent

        // Click-to-close backdrop — only active when panel background is hidden
        MouseArea {
            anchors.fill: parent
            z: -1
            enabled: pluginApi?.pluginSettings?.hidePanelBackground ?? false
            onClicked: {
                if (root.pluginApi)
                    root.pluginApi.closePanel(screen);
            }
        }

        NIconButton {
            visible: pluginApi?.mainInstance?.showCloseButton ?? false
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Style.marginM
            z: 10
            icon: "x"
            tooltipText: pluginApi?.tr("panel.close")
            colorBg: (typeof Color !== "undefined") ? Color.mSurfaceVariant : "#444444"
            colorBgHover: (typeof Color !== "undefined") ? Color.mError : "#CC0000"
            colorFg: (typeof Color !== "undefined") ? Color.mOnSurface : "#FFFFFF"
            colorFgHover: (typeof Color !== "undefined") ? Color.mOnError : "#FFFFFF"
            onClicked: {
                if (root.pluginApi) {
                    root.pluginApi.closePanel(screen);
                }
            }
        }

        // CLIPBOARD PANEL - Bottom, full width (horizontal)
        Rectangle {
            id: clipboardPanel
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.min(300, screen?.height * 0.3 || 300)
            color: (typeof Color !== "undefined") ? Color.mSurface : "#222222"
            radius: Style.radiusM
            opacity: 1.0  // Override global panel opacity

            Rectangle {
                topLeftRadius: Style.radiusM
                topRightRadius: Style.radiusM
                bottomLeftRadius: 0
                bottomRightRadius: 0
                opacity: 1.0
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.marginL
                spacing: Style.marginM

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginM

                    NText {
                        text: pluginApi?.tr("panel.title")
                        font.bold: true
                        font.pointSize: Style.fontSizeL
                        Layout.alignment: Qt.AlignVCenter
                        Layout.topMargin: -2 * Style.uiScaleRatio
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    NIconButton {
                        icon: "settings"
                        tooltipText: pluginApi?.tr("panel.settings")
                        Layout.alignment: Qt.AlignVCenter
                        colorBg: (typeof Color !== "undefined") ? Color.mSurfaceVariant : "#444444"
                        colorBgHover: (typeof Color !== "undefined") ? Color.mHover : "#666666"
                        colorFg: (typeof Color !== "undefined") ? Color.mOnSurface : "#FFFFFF"
                        colorFgHover: (typeof Color !== "undefined") ? Color.mOnSurface : "#FFFFFF"
                        onClicked: {
                            if (root.pluginApi) {
                                BarService.openPluginSettings(screen, root.pluginApi.manifest);
                            }
                        }
                    }

                    NTextInput {
                        id: searchInput
                        Layout.preferredWidth: 250
                        Layout.alignment: Qt.AlignVCenter
                        placeholderText: pluginApi?.tr("panel.search-placeholder")
                        text: root.searchText
                        onTextChanged: root.searchText = text

                        Keys.onEscapePressed: {
                            if (text !== "") {
                                text = "";
                            } else {
                                root.onEscapePressed();
                            }
                        }
                        Keys.onLeftPressed: event => {
                            if (searchInput.cursorPosition === 0) {
                                root.onLeftPressed();
                                event.accepted = true;
                            }
                        }
                        Keys.onRightPressed: event => {
                            if (searchInput.cursorPosition === text.length) {
                                root.onRightPressed();
                                event.accepted = true;
                            }
                        }
                        Keys.onReturnPressed: root.onReturnPressed()
                        Keys.onEnterPressed: root.onReturnPressed()
                        Keys.onTabPressed: event => {
                            root.filterType = "Text";
                            event.accepted = true;
                        }
                        Keys.onUpPressed: event => {
                            // Up = focus search (already focused, do nothing)
                            event.accepted = true;
                        }
                        Keys.onDownPressed: event => {
                            // Down = focus cards
                            listView.forceActiveFocus();
                            event.accepted = true;
                        }
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Home && event.modifiers & Qt.ControlModifier) {
                                root.onHomePressed();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_End && event.modifiers & Qt.ControlModifier) {
                                root.onEndPressed();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Delete) {
                                // Delete current card
                                if (listView.count > 0 && root.selectedIndex >= 0 && root.selectedIndex < listView.count) {
                                    const item = root.filteredItems[root.selectedIndex];
                                    if (item) {
                                        pluginApi?.mainInstance?.deleteById(item.id);
                                        if (root.selectedIndex >= listView.count - 1) {
                                            root.selectedIndex = Math.max(0, listView.count - 2);
                                        }
                                    }
                                }
                                event.accepted = true;
                            } else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                                // Number keys for filter types
                                const filterMap = {
                                    [Qt.Key_1]: "",
                                    [Qt.Key_2]: "Text",
                                    [Qt.Key_3]: "Image",
                                    [Qt.Key_4]: "Color",
                                    [Qt.Key_5]: "Link",
                                    [Qt.Key_6]: "Code",
                                    [Qt.Key_7]: "Emoji",
                                    [Qt.Key_8]: "File"
                                };
                                if (filterMap.hasOwnProperty(event.key)) {
                                    root.filterType = filterMap[event.key];
                                    event.accepted = true;
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Filter type -> accent color key mapping (mirrors ClipboardCard defaults)
                    // All/Text/Link/Emoji -> mPrimary, Image/File -> mTertiary, Color/Code -> mSecondary
                    RowLayout {
                        spacing: Style.marginXS
                        Layout.alignment: Qt.AlignVCenter

                        // --- ALL ---
                        Item {
                            readonly property string fType: ""
                            readonly property color accentColor: (typeof Color !== "undefined") ? Color.mPrimary : "#BB86FC"
                            readonly property color accentFgColor: (typeof Color !== "undefined") ? Color.mOnPrimary : "#FFFFFF"
                            readonly property bool isActive: root.filterType === fType
                            readonly property int itemCount: (pluginApi?.mainInstance?.items || []).length
                            // Expand slightly so the burst ring has room without clipping
                            width: btnAll.width + Style.fontSizeXS
                            height: btnAll.height + Style.fontSizeXS

                            NIconButton {
                                id: btnAll
                                anchors.centerIn: parent
                                focus: true
                                icon: "apps"
                                tooltipText: pluginApi?.tr("panel.filter-all")
                                colorBg: (typeof Color !== "undefined") ? (parent.isActive ? Color.mPrimary : Color.mSurfaceVariant) : "#444444"
                                colorBgHover: (typeof Color !== "undefined") ? (parent.isActive ? Color.mPrimary : Color.mHover) : "#666666"
                                colorFg: (typeof Color !== "undefined") ? (parent.isActive ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                                colorFgHover: (typeof Color !== "undefined") ? (parent.isActive ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                                onClicked: root.filterType = ""
                                Keys.onTabPressed: {
                                    root.filterType = "";
                                    event.accepted = true;
                                }
                            }

                            // Active burst ring - matches groupedWorkspaceNumberBurst
                            Rectangle {
                                anchors.centerIn: btnAll
                                width: btnAll.width + 8
                                height: btnAll.height + 8
                                radius: Math.min(width, height) / 2
                                color: "transparent"
                                border.color: (typeof Color !== "undefined") ? parent.accentColor : "#BB86FC"
                                border.width: 2
                                opacity: parent.isActive ? 0.85 : 0
                                scale: parent.isActive ? 1.0 : 0.7
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Style.animationFast
                                        easing.type: Easing.InOutCubic
                                    }
                                }
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Style.animationFast
                                        easing.type: Easing.OutBack
                                    }
                                }
                            }

                            // Count badge - matches groupedWorkspaceNumberContainer pattern
                            Item {
                                visible: parent.itemCount > 0
                                anchors {
                                    left: btnAll.left
                                    top: btnAll.top
                                    leftMargin: -Style.fontSizeXS * 0.55
                                    topMargin: -Style.fontSizeXS * 0.25
                                }
                                width: Math.max(badgeAll.implicitWidth + Style.margin2XS, Style.fontSizeXXS * 2)
                                height: Math.max(badgeAll.implicitHeight + Style.marginXS, Style.fontSizeXXS * 2)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Math.min(Style.radiusL, width / 2)
                                    color: (typeof Color !== "undefined") ? parent.parent.accentColor : "#BB86FC"
                                    scale: parent.parent.parent.isActive ? 1.0 : 0.85
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: Style.animationNormal
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                    Behavior on color {
                                        enabled: (typeof Color !== "undefined") && !Color.isTransitioning
                                        ColorAnimation {
                                            duration: Style.animationFast
                                            easing.type: Easing.InOutCubic
                                        }
                                    }
                                }

                                NText {
                                    id: badgeAll
                                    anchors.centerIn: parent
                                    text: parent.parent.itemCount > 99 ? "99+" : parent.parent.itemCount
                                    font.pointSize: (typeof Style !== "undefined") ? Style.fontSizeXS * 0.75 : 8
                                    font.bold: true
                                    color: (typeof Color !== "undefined") ? parent.parent.accentFgColor : "#FFFFFF"
                                }
                            }
                        }

                        // --- TEXT ---
                        Item {
                            readonly property string fType: "Text"
                            readonly property color accentColor: (typeof Color !== "undefined") ? Color.mPrimary : "#BB86FC"
                            readonly property color accentFgColor: (typeof Color !== "undefined") ? Color.mOnPrimary : "#FFFFFF"
                            readonly property bool isActive: root.filterType === fType
                            readonly property int itemCount: {
                                const all = pluginApi?.mainInstance?.items || [];
                                return all.filter(i => (pluginApi?.mainInstance?.getItemType(i) || "Text") === "Text").length;
                            }
                            width: btnText.width + Style.fontSizeXS
                            height: btnText.height + Style.fontSizeXS

                            NIconButton {
                                id: btnText
                                anchors.centerIn: parent
                                focus: true
                                icon: "align-left"
                                tooltipText: pluginApi?.tr("panel.filter-text")
                                colorBg: (typeof Color !== "undefined") ? (parent.isActive ? Color.mPrimary : Color.mSurfaceVariant) : "#444444"
                                colorBgHover: (typeof Color !== "undefined") ? (parent.isActive ? Color.mPrimary : Color.mHover) : "#666666"
                                colorFg: (typeof Color !== "undefined") ? (parent.isActive ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                                colorFgHover: (typeof Color !== "undefined") ? (parent.isActive ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                                onClicked: root.filterType = "Text"
                                Keys.onTabPressed: {
                                    root.filterType = "Image";
                                    event.accepted = true;
                                }
                            }

                            Rectangle {
                                anchors.centerIn: btnText
                                width: btnText.width + 8
                                height: btnText.height + 8
                                radius: Math.min(width, height) / 2
                                color: "transparent"
                                border.color: (typeof Color !== "undefined") ? parent.accentColor : "#BB86FC"
                                border.width: 2
                                opacity: parent.isActive ? 0.85 : 0
                                scale: parent.isActive ? 1.0 : 0.7
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Style.animationFast
                                        easing.type: Easing.InOutCubic
                                    }
                                }
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Style.animationFast
                                        easing.type: Easing.OutBack
                                    }
                                }
                            }

                            Item {
                                visible: parent.itemCount > 0
                                anchors {
                                    left: btnText.left
                                    top: btnText.top
                                    leftMargin: -Style.fontSizeXS * 0.55
                                    topMargin: -Style.fontSizeXS * 0.25
                                }
                                width: Math.max(badgeText.implicitWidth + Style.margin2XS, Style.fontSizeXXS * 2)
                                height: Math.max(badgeText.implicitHeight + Style.marginXS, Style.fontSizeXXS * 2)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Math.min(Style.radiusL, width / 2)
                                    color: (typeof Color !== "undefined") ? parent.parent.accentColor : "#BB86FC"
                                    scale: parent.parent.parent.isActive ? 1.0 : 0.85
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: Style.animationNormal
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                    Behavior on color {
                                        enabled: (typeof Color !== "undefined") && !Color.isTransitioning
                                        ColorAnimation {
                                            duration: Style.animationFast
                                            easing.type: Easing.InOutCubic
                                        }
                                    }
                                }
                                NText {
                                    id: badgeText
                                    anchors.centerIn: parent
                                    text: parent.parent.itemCount > 99 ? "99+" : parent.parent.itemCount
                                    font.pointSize: (typeof Style !== "undefined") ? Style.fontSizeXS * 0.75 : 8
                                    font.bold: true
                                    color: (typeof Color !== "undefined") ? parent.parent.accentFgColor : "#FFFFFF"
                                }
                            }
                        }

                        // --- IMAGE ---
                        Item {
                            readonly property string fType: "Image"
                            readonly property color accentColor: (typeof Color !== "undefined") ? Color.mTertiary : "#03DAC6"
                            readonly property color accentFgColor: (typeof Color !== "undefined") ? Color.mOnTertiary : "#FFFFFF"
                            readonly property bool isActive: root.filterType === fType
                            readonly property int itemCount: {
                                const all = pluginApi?.mainInstance?.items || [];
                                return all.filter(i => (pluginApi?.mainInstance?.getItemType(i) || "Text") === "Image").length;
                            }
                            width: btnImage.width + Style.fontSizeXS
                            height: btnImage.height + Style.fontSizeXS

                            NIconButton {
                                id: btnImage
                                anchors.centerIn: parent
                                focus: true
                                icon: "photo"
                                tooltipText: pluginApi?.tr("panel.filter-images")
                                colorBg: (typeof Color !== "undefined") ? (parent.isActive ? Color.mTertiary : Color.mSurfaceVariant) : "#444444"
                                colorBgHover: (typeof Color !== "undefined") ? (parent.isActive ? Color.mTertiary : Color.mHover) : "#666666"
                                colorFg: (typeof Color !== "undefined") ? (parent.isActive ? Color.mOnTertiary : Color.mOnSurface) : "#FFFFFF"
                                colorFgHover: (typeof Color !== "undefined") ? (parent.isActive ? Color.mOnTertiary : Color.mOnSurface) : "#FFFFFF"
                                onClicked: root.filterType = "Image"
                            }

                            Rectangle {
                                anchors.centerIn: btnImage
                                width: btnImage.width + 8
                                height: btnImage.height + 8
                                radius: Math.min(width, height) / 2
                                color: "transparent"
                                border.color: (typeof Color !== "undefined") ? parent.accentColor : "#03DAC6"
                                border.width: 2
                                opacity: parent.isActive ? 0.85 : 0
                                scale: parent.isActive ? 1.0 : 0.7
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Style.animationFast
                                        easing.type: Easing.InOutCubic
                                    }
                                }
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Style.animationFast
                                        easing.type: Easing.OutBack
                                    }
                                }
                            }

                            Item {
                                visible: parent.itemCount > 0
                                anchors {
                                    left: btnImage.left
                                    top: btnImage.top
                                    leftMargin: -Style.fontSizeXS * 0.55
                                    topMargin: -Style.fontSizeXS * 0.25
                                }
                                width: Math.max(badgeImage.implicitWidth + Style.margin2XS, Style.fontSizeXXS * 2)
                                height: Math.max(badgeImage.implicitHeight + Style.marginXS, Style.fontSizeXXS * 2)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Math.min(Style.radiusL, width / 2)
                                    color: (typeof Color !== "undefined") ? parent.parent.accentColor : "#03DAC6"
                                    scale: parent.parent.parent.isActive ? 1.0 : 0.85
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: Style.animationNormal
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                    Behavior on color {
                                        enabled: (typeof Color !== "undefined") && !Color.isTransitioning
                                        ColorAnimation {
                                            duration: Style.animationFast
                                            easing.type: Easing.InOutCubic
                                        }
                                    }
                                }
                                NText {
                                    id: badgeImage
                                    anchors.centerIn: parent
                                    text: parent.parent.itemCount > 99 ? "99+" : parent.parent.itemCount
                                    font.pointSize: (typeof Style !== "undefined") ? Style.fontSizeXS * 0.75 : 8
                                    font.bold: true
                                    color: (typeof Color !== "undefined") ? parent.parent.accentFgColor : "#FFFFFF"
                                }
                            }
                        }

                        // --- COLOR ---
                        Item {
                            readonly property string fType: "Color"
                            readonly property color accentColor: (typeof Color !== "undefined") ? Color.mSecondary : "#CF6679"
                            readonly property color accentFgColor: (typeof Color !== "undefined") ? Color.mOnSecondary : "#FFFFFF"
                            readonly property bool isActive: root.filterType === fType
                            readonly property int itemCount: {
                                const all = pluginApi?.mainInstance?.items || [];
                                return all.filter(i => (pluginApi?.mainInstance?.getItemType(i) || "Text") === "Color").length;
                            }
                            width: btnColorFilter.width + Style.fontSizeXS
                            height: btnColorFilter.height + Style.fontSizeXS

                            NIconButton {
                                id: btnColorFilter
                                anchors.centerIn: parent
                                focus: true
                                icon: "palette"
                                tooltipText: pluginApi?.tr("panel.filter-colors")
                                colorBg: (typeof Color !== "undefined") ? (parent.isActive ? Color.mSecondary : Color.mSurfaceVariant) : "#444444"
                                colorBgHover: (typeof Color !== "undefined") ? (parent.isActive ? Color.mSecondary : Color.mHover) : "#666666"
                                colorFg: (typeof Color !== "undefined") ? (parent.isActive ? Color.mOnSecondary : Color.mOnSurface) : "#FFFFFF"
                                colorFgHover: (typeof Color !== "undefined") ? (parent.isActive ? Color.mOnSecondary : Color.mOnSurface) : "#FFFFFF"
                                onClicked: root.filterType = "Color"
                            }

                            Rectangle {
                                anchors.centerIn: btnColorFilter
                                width: btnColorFilter.width + 8
                                height: btnColorFilter.height + 8
                                radius: Math.min(width, height) / 2
                                color: "transparent"
                                border.color: (typeof Color !== "undefined") ? parent.accentColor : "#CF6679"
                                border.width: 2
                                opacity: parent.isActive ? 0.85 : 0
                                scale: parent.isActive ? 1.0 : 0.7
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Style.animationFast
                                        easing.type: Easing.InOutCubic
                                    }
                                }
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Style.animationFast
                                        easing.type: Easing.OutBack
                                    }
                                }
                            }

                            Item {
                                visible: parent.itemCount > 0
                                anchors {
                                    left: btnColorFilter.left
                                    top: btnColorFilter.top
                                    leftMargin: -Style.fontSizeXS * 0.55
                                    topMargin: -Style.fontSizeXS * 0.25
                                }
                                width: Math.max(badgeColorFilter.implicitWidth + Style.margin2XS, Style.fontSizeXXS * 2)
                                height: Math.max(badgeColorFilter.implicitHeight + Style.marginXS, Style.fontSizeXXS * 2)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Math.min(Style.radiusL, width / 2)
                                    color: (typeof Color !== "undefined") ? parent.parent.accentColor : "#CF6679"
                                    scale: parent.parent.parent.isActive ? 1.0 : 0.85
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: Style.animationNormal
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                    Behavior on color {
                                        enabled: (typeof Color !== "undefined") && !Color.isTransitioning
                                        ColorAnimation {
                                            duration: Style.animationFast
                                            easing.type: Easing.InOutCubic
                                        }
                                    }
                                }
                                NText {
                                    id: badgeColorFilter
                                    anchors.centerIn: parent
                                    text: parent.parent.itemCount > 99 ? "99+" : parent.parent.itemCount
                                    font.pointSize: (typeof Style !== "undefined") ? Style.fontSizeXS * 0.75 : 8
                                    font.bold: true
                                    color: (typeof Color !== "undefined") ? parent.parent.accentFgColor : "#FFFFFF"
                                }
                            }
                        }

                        // --- LINK ---
                        Item {
                            readonly property string fType: "Link"
                            readonly property color accentColor: (typeof Color !== "undefined") ? Color.mPrimary : "#BB86FC"
                            readonly property color accentFgColor: (typeof Color !== "undefined") ? Color.mOnPrimary : "#FFFFFF"
                            readonly property bool isActive: root.filterType === fType
                            readonly property int itemCount: {
                                const all = pluginApi?.mainInstance?.items || [];
                                return all.filter(i => (pluginApi?.mainInstance?.getItemType(i) || "Text") === "Link").length;
                            }
                            width: btnLink.width + Style.fontSizeXS
                            height: btnLink.height + Style.fontSizeXS

                            NIconButton {
                                id: btnLink
                                anchors.centerIn: parent
                                focus: true
                                icon: "link"
                                tooltipText: pluginApi?.tr("panel.filter-links")
                                colorBg: (typeof Color !== "undefined") ? (parent.isActive ? Color.mPrimary : Color.mSurfaceVariant) : "#444444"
                                colorBgHover: (typeof Color !== "undefined") ? (parent.isActive ? Color.mPrimary : Color.mHover) : "#666666"
                                colorFg: (typeof Color !== "undefined") ? (parent.isActive ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                                colorFgHover: (typeof Color !== "undefined") ? (parent.isActive ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                                onClicked: root.filterType = "Link"
                            }

                            Rectangle {
                                anchors.centerIn: btnLink
                                width: btnLink.width + 8
                                height: btnLink.height + 8
                                radius: Math.min(width, height) / 2
                                color: "transparent"
                                border.color: (typeof Color !== "undefined") ? parent.accentColor : "#BB86FC"
                                border.width: 2
                                opacity: parent.isActive ? 0.85 : 0
                                scale: parent.isActive ? 1.0 : 0.7
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Style.animationFast
                                        easing.type: Easing.InOutCubic
                                    }
                                }
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Style.animationFast
                                        easing.type: Easing.OutBack
                                    }
                                }
                            }

                            Item {
                                visible: parent.itemCount > 0
                                anchors {
                                    left: btnLink.left
                                    top: btnLink.top
                                    leftMargin: -Style.fontSizeXS * 0.55
                                    topMargin: -Style.fontSizeXS * 0.25
                                }
                                width: Math.max(badgeLink.implicitWidth + Style.margin2XS, Style.fontSizeXXS * 2)
                                height: Math.max(badgeLink.implicitHeight + Style.marginXS, Style.fontSizeXXS * 2)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Math.min(Style.radiusL, width / 2)
                                    color: (typeof Color !== "undefined") ? parent.parent.accentColor : "#BB86FC"
                                    scale: parent.parent.parent.isActive ? 1.0 : 0.85
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: Style.animationNormal
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                    Behavior on color {
                                        enabled: (typeof Color !== "undefined") && !Color.isTransitioning
                                        ColorAnimation {
                                            duration: Style.animationFast
                                            easing.type: Easing.InOutCubic
                                        }
                                    }
                                }
                                NText {
                                    id: badgeLink
                                    anchors.centerIn: parent
                                    text: parent.parent.itemCount > 99 ? "99+" : parent.parent.itemCount
                                    font.pointSize: (typeof Style !== "undefined") ? Style.fontSizeXS * 0.75 : 8
                                    font.bold: true
                                    color: (typeof Color !== "undefined") ? parent.parent.accentFgColor : "#FFFFFF"
                                }
                            }
                        }

                        // --- CODE ---
                        Item {
                            readonly property string fType: "Code"
                            readonly property color accentColor: (typeof Color !== "undefined") ? Color.mSecondary : "#CF6679"
                            readonly property color accentFgColor: (typeof Color !== "undefined") ? Color.mOnSecondary : "#FFFFFF"
                            readonly property bool isActive: root.filterType === fType
                            readonly property int itemCount: {
                                const all = pluginApi?.mainInstance?.items || [];
                                return all.filter(i => (pluginApi?.mainInstance?.getItemType(i) || "Text") === "Code").length;
                            }
                            width: btnCode.width + Style.fontSizeXS
                            height: btnCode.height + Style.fontSizeXS

                            NIconButton {
                                id: btnCode
                                anchors.centerIn: parent
                                focus: true
                                icon: "code"
                                tooltipText: pluginApi?.tr("panel.filter-code")
                                colorBg: (typeof Color !== "undefined") ? (parent.isActive ? Color.mSecondary : Color.mSurfaceVariant) : "#444444"
                                colorBgHover: (typeof Color !== "undefined") ? (parent.isActive ? Color.mSecondary : Color.mHover) : "#666666"
                                colorFg: (typeof Color !== "undefined") ? (parent.isActive ? Color.mOnSecondary : Color.mOnSurface) : "#FFFFFF"
                                colorFgHover: (typeof Color !== "undefined") ? (parent.isActive ? Color.mOnSecondary : Color.mOnSurface) : "#FFFFFF"
                                onClicked: root.filterType = "Code"
                            }

                            Rectangle {
                                anchors.centerIn: btnCode
                                width: btnCode.width + 8
                                height: btnCode.height + 8
                                radius: Math.min(width, height) / 2
                                color: "transparent"
                                border.color: (typeof Color !== "undefined") ? parent.accentColor : "#CF6679"
                                border.width: 2
                                opacity: parent.isActive ? 0.85 : 0
                                scale: parent.isActive ? 1.0 : 0.7
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Style.animationFast
                                        easing.type: Easing.InOutCubic
                                    }
                                }
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Style.animationFast
                                        easing.type: Easing.OutBack
                                    }
                                }
                            }

                            Item {
                                visible: parent.itemCount > 0
                                anchors {
                                    left: btnCode.left
                                    top: btnCode.top
                                    leftMargin: -Style.fontSizeXS * 0.55
                                    topMargin: -Style.fontSizeXS * 0.25
                                }
                                width: Math.max(badgeCode.implicitWidth + Style.margin2XS, Style.fontSizeXXS * 2)
                                height: Math.max(badgeCode.implicitHeight + Style.marginXS, Style.fontSizeXXS * 2)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Math.min(Style.radiusL, width / 2)
                                    color: (typeof Color !== "undefined") ? parent.parent.accentColor : "#CF6679"
                                    scale: parent.parent.parent.isActive ? 1.0 : 0.85
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: Style.animationNormal
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                    Behavior on color {
                                        enabled: (typeof Color !== "undefined") && !Color.isTransitioning
                                        ColorAnimation {
                                            duration: Style.animationFast
                                            easing.type: Easing.InOutCubic
                                        }
                                    }
                                }
                                NText {
                                    id: badgeCode
                                    anchors.centerIn: parent
                                    text: parent.parent.itemCount > 99 ? "99+" : parent.parent.itemCount
                                    font.pointSize: (typeof Style !== "undefined") ? Style.fontSizeXS * 0.75 : 8
                                    font.bold: true
                                    color: (typeof Color !== "undefined") ? parent.parent.accentFgColor : "#FFFFFF"
                                }
                            }
                        }

                        // --- EMOJI ---
                        Item {
                            readonly property string fType: "Emoji"
                            readonly property color accentColor: (typeof Color !== "undefined") ? Color.mPrimary : "#BB86FC"
                            readonly property color accentFgColor: (typeof Color !== "undefined") ? Color.mOnPrimary : "#FFFFFF"
                            readonly property bool isActive: root.filterType === fType
                            readonly property int itemCount: {
                                const all = pluginApi?.mainInstance?.items || [];
                                return all.filter(i => (pluginApi?.mainInstance?.getItemType(i) || "Text") === "Emoji").length;
                            }
                            width: btnEmoji.width + Style.fontSizeXS
                            height: btnEmoji.height + Style.fontSizeXS

                            NIconButton {
                                id: btnEmoji
                                anchors.centerIn: parent
                                focus: true
                                icon: "mood-smile"
                                tooltipText: pluginApi?.tr("panel.filter-emoji")
                                colorBg: (typeof Color !== "undefined") ? (parent.isActive ? Color.mPrimary : Color.mSurfaceVariant) : "#444444"
                                colorBgHover: (typeof Color !== "undefined") ? (parent.isActive ? Color.mPrimary : Color.mHover) : "#666666"
                                colorFg: (typeof Color !== "undefined") ? (parent.isActive ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                                colorFgHover: (typeof Color !== "undefined") ? (parent.isActive ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                                onClicked: root.filterType = "Emoji"
                            }

                            Rectangle {
                                anchors.centerIn: btnEmoji
                                width: btnEmoji.width + 8
                                height: btnEmoji.height + 8
                                radius: Math.min(width, height) / 2
                                color: "transparent"
                                border.color: (typeof Color !== "undefined") ? parent.accentColor : "#BB86FC"
                                border.width: 2
                                opacity: parent.isActive ? 0.85 : 0
                                scale: parent.isActive ? 1.0 : 0.7
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Style.animationFast
                                        easing.type: Easing.InOutCubic
                                    }
                                }
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Style.animationFast
                                        easing.type: Easing.OutBack
                                    }
                                }
                            }

                            Item {
                                visible: parent.itemCount > 0
                                anchors {
                                    left: btnEmoji.left
                                    top: btnEmoji.top
                                    leftMargin: -Style.fontSizeXS * 0.55
                                    topMargin: -Style.fontSizeXS * 0.25
                                }
                                width: Math.max(badgeEmoji.implicitWidth + Style.margin2XS, Style.fontSizeXXS * 2)
                                height: Math.max(badgeEmoji.implicitHeight + Style.marginXS, Style.fontSizeXXS * 2)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Math.min(Style.radiusL, width / 2)
                                    color: (typeof Color !== "undefined") ? parent.parent.accentColor : "#BB86FC"
                                    scale: parent.parent.parent.isActive ? 1.0 : 0.85
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: Style.animationNormal
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                    Behavior on color {
                                        enabled: (typeof Color !== "undefined") && !Color.isTransitioning
                                        ColorAnimation {
                                            duration: Style.animationFast
                                            easing.type: Easing.InOutCubic
                                        }
                                    }
                                }
                                NText {
                                    id: badgeEmoji
                                    anchors.centerIn: parent
                                    text: parent.parent.itemCount > 99 ? "99+" : parent.parent.itemCount
                                    font.pointSize: (typeof Style !== "undefined") ? Style.fontSizeXS * 0.75 : 8
                                    font.bold: true
                                    color: (typeof Color !== "undefined") ? parent.parent.accentFgColor : "#FFFFFF"
                                }
                            }
                        }

                        // --- FILE ---
                        Item {
                            readonly property string fType: "File"
                            readonly property color accentColor: (typeof Color !== "undefined") ? Color.mTertiary : "#03DAC6"
                            readonly property color accentFgColor: (typeof Color !== "undefined") ? Color.mOnTertiary : "#FFFFFF"
                            readonly property bool isActive: root.filterType === fType
                            readonly property int itemCount: {
                                const all = pluginApi?.mainInstance?.items || [];
                                return all.filter(i => (pluginApi?.mainInstance?.getItemType(i) || "Text") === "File").length;
                            }
                            width: btnFile.width + Style.fontSizeXS
                            height: btnFile.height + Style.fontSizeXS

                            NIconButton {
                                id: btnFile
                                anchors.centerIn: parent
                                focus: true
                                icon: "file"
                                tooltipText: pluginApi?.tr("panel.filter-files")
                                colorBg: (typeof Color !== "undefined") ? (parent.isActive ? Color.mTertiary : Color.mSurfaceVariant) : "#444444"
                                colorBgHover: (typeof Color !== "undefined") ? (parent.isActive ? Color.mTertiary : Color.mHover) : "#666666"
                                colorFg: (typeof Color !== "undefined") ? (parent.isActive ? Color.mOnTertiary : Color.mOnSurface) : "#FFFFFF"
                                colorFgHover: (typeof Color !== "undefined") ? (parent.isActive ? Color.mOnTertiary : Color.mOnSurface) : "#FFFFFF"
                                onClicked: root.filterType = "File"
                            }

                            Rectangle {
                                anchors.centerIn: btnFile
                                width: btnFile.width + 8
                                height: btnFile.height + 8
                                radius: Math.min(width, height) / 2
                                color: "transparent"
                                border.color: (typeof Color !== "undefined") ? parent.accentColor : "#03DAC6"
                                border.width: 2
                                opacity: parent.isActive ? 0.85 : 0
                                scale: parent.isActive ? 1.0 : 0.7
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Style.animationFast
                                        easing.type: Easing.InOutCubic
                                    }
                                }
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Style.animationFast
                                        easing.type: Easing.OutBack
                                    }
                                }
                            }

                            Item {
                                visible: parent.itemCount > 0
                                anchors {
                                    left: btnFile.left
                                    top: btnFile.top
                                    leftMargin: -Style.fontSizeXS * 0.55
                                    topMargin: -Style.fontSizeXS * 0.25
                                }
                                width: Math.max(badgeFile.implicitWidth + Style.margin2XS, Style.fontSizeXXS * 2)
                                height: Math.max(badgeFile.implicitHeight + Style.marginXS, Style.fontSizeXXS * 2)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Math.min(Style.radiusL, width / 2)
                                    color: (typeof Color !== "undefined") ? parent.parent.accentColor : "#03DAC6"
                                    scale: parent.parent.parent.isActive ? 1.0 : 0.85
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: Style.animationNormal
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                    Behavior on color {
                                        enabled: (typeof Color !== "undefined") && !Color.isTransitioning
                                        ColorAnimation {
                                            duration: Style.animationFast
                                            easing.type: Easing.InOutCubic
                                        }
                                    }
                                }
                                NText {
                                    id: badgeFile
                                    anchors.centerIn: parent
                                    text: parent.parent.itemCount > 99 ? "99+" : parent.parent.itemCount
                                    font.pointSize: (typeof Style !== "undefined") ? Style.fontSizeXS * 0.75 : 8
                                    font.bold: true
                                    color: (typeof Color !== "undefined") ? parent.parent.accentFgColor : "#FFFFFF"
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 24
                        Layout.alignment: Qt.AlignVCenter
                        color: (typeof Color !== "undefined") ? Color.mOutline : "#888888"
                        opacity: 0.5
                    }

                    NButton {
                        focus: true
                        text: pluginApi?.tr("panel.clear-all")
                        icon: "trash"
                        Layout.alignment: Qt.AlignVCenter
                        Layout.topMargin: -2 * Style.uiScaleRatio
                        onClicked: pluginApi?.mainInstance?.wipeAll()
                    }
                }

                ListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Horizontal
                    spacing: Style.marginM
                    clip: true
                    currentIndex: root.selectedIndex
                    focus: false

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        onWheel: wheel => {
                            listView.flick(wheel.angleDelta.y * 12, 0);
                            wheel.accepted = true;
                        }
                    }

                    model: root.filteredItems

                    Keys.onUpPressed: {
                        searchInput.forceActiveFocus();
                    }
                    Keys.onLeftPressed: {
                        if (count > 0) {
                            root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                            positionViewAtIndex(root.selectedIndex, ListView.Contain);
                        }
                    }
                    Keys.onRightPressed: {
                        if (count > 0) {
                            root.selectedIndex = Math.min(count - 1, root.selectedIndex + 1);
                            positionViewAtIndex(root.selectedIndex, ListView.Contain);
                        }
                    }
                    Keys.onReturnPressed: {
                        if (count > 0 && root.selectedIndex >= 0 && root.selectedIndex < count) {
                            const item = root.filteredItems[root.selectedIndex];
                            if (item) {
                                root.pluginApi?.mainInstance?.copyToClipboard(item.id);
                                if (root.pluginApi) {
                                    root.pluginApi.closePanel(screen);
                                }
                            }
                        }
                    }
                    Keys.onDeletePressed: {
                        if (count > 0 && root.selectedIndex >= 0 && root.selectedIndex < count) {
                            const item = root.filteredItems[root.selectedIndex];
                            if (item) {
                                root.pluginApi?.mainInstance?.deleteById(item.id);
                                if (root.selectedIndex >= count - 1) {
                                    root.selectedIndex = Math.max(0, count - 2);
                                }
                            }
                        }
                    }
                    Keys.onEscapePressed: {
                        if (root.pluginApi) {
                            root.pluginApi.closePanel(screen);
                        }
                    }
                    Keys.onTabPressed: {
                        // Cycle through filters: All -> Text -> Image -> Color -> Link -> Code -> Emoji -> File -> All
                        const filters = ["", "Text", "Image", "Color", "Link", "Code", "Emoji", "File"];
                        const currentIdx = filters.indexOf(root.filterType);
                        const nextIdx = (currentIdx + 1) % filters.length;
                        root.filterType = filters[nextIdx];
                    }
                    Keys.onBacktabPressed: {
                        // Shift+Tab = cycle backwards
                        const filters = ["", "Text", "Image", "Color", "Link", "Code", "Emoji", "File"];
                        const currentIdx = filters.indexOf(root.filterType);
                        const prevIdx = (currentIdx - 1 + filters.length) % filters.length;
                        root.filterType = filters[prevIdx];
                    }
                    Keys.onPressed: event => {
                        if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                            const filterMap = {
                                [Qt.Key_1]: "",
                                [Qt.Key_2]: "Text",
                                [Qt.Key_3]: "Image",
                                [Qt.Key_4]: "Color",
                                [Qt.Key_5]: "Link",
                                [Qt.Key_6]: "Code",
                                [Qt.Key_7]: "Emoji",
                                [Qt.Key_8]: "File"
                            };
                            if (filterMap.hasOwnProperty(event.key)) {
                                root.filterType = filterMap[event.key];
                                event.accepted = true;
                            }
                        }
                    }

                    delegate: ClipboardCard {
                        clipboardItem: modelData
                        pluginApi: root.pluginApi
                        screen: root.currentScreen
                        panelRoot: root
                        height: listView.height
                        selected: index === root.selectedIndex
                        enableTodoIntegration: root.pluginApi?.pluginSettings?.enableTodoIntegration || false
                        isPinned: {
                            // Force re-evaluation when pinnedRevision changes
                            const rev = root.pluginApi?.mainInstance?.pinnedRevision || 0;
                            const pinnedItems = root.pluginApi?.mainInstance?.pinnedItems || [];
                            return pinnedItems.some(p => p.id === clipboardId);
                        }

                        onClicked: {
                            root.selectedIndex = index;
                            root.pluginApi?.mainInstance?.copyToClipboard(clipboardId);
                            if (root.pluginApi) {
                                root.pluginApi.closePanel(screen);
                                const autoPaste = root.pluginApi.pluginSettings?.autoPaste ?? false;
                                const rmbOnly = root.pluginApi.pluginSettings?.autoPasteOnRightClick ?? false;
                                if (autoPaste && !rmbOnly) {
                                    root.pluginApi.mainInstance?.triggerAutoPaste();
                                }
                            }
                        }

                        onRightClicked: {
                            root.selectedIndex = index;
                            const autoPaste = root.pluginApi?.pluginSettings?.autoPaste ?? false;
                            const rmbOnly = root.pluginApi?.pluginSettings?.autoPasteOnRightClick ?? false;
                            if (autoPaste && rmbOnly) {
                                root.pluginApi?.mainInstance?.copyToClipboard(clipboardId);
                                if (root.pluginApi) {
                                    root.pluginApi.closePanel(screen);
                                    root.pluginApi.mainInstance?.triggerAutoPaste();
                                }
                            }
                        }

                        onDeleteClicked: {
                            root.pluginApi?.mainInstance?.deleteById(clipboardId);
                        }

                        onPinClicked: {
                            if (isPinned) {
                                root.pluginApi?.mainInstance?.unpinItem(clipboardId);
                                ToastService.showNotice(pluginApi?.tr("toast.item-unpinned"));
                            } else {
                                const pinnedItems = root.pluginApi?.mainInstance?.pinnedItems || [];
                                if (pinnedItems.length >= 20) {
                                    ToastService.showWarning(pluginApi?.tr("toast.max-pinned-items").replace("{max}", "20"));
                                } else {
                                    root.pluginApi?.mainInstance?.pinItem(clipboardId);
                                    ToastService.showNotice(pluginApi?.tr("toast.item-pinned"));
                                }
                            }
                        }

                        onAddToTodoClicked: {
                            if (preview) {
                                // Direct call to Main.qml function (no internal IPC)
                                root.pluginApi?.mainInstance?.addTodoWithText(preview.substring(0, 200), 0);
                            }
                        }
                    }

                    NText {
                        anchors.centerIn: parent
                        visible: listView.count === 0
                        text: root.filterType || root.searchText ? pluginApi?.tr("panel.no-matches") : pluginApi?.tr("panel.empty")
                        color: (typeof Color !== "undefined") ? Color.mOnSurfaceVariant : "#AAAAAA"
                    }
                }
            }
        }  // End clipboardPanel

        // PINNED PANEL - Left side, vertical
        Rectangle {
            id: pinnedPanel
            visible: pluginApi?.pluginSettings?.pincardsEnabled ?? true
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: clipboardPanel.top
            anchors.bottomMargin: Style.marginM
            width: Math.min(300, screen?.width * 0.2 || 300)
            color: (typeof Color !== "undefined") ? Color.mSurface : "#222222"
            radius: Style.radiusM
            opacity: 1.0  // Override global panel opacity

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.marginL
                spacing: Style.marginM

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginM

                    NText {
                        text: pluginApi?.tr("panel.pinned-title")
                        font.bold: true
                        font.pointSize: Style.fontSizeL
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
                ListView {
                    id: pinnedListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Vertical
                    spacing: Style.marginS
                    clip: true

                    model: root.pluginApi?.mainInstance?.pinnedItems || []

                    delegate: ClipboardCard {
                        width: pinnedListView.width
                        height: Math.min(150, pinnedPanel.height * 0.25)
                        panelRoot: root
                        clipboardItem: {
                            return {
                                "id": modelData.id,
                                "preview": modelData.isImage ? "" : modelData.preview  // Don't show binary preview
                                ,
                                "mime": modelData.mime || "text/plain",
                                "isImage": modelData.isImage || false,
                                "content": modelData.content || ""  // For images, this is data URL
                            };
                        }
                        isPinned: true
                        pluginApi: root.pluginApi
                        screen: root.currentScreen
                        selected: false
                        pinnedImageDataUrl: modelData.isImage ? modelData.content : ""  // Pass data URL directly

                        onClicked: {
                            root.pluginApi?.mainInstance?.copyPinnedToClipboard(modelData.id);
                            if (root.pluginApi) {
                                root.pluginApi.closePanel(screen);
                                const autoPaste = root.pluginApi.pluginSettings?.autoPaste ?? false;
                                const rmbOnly = root.pluginApi.pluginSettings?.autoPasteOnRightClick ?? false;
                                if (autoPaste && !rmbOnly) {
                                    root.pluginApi.mainInstance?.triggerAutoPaste();
                                }
                            }
                        }

                        onRightClicked: {
                            const autoPaste = root.pluginApi?.pluginSettings?.autoPaste ?? false;
                            const rmbOnly = root.pluginApi?.pluginSettings?.autoPasteOnRightClick ?? false;
                            if (autoPaste && rmbOnly) {
                                root.pluginApi?.mainInstance?.copyPinnedToClipboard(modelData.id);
                                if (root.pluginApi) {
                                    root.pluginApi.closePanel(screen);
                                    root.pluginApi.mainInstance?.triggerAutoPaste();
                                }
                            }
                        }

                        onPinClicked: {
                            root.pluginApi?.mainInstance?.unpinItem(modelData.id);
                            ToastService.showNotice(pluginApi?.tr("toast.item-unpinned"));
                        }

                        onDeleteClicked: {
                            root.pluginApi?.mainInstance?.unpinItem(modelData.id);
                        }
                    }

                    NText {
                        anchors.centerIn: parent
                        visible: pinnedListView.count === 0
                        text: pluginApi?.tr("panel.no-pinned")
                        color: (typeof Color !== "undefined") ? Color.mOnSurfaceVariant : "#AAAAAA"
                    }
                }
            }
        }  // End pinnedPanel

        // Vertical separator between pinned and notecards
        Rectangle {
            visible: pinnedPanel.visible && noteCardsPanel.visible
            anchors.left: pinnedPanel.right
            anchors.top: parent.top
            anchors.bottom: clipboardPanel.top
            anchors.bottomMargin: Style.marginM
            width: 1
            color: "transparent"

            Column {
                anchors.centerIn: parent
                spacing: 10
                Repeater {
                    model: 27
                    Rectangle {
                        width: 2
                        height: 8
                        color: (typeof Color !== "undefined") ? Color.mOutline : "#555555"
                        opacity: 0.7
                    }
                }
            }
        }

        // NOTECARDS PANEL - Middle space (between pinned and clipboard)
        Item {
            id: noteCardsPanel
            visible: pluginApi?.pluginSettings?.notecardsEnabled ?? true
            anchors.left: pinnedPanel.visible ? pinnedPanel.right : parent.left
            anchors.leftMargin: pinnedPanel.visible ? Style.marginM : 0
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: clipboardPanel.top
            anchors.bottomMargin: Style.marginM

            NoteCardsPanel {
                id: notecardsPanelInstance
                anchors.fill: parent
                pluginApi: root.pluginApi
                screen: root.currentScreen
            }
        }  // End noteCardsPanel
    }  // End mainContainer

    Component.onCompleted: {
        selectedIndex = 0;
        filterType = "";
        searchText = "";
        pluginApi?.mainInstance?.list(screen?.width || 100);
        listView.forceActiveFocus();
        WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand;
    }
}
