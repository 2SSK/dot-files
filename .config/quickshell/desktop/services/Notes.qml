pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Notes, kept on this machine in ~/.local/share/desktop/notes/notes.json, in a folder only you can
// read (they may hold connection strings and the like; each save writes a fresh file, so the folder
// keeps them private rather than the file's mode). A note: { id, title, type, tag, pinned, body, items, updated }
// with type text, checklist or code; a checklist keeps [{ text, done }] in items.
Singleton {
	id: root

	readonly property string folder: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/desktop"
	readonly property var notes: adapter.notes
	// pinned first, then the most recently changed
	readonly property var sorted: [...notes].sort((a, b) => (!!b.pinned - !!a.pinned) || (b.updated - a.updated))
	property string selected: ""
	readonly property var current: notes.find(n => n.id === selected) ?? null

	function create(type: string, body: string, title: string): string {
		const id = `${Date.now()}-${Math.floor(Math.random() * 1e6)}`;
		adapter.notes = [...notes, { id, title: title ?? "", type, tag: "none", pinned: false, body: body ?? "", items: [], updated: Date.now() }];
		selected = id;
		save();
		return id;
	}

	// a clipboard snippet becomes a code note named after its first line
	function addSnippet(text: string): string {
		const first = text.trim().split("\n")[0];
		return create("code", text, first.length > 48 ? first.slice(0, 48) + "…" : first);
	}

	// what a note can be, its colour tags, and how the list names one (NotesPage, NoteEditor)
	readonly property var types: [
		{ key: "text", glyph: Icons.g("note"), label: "Text" },
		{ key: "checklist", glyph: Icons.g("checkbox"), label: "Checklist" },
		{ key: "code", glyph: Icons.g("code"), label: "Code" }
	]
	readonly property var tags: ({ none: Theme.fgMuted, red: Theme.error, yellow: Theme.warning, green: Theme.success, blue: Theme.primary, purple: Theme.secondary })

	function glyph(type: string): string {
		return types.find(t => t.key === type)?.glyph ?? types[0].glyph;
	}

	function heading(note: var): string {
		return note.title || (note.type === "checklist" ? (note.items?.[0]?.text ?? "") : note.body.trim().split("\n")[0]) || "Untitled";
	}

	function update(id: string, change: var): void {
		adapter.notes = notes.map(n => n.id === id ? Object.assign({}, n, change, { updated: Date.now() }) : n);
		save();
	}

	function remove(id: string): void {
		adapter.notes = notes.filter(n => n.id !== id);
		if (selected === id)
			selected = sorted[0]?.id ?? "";
		save();
	}

	function save(): void {
		saveTimer.restart();
	}

	Timer {
		id: saveTimer

		interval: 500
		onTriggered: file.writeAdapter()
	}

	FileView {
		id: file

		path: root.folder + "/notes/notes.json"
		blockLoading: true
		printErrors: false

		JsonAdapter {
			id: adapter

			property var notes: []
		}
	}

	// the private folder, before anything is written
	Process {
		running: true
		command: ["sh", "-c", 'mkdir -p "$1" && chmod 700 "$1"', "sh", root.folder + "/notes"]
	}

	Component.onCompleted: selected = sorted[0]?.id ?? ""
}
