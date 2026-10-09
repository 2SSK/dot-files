pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Todo items, kept on this machine in ~/.local/share/desktop/todo.json.
Singleton {
	id: root

	readonly property var items: adapter.items // [{ text, done }]

	function add(text: string): void {
		if (text.trim())
			save([...items, { text: text.trim(), done: false }]);
	}

	function toggle(index: int): void {
		save(items.map((item, i) => i === index ? { text: item.text, done: !item.done } : item));
	}

	function remove(index: int): void {
		save(items.filter((_, i) => i !== index));
	}

	function clearDone(): void {
		save(items.filter(item => !item.done));
	}

	function save(list: var): void {
		adapter.items = list;
		file.writeAdapter();
	}

	FileView {
		id: file

		path: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/desktop/todo.json"
		watchChanges: true
		onFileChanged: reload()
		printErrors: false

		JsonAdapter {
			id: adapter

			property var items: []
		}
	}
}
