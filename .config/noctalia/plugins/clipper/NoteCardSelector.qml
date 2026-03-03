import QtQuick
import Quickshell

// Note card selector wrapper - prepares menu items and handles selection
QtObject {
    id: root

    property var pluginApi: null
    property string selectedText: ""
    property var noteCards: []
    property var selectionMenu: null

    signal noteSelected(string noteId, string noteTitle)
    signal createNewNote()

    function buildMenuModel() {
        const model = [];

        // First option: Create new note
        model.push({
            "label": pluginApi?.tr("notecards.create-note") || "Create New Note",
            "action": "create-new",
            "icon": "add"
        });

        // Add existing notes
        for (let i = 0; i < noteCards.length; i++) {
            const note = noteCards[i];
            model.push({
                "label": note.title || (pluginApi?.tr("notecards.untitled-placeholder") || "Untitled"),
                "action": "note-" + note.id,
                "icon": "note",
                "noteId": note.id
            });
        }

        return model;
    }

    function show(text, notes) {
        selectedText = text || "";
        noteCards = notes || [];

        if (selectionMenu) {
            const menuItems = buildMenuModel();
            selectionMenu.show(menuItems);
        }
    }

    function handleItemSelected(action) {
        if (action === "create-new") {
            root.createNewNote();
        } else if (action.startsWith("note-")) {
            const noteId = action.replace("note-", "");
            const note = noteCards.find(n => n.id === noteId);
            root.noteSelected(noteId, note ? note.title : (pluginApi?.tr("notecards.untitled-placeholder") || "Untitled"));
        }
    }
}
