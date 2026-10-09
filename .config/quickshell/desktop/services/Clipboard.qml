pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history: what's copied (text), newest first, kept in memory only, so passwords and
// tokens never reach the disk. Pinned items are kept, in ~/.local/state/desktop/clipboard/ (a
// folder only you can read).
Singleton {
	id: root

	readonly property string folder: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/desktop/clipboard"
	property var history: [] // [{ text, time }]
	readonly property var pins: adapter.pins // [{ text, time }]

	function isPinned(text: string): bool {
		return pins.some(p => p.text === text);
	}

	function add(text: string): void {
		if (!text || !text.trim())
			return;
		history = [{ text, time: Date.now() }, ...history.filter(h => h.text !== text)].slice(0, 100);
	}

	// copy an item back (it moves to the top)
	function copy(text: string): void {
		Quickshell.clipboardText = text;
	}

	function pin(text: string): void {
		adapter.pins = isPinned(text) ? pins.filter(p => p.text !== text) : [{ text, time: Date.now() }, ...pins];
		file.writeAdapter();
	}

	function remove(text: string): void {
		history = history.filter(h => h.text !== text);
		if (isPinned(text))
			pin(text);
	}

	function clear(): void {
		history = [];
	}

	// X11: Qt hears every change. Wayland only tells the focused app, so wl-paste watches instead:
	// each copy's text, ended by a record separator
	Connections {
		target: Quickshell
		enabled: !Quickshell.env("WAYLAND_DISPLAY")

		function onClipboardTextChanged(): void {
			root.add(Quickshell.clipboardText);
		}
	}

	Process {
		running: !!Quickshell.env("WAYLAND_DISPLAY")
		command: ["wl-paste", "--type", "text", "--watch", "sh", "-c", "cat; printf '\\036'"]
		stdout: SplitParser {
			splitMarker: "\u001e"
			onRead: text => root.add(text)
		}
	}

	Process {
		running: true
		command: ["sh", "-c", 'mkdir -p "$1" && chmod 700 "$1"', "sh", root.folder]
	}

	FileView {
		id: file

		path: root.folder + "/pins.json"
		printErrors: false

		JsonAdapter {
			id: adapter

			property var pins: []
		}
	}
}
