import QtQuick
import Quickshell

// Todo page selector wrapper - prepares menu items and handles selection
QtObject {
    id: root

    property var pluginApi: null
    property string selectedText: ""
    property var todoPages: []
    property var selectionMenu: null

    signal pageSelected(int pageId, string pageName)

    function buildMenuModel() {
        const model = [];

        // Add existing todo pages only
        for (let i = 0; i < todoPages.length; i++) {
            const page = todoPages[i];
            model.push({
                "label": page.name || (pluginApi?.tr("notecards.untitled-placeholder") || "Untitled"),
                "action": "page-" + page.id,
                "icon": "list",
                "pageId": page.id
            });
        }

        return model;
    }

    function show(text, pages) {
        selectedText = text || "";
        todoPages = pages || [];

        if (selectionMenu) {
            const menuItems = buildMenuModel();
            selectionMenu.show(menuItems);
        } else {
        }
    }

    function handleItemSelected(action) {
        if (action.startsWith("page-")) {
            const pageId = parseInt(action.replace("page-", ""));
            const page = todoPages.find(p => p.id === pageId);
            root.pageSelected(pageId, page ? page.name : (pluginApi?.tr("notecards.untitled-placeholder") || "Untitled"));
        }
    }
}
