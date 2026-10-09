pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Todo items, kept on this machine in ~/.local/share/desktop/todo.json: { id, text, done, priority }
// with priority high, medium or low. `sorted` puts open ones first, by priority, then done ones.
Singleton {
	id: root

	readonly property var order: ({ high: 0, medium: 1, low: 2 })
	// older items may lack an id or a priority
	readonly property var items: adapter.items.map((item, i) => ({ id: item.id ?? `old-${i}`, text: item.text, done: !!item.done, priority: item.priority ?? "medium" }))
	readonly property var sorted: [...items].sort((a, b) => (a.done - b.done) || (order[a.priority] - order[b.priority]))
	readonly property int open: items.filter(item => !item.done).length

	function add(text: string, priority: string): void {
		if (text.trim())
			save([...items, { id: `${Date.now()}-${Math.floor(Math.random() * 1e6)}`, text: text.trim(), done: false, priority }]);
	}

	function update(id: string, change: var): void {
		save(items.map(item => item.id === id ? Object.assign({}, item, change) : item));
	}

	function toggle(id: string): void {
		const item = items.find(i => i.id === id);
		if (item)
			update(id, { done: !item.done });
	}

	// high → medium → low → high
	function cyclePriority(id: string): void {
		const item = items.find(i => i.id === id);
		if (item)
			update(id, { priority: ({ high: "medium", medium: "low", low: "high" })[item.priority] });
	}

	function remove(id: string): void {
		save(items.filter(item => item.id !== id));
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
