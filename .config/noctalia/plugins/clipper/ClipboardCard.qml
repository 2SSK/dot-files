import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Keyboard
import qs.Services.Noctalia
import qs.Services.UI
import qs.Widgets

Rectangle {
    id: root
    focus: true
    property var clipboardItem: null
    property var pluginApi: null
    property var screen: null
    property var panelRoot: null
    property string clipboardId: clipboardItem ? clipboardItem.id : ""
    property string mime: clipboardItem ? clipboardItem.mime : ""
    property string preview: clipboardItem ? clipboardItem.preview : ""
    property string pinnedImageDataUrl: ""  // For pinned images - data URL

    // Content type detection
    readonly property bool isImage: clipboardItem && clipboardItem.isImage
    readonly property bool isColor: {
        if (isImage || !preview) return false;
        const trimmed = preview.trim();
        return /^#[A-Fa-f0-9]{6}$/.test(trimmed) || /^#[A-Fa-f0-9]{3}$/.test(trimmed) || /^[A-Fa-f0-9]{6}$/.test(trimmed) || /^rgba?\(.*\)$/i.test(trimmed);
    }
    readonly property bool isLink: !isImage && !isColor && preview && /^https?:\/\//.test(preview.trim())
    readonly property bool isCode: !isImage && !isColor && !isLink && preview && (preview.includes("function") || preview.includes("import ") || preview.includes("const ") || preview.includes("let ") || preview.includes("var ") || preview.includes("class ") || preview.includes("def ") || preview.includes("return ") || /^[\{\[\(<]/.test(preview.trim()))
    readonly property bool isEmoji: {
        if (isImage || isColor || isLink || isCode || !preview) return false;
        const trimmed = preview.trim();
        return trimmed.length <= 4 && trimmed.charCodeAt(0) > 255;
    }
    readonly property bool isFile: !isImage && !isColor && !isLink && !isCode && !isEmoji && preview && /^(\/|~|file:\/\/)/.test(preview.trim())
    readonly property bool isText: !isImage && !isColor && !isLink && !isCode && !isEmoji && !isFile

    // Helper to safely access Color singleton
    function getColor(propName, fallback) {
        if (typeof Color !== "undefined" && Color[propName]) return Color[propName];
        return fallback;
    }

    readonly property string colorValue: {
        if (!isColor || !preview) return "";
        const trimmed = preview.trim();
        if (/^#[A-Fa-f0-9]{3,6}$/.test(trimmed)) return trimmed;
        if (/^[A-Fa-f0-9]{6}$/.test(trimmed)) return "#" + trimmed;
        return trimmed;
    }

    readonly property string typeLabel: isImage ? "Image" : isColor ? "Color" : isLink ? "Link" : isCode ? "Code" : isEmoji ? "Emoji" : isFile ? "File" : "Text"
    readonly property string typeIcon: isImage ? "photo" : isColor ? "palette" : isLink ? "link" : isCode ? "code" : isEmoji ? "mood-smile" : isFile ? "file" : "align-left"

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

    // Get color setting for current card type
    function getCardColorSetting(colorType) {
        const settings = pluginApi?.pluginSettings?.cardColors;
        const customColors = pluginApi?.pluginSettings?.customColors;
        const cardType = typeLabel;

        if (settings && settings[cardType] && settings[cardType][colorType]) {
            const colorKey = settings[cardType][colorType];
            if (colorKey === "custom" && customColors && customColors[cardType]) {
                return customColors[cardType][colorType] || "#888888";
            }
            return getColor(colorKey, defaultCardColors[cardType]?.[colorType] || "#888888");
        }

        // Fallback to default
        const defaultKey = defaultCardColors[cardType]?.[colorType];
        return getColor(defaultKey, "#888888");
    }

    // Colors from settings or defaults
    readonly property color accentColor: getCardColorSetting("bg")
    readonly property color accentFgColor: getCardColorSetting("fg")
    readonly property color separatorColor: getCardColorSetting("separator")

    signal clicked
    signal deleteClicked
    signal addToTodoClicked
    signal pinClicked
    property bool selected: false
    property bool enableTodoIntegration: false
    property bool isPinned: false

    width: 250
    height: parent.height

    // Get ToDo pages from plugin
    function getTodoPages() {
        const todoApi = PluginService.getPluginAPI("todo");
        if (!todoApi || !todoApi.pluginSettings || !todoApi.pluginSettings.pages) {
            return [{ id: 0, name: "General" }];
        }
        return todoApi.pluginSettings.pages;
    }

    // Build menu model from ToDo pages
    function buildTodoMenuModel() {
        const pages = getTodoPages();
        const model = [];
        for (let i = 0; i < pages.length; i++) {
            model.push({
                "label": pages[i].name,
                "action": "page-" + pages[i].id,
                "icon": "checkbox"
            });
        }
        return model;
    }

    // Anchor point for context menu positioning
    Item {
        id: menuAnchor
        width: 0
        height: 0
        visible: false
    }

    // Context menu for ToDo page selection
    NPopupContextMenu {
        id: todoContextMenu
        screen: root.screen
        anchorItem: menuAnchor

        onTriggered: action => {
            todoContextMenu.visible = false;

            if (action.startsWith("page-")) {
                const pageId = parseInt(action.replace("page-", ""));
                if (root.preview) {
                    root.pluginApi?.mainInstance?.addTodoWithText(root.preview.substring(0, 200), pageId);
                }
            }
        }

        onVisibleChanged: {
            if (!visible) {
                // Cleanup when menu closes
                root.focus = true;
                if (root.panelRoot && root.panelRoot.activeContextMenu === todoContextMenu) {
                    root.panelRoot.activeContextMenu = null;
                }
            }
        }
    }

    // Click outside to close menu
    MouseArea {
        anchors.fill: parent
        enabled: todoContextMenu.visible
        z: todoContextMenu.visible ? 999 : -1
        onClicked: {
            todoContextMenu.visible = false;
        }
    }

    // Body background - Same as accent color
    color: selected ? Qt.darker(accentColor, 1.1) : (mouseArea.containsMouse ? Qt.lighter(accentColor, 1.1) : accentColor)

    radius: (typeof Style !== "undefined") ? Style.radiusM : 16
    border.width: 2
    border.color: accentColor // Border same as background

    // Visual indicator for pinned status (small icon in corner)
    NIcon {
        visible: root.isPinned
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4
        z: 100
        icon: "pin-filled"
        pointSize: 10
        color: root.accentFgColor
        opacity: 0.6
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: headerBar
            Layout.fillWidth: true
            Layout.preferredHeight: 35
            color: root.accentColor // Header same as background
            topLeftRadius: (typeof Style !== "undefined") ? Style.radiusM : 16
            topRightRadius: (typeof Style !== "undefined") ? Style.radiusM : 16
            bottomLeftRadius: 0
            bottomRightRadius: 0


            RowLayout {
                id: headerContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 8
                spacing: 8
                NIcon { icon: root.typeIcon; pointSize: 13; color: root.accentFgColor }
                NText { text: root.typeLabel; color: root.accentFgColor; font.bold: true }
                Item { Layout.fillWidth: true }
                NIconButton {
                    id: todoButton
                    visible: root.enableTodoIntegration && !root.isImage
                    icon: "checkbox"
                    tooltipText: pluginApi?.tr("card.add-todo") || "Add to ToDo"
                    colorFg: root.accentFgColor
                    colorBg: "transparent"
                    colorBgHover: Qt.rgba(0,0,0,0.1)
                    colorBorder: "transparent"
                    colorBorderHover: "transparent"
                    onClicked: {
                        // Close any previously open menu
                        if (root.panelRoot && root.panelRoot.activeContextMenu) {
                            root.panelRoot.activeContextMenu.visible = false;
                        }

                        // Position anchor at button location
                        const pos = todoButton.mapToItem(root, 0, todoButton.height);
                        menuAnchor.x = pos.x;
                        menuAnchor.y = pos.y;

                        // Show menu and register it as active
                        todoContextMenu.model = root.buildTodoMenuModel();
                        todoContextMenu.visible = true;
                        if (root.panelRoot) {
                            root.panelRoot.activeContextMenu = todoContextMenu;
                        }
                    }
                }
                NIconButton {
                    visible: !root.isPinned && (pluginApi?.pluginSettings?.pincardsEnabled ?? true)  // Hide pin button if pinned or if feature disabled
                    icon: "pin"
                    tooltipText: pluginApi?.tr("card.pin") || "Pin"
                    colorFg: root.accentFgColor
                    colorBg: "transparent"
                    colorBgHover: Qt.rgba(0,0,0,0.1)
                    colorBorder: "transparent"
                    colorBorderHover: "transparent"
                    onClicked: root.pinClicked()
                }
                NIconButton {
                    icon: "trash"
                    tooltipText: pluginApi?.tr("card.delete") || "Delete"
                    colorFg: root.accentFgColor
                    colorBg: "transparent"
                    colorBgHover: Qt.rgba(0,0,0,0.1)
                    colorBorder: "transparent"
                    colorBorderHover: "transparent"
                    onClicked: root.deleteClicked()
                }
            }
            MouseArea { anchors.fill: parent; z: -1; onClicked: root.clicked() }
        }

        Rectangle {
            width: parent.width - 10
            Layout.alignment: Qt.AlignHCenter
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: root.separatorColor }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 8
            clip: true
            MouseArea { id: mouseArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }

            Rectangle {
                visible: root.isColor
                anchors.fill: parent
                radius: 8
                color: root.colorValue || "transparent"
                border.width: 1
                border.color: root.accentFgColor // Use FG color for border contrast
            }

            NText {
                visible: !root.isColor && !root.isImage
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                text: root.preview || ""
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                color: root.accentFgColor
                font.pointSize: 11
                verticalAlignment: Text.AlignTop
            }

            NImageRounded {
                visible: root.isImage
                anchors.fill: parent
                radius: 8
                imageFillMode: Image.PreserveAspectFit
                imagePath: {
                    // For pinned images, use data URL directly
                    if (root.pinnedImageDataUrl) {
                        return root.pinnedImageDataUrl;
                    }
                    // For cliphist images, use cache (reactive binding via imageCacheRevision)
                    if (root.isImage && root.pluginApi?.mainInstance) {
                        // Force re-evaluation when cache changes by referencing revision
                        const revision = root.pluginApi.mainInstance.imageCacheRevision;
                        const cache = root.pluginApi.mainInstance.imageCache;
                        return cache[root.clipboardId] || "";
                    }
                    return "";
                }
                Component.onCompleted: {
                    // Only decode if not pinned (pinned images have data URL already)
                    if (!root.pinnedImageDataUrl && root.isImage && root.clipboardId && root.pluginApi?.mainInstance) {
                        root.pluginApi.mainInstance.decodeToDataUrl(root.clipboardId, root.mime, null);
                    }
                }
            }
        }
    }
    Component.onDestruction: {
        if (todoContextMenu && todoContextMenu.visible) {
            todoContextMenu.visible = false;
        }
    }
}
