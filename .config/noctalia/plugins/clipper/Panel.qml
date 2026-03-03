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
    readonly property bool allowAttach: false

    // Panel dimensions - fullscreen transparent container
    property int contentPreferredHeight: screen?.height || 0
    property int contentPreferredWidth: screen?.width || 0

    // Panel positioning - cover full screen
    property bool panelAnchorBottom: true
    property bool panelAnchorTop: true
    property bool panelAnchorLeft: true
    property bool panelAnchorRight: true
    property bool panelAnchorHorizontalCenter: false
    property bool panelAnchorVerticalCenter: false

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

    Keys.onDigit1Pressed: filterType = "Text"
    Keys.onDigit2Pressed: filterType = "Image"
    Keys.onDigit3Pressed: filterType = "Color"
    Keys.onDigit4Pressed: filterType = "Link"
    Keys.onDigit5Pressed: filterType = "Code"
    Keys.onDigit6Pressed: filterType = "Emoji"
    Keys.onDigit7Pressed: filterType = "File"
    Keys.onDigit0Pressed: filterType = ""

    // Main container - transparent fullscreen
    Item {
        id: mainContainer
        anchors.fill: parent

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
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.radius
                color: parent.color
            }

            ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NText {
                    text: pluginApi?.tr("panel.title") || "Clipboard History"
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
                    tooltipText: pluginApi?.tr("panel.settings") || "Settings"
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

                NIconButton {
                    visible: pluginApi?.mainInstance?.showCloseButton ?? false
                    icon: "x"
                    tooltipText: pluginApi?.tr("panel.close") || "Close"
                    Layout.alignment: Qt.AlignVCenter
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

                NTextInput {
                    id: searchInput
                    Layout.preferredWidth: 250
                    Layout.alignment: Qt.AlignVCenter
                    placeholderText: pluginApi?.tr("panel.search-placeholder") || "Search..."
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
                                [Qt.Key_0]: "",
                                [Qt.Key_1]: "Text",
                                [Qt.Key_2]: "Image",
                                [Qt.Key_3]: "Color",
                                [Qt.Key_4]: "Link",
                                [Qt.Key_5]: "Code",
                                [Qt.Key_6]: "Emoji",
                                [Qt.Key_7]: "File"
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

                RowLayout {
                    spacing: Style.marginXS
                    Layout.alignment: Qt.AlignVCenter

                    NIconButton {
                        focus: true
                        icon: "apps"
                        tooltipText: pluginApi?.tr("panel.filter-all") || "All"
                        colorBg: (typeof Color !== "undefined") ? (root.filterType === "" ? Color.mPrimary : Color.mSurfaceVariant) : "#444444"
                        colorBgHover: (typeof Color !== "undefined") ? (root.filterType === "" ? Color.mPrimary : Color.mHover) : "#666666"
                        colorFg: (typeof Color !== "undefined") ? (root.filterType === "" ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                        colorFgHover: (typeof Color !== "undefined") ? (root.filterType === "" ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                        onClicked: root.filterType = ""

                        Keys.onTabPressed: {
                            root.filterType = "";
                            event.accepted = true;
                        }
                    }

                    NIconButton {
                        focus: true
                        icon: "align-left"
                        tooltipText: pluginApi?.tr("panel.filter-text") || "Text"
                        colorBg: (typeof Color !== "undefined") ? (root.filterType === "Text" ? Color.mPrimary : Color.mSurfaceVariant) : "#444444"
                        colorBgHover: (typeof Color !== "undefined") ? (root.filterType === "Text" ? Color.mPrimary : Color.mHover) : "#666666"
                        colorFg: (typeof Color !== "undefined") ? (root.filterType === "Text" ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                        colorFgHover: (typeof Color !== "undefined") ? (root.filterType === "Text" ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                        onClicked: root.filterType = "Text"

                        Keys.onTabPressed: {
                            root.filterType = "Image";
                            event.accepted = true;
                        }
                    }

                    NIconButton {
                        focus: true
                        icon: "photo"
                        tooltipText: pluginApi?.tr("panel.filter-images") || "Images"
                        colorBg: (typeof Color !== "undefined") ? (root.filterType === "Image" ? Color.mTertiary : Color.mSurfaceVariant) : "#444444"
                        colorBgHover: (typeof Color !== "undefined") ? (root.filterType === "Image" ? Color.mTertiary : Color.mHover) : "#666666"
                        colorFg: (typeof Color !== "undefined") ? (root.filterType === "Image" ? Color.mOnTertiary : Color.mOnSurface) : "#FFFFFF"
                        colorFgHover: (typeof Color !== "undefined") ? (root.filterType === "Image" ? Color.mOnTertiary : Color.mOnSurface) : "#FFFFFF"
                        onClicked: root.filterType = "Image"
                    }

                    NIconButton {
                        focus: true
                        icon: "palette"
                        tooltipText: pluginApi?.tr("panel.filter-colors") || "Colors"
                        colorBg: (typeof Color !== "undefined") ? (root.filterType === "Color" ? Color.mSecondary : Color.mSurfaceVariant) : "#444444"
                        colorBgHover: (typeof Color !== "undefined") ? (root.filterType === "Color" ? Color.mSecondary : Color.mHover) : "#666666"
                        colorFg: (typeof Color !== "undefined") ? (root.filterType === "Color" ? Color.mOnSecondary : Color.mOnSurface) : "#FFFFFF"
                        colorFgHover: (typeof Color !== "undefined") ? (root.filterType === "Color" ? Color.mOnSecondary : Color.mOnSurface) : "#FFFFFF"
                        onClicked: root.filterType = "Color"
                    }

                    NIconButton {
                        focus: true
                        icon: "link"
                        tooltipText: pluginApi?.tr("panel.filter-links") || "Links"
                        colorBg: (typeof Color !== "undefined") ? (root.filterType === "Link" ? Color.mPrimary : Color.mSurfaceVariant) : "#444444"
                        colorBgHover: (typeof Color !== "undefined") ? (root.filterType === "Link" ? Color.mPrimary : Color.mHover) : "#666666"
                        colorFg: (typeof Color !== "undefined") ? (root.filterType === "Link" ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                        colorFgHover: (typeof Color !== "undefined") ? (root.filterType === "Link" ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                        onClicked: root.filterType = "Link"
                    }

                    NIconButton {
                        focus: true
                        icon: "code"
                        tooltipText: pluginApi?.tr("panel.filter-code") || "Code"
                        colorBg: (typeof Color !== "undefined") ? (root.filterType === "Code" ? Color.mSecondary : Color.mSurfaceVariant) : "#444444"
                        colorBgHover: (typeof Color !== "undefined") ? (root.filterType === "Code" ? Color.mSecondary : Color.mHover) : "#666666"
                        colorFg: (typeof Color !== "undefined") ? (root.filterType === "Code" ? Color.mOnSecondary : Color.mOnSurface) : "#FFFFFF"
                        colorFgHover: (typeof Color !== "undefined") ? (root.filterType === "Code" ? Color.mOnSecondary : Color.mOnSurface) : "#FFFFFF"
                        onClicked: root.filterType = "Code"
                    }

                    NIconButton {
                        focus: true
                        icon: "mood-smile"
                        tooltipText: pluginApi?.tr("panel.filter-emoji") || "Emoji"
                        colorBg: (typeof Color !== "undefined") ? (root.filterType === "Emoji" ? Color.mPrimary : Color.mSurfaceVariant) : "#444444"
                        colorBgHover: (typeof Color !== "undefined") ? (root.filterType === "Emoji" ? Color.mPrimary : Color.mHover) : "#666666"
                        colorFg: (typeof Color !== "undefined") ? (root.filterType === "Emoji" ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                        colorFgHover: (typeof Color !== "undefined") ? (root.filterType === "Emoji" ? Color.mOnPrimary : Color.mOnSurface) : "#FFFFFF"
                        onClicked: root.filterType = "Emoji"
                    }

                    NIconButton {
                        focus: true
                        icon: "file"
                        tooltipText: pluginApi?.tr("panel.filter-files") || "Files"
                        colorBg: (typeof Color !== "undefined") ? (root.filterType === "File" ? Color.mTertiary : Color.mSurfaceVariant) : "#444444"
                        colorBgHover: (typeof Color !== "undefined") ? (root.filterType === "File" ? Color.mTertiary : Color.mHover) : "#666666"
                        colorFg: (typeof Color !== "undefined") ? (root.filterType === "File" ? Color.mOnTertiary : Color.mOnSurface) : "#FFFFFF"
                        colorFgHover: (typeof Color !== "undefined") ? (root.filterType === "File" ? Color.mOnTertiary : Color.mOnSurface) : "#FFFFFF"
                        onClicked: root.filterType = "File"
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
                    text: pluginApi?.tr("panel.clear-all") || "Clear All"
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
                            [Qt.Key_0]: "",
                            [Qt.Key_1]: "Text",
                            [Qt.Key_2]: "Image",
                            [Qt.Key_3]: "Color",
                            [Qt.Key_4]: "Link",
                            [Qt.Key_5]: "Code",
                            [Qt.Key_6]: "Emoji",
                            [Qt.Key_7]: "File"
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
                        }
                    }

                    onDeleteClicked: {
                        root.pluginApi?.mainInstance?.deleteById(clipboardId);
                    }

                    onPinClicked: {
                        if (isPinned) {
                            root.pluginApi?.mainInstance?.unpinItem(clipboardId);
                            ToastService.showNotice(pluginApi?.tr("toast.item-unpinned") || "Item unpinned");
                        } else {
                            const pinnedItems = root.pluginApi?.mainInstance?.pinnedItems || [];
                            if (pinnedItems.length >= 20) {
                                ToastService.showWarning((pluginApi?.tr("toast.max-pinned-items") || "Maximum {max} pinned items reached").replace("{max}", "20"));
                            } else {
                                root.pluginApi?.mainInstance?.pinItem(clipboardId);
                                ToastService.showNotice(pluginApi?.tr("toast.item-pinned") || "Item pinned");
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
                    text: root.filterType || root.searchText ? (pluginApi?.tr("panel.no-matches") || "No matching items") : (pluginApi?.tr("panel.empty") || "Clipboard is empty")
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
                        text: pluginApi?.tr("panel.pinned-title") || "Pinned Items"
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
                                "preview": modelData.isImage ? "" : modelData.preview,  // Don't show binary preview
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
                            }
                        }

                        onPinClicked: {
                            root.pluginApi?.mainInstance?.unpinItem(modelData.id);
                            ToastService.showNotice(pluginApi?.tr("toast.item-unpinned") || "Item unpinned");
                        }

                        onDeleteClicked: {
                            root.pluginApi?.mainInstance?.unpinItem(modelData.id);
                        }
                    }

                    NText {
                        anchors.centerIn: parent
                        visible: pinnedListView.count === 0
                        text: pluginApi?.tr("panel.no-pinned") || "No pinned items"
                        color: (typeof Color !== "undefined") ? Color.mOnSurfaceVariant : "#AAAAAA"
                    }
                }
            }
        }  // End pinnedPanel

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
