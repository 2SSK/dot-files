pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history, newest first: text, images and files, as `desktop-clipboard watch` reports
// each copy. Text stays in memory and images in the runtime folder (RAM, gone at logout), so
// passwords and screenshots never reach the disk; a password manager's copies are left out.
// Pinned entries are kept in ~/.local/state/desktop/clipboard/ (a folder only you can read; a
// pinned image is copied there). Copying an entry back puts it on the clipboard as what it was:
// an image pastes as an image, files paste as attachments.
//
// An entry: { kind: "text" | "image" | "files", text, path, paths, time }
Singleton {
	id: root

	readonly property string folder: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/desktop/clipboard"
	property var history: []
	// pins from before images and files were kept are text, without a kind
	readonly property var pins: adapter.pins.map(p => p.kind ? p : Object.assign({ kind: "text" }, p))
	readonly property int maxImages: 30

	// what makes two entries the same
	function key(e: var): string {
		return e.kind === "image" ? "image:" + e.path.replace(/^.*\//, "") : e.kind === "files" ? "files:" + e.paths.join("\n") : "text:" + e.text;
	}

	function isPinned(e: var): bool {
		const k = key(e);
		return pins.some(p => key(p) === k);
	}

	function add(e: var): void {
		if (!e || !e.kind)
			return;
		const k = key(e);
		const next = [Object.assign({}, e, { time: Date.now() }), ...history.filter(h => key(h) !== k)].slice(0, 100);
		// only the newest images stay, their files too
		const images = next.filter(h => h.kind === "image");
		for (const old of images.slice(maxImages))
			forget(old);
		history = next.filter(h => h.kind !== "image" || images.indexOf(h) < maxImages);
	}

	// copy an entry back, as what it was (it comes back to the top through the watch)
	function copy(e: var): void {
		if (e.kind === "image")
			Quickshell.execDetached(["desktop-clipboard", "copy", "image", e.path]);
		else if (e.kind === "files")
			Quickshell.execDetached(["desktop-clipboard", "copy", "files", ...e.paths]);
		else
			Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | desktop-clipboard copy text', "sh", e.text]);
	}

	function pin(e: var): void {
		const k = key(e);
		if (isPinned(e)) {
			const gone = pins.find(p => key(p) === k);
			adapter.pins = pins.filter(p => key(p) !== k);
			if (gone?.kind === "image")
				Quickshell.execDetached(["rm", "-f", gone.path]);
		} else if (e.kind === "image") {
			// kept past logout: a copy in the pins folder
			const kept = root.folder + "/" + e.path.replace(/^.*\//, "");
			Quickshell.execDetached(["cp", "-n", e.path, kept]);
			adapter.pins = [{ kind: "image", path: kept, time: Date.now() }, ...pins];
		} else {
			adapter.pins = [Object.assign({}, e, { time: Date.now() }), ...pins];
		}
		file.writeAdapter();
	}

	function remove(e: var): void {
		const k = key(e);
		history = history.filter(h => key(h) !== k);
		forget(e);
		if (isPinned(e))
			pin(e);
	}

	function clear(): void {
		for (const h of history)
			forget(h);
		history = [];
	}

	// an image's file in the runtime folder goes with its entry (a pinned copy stays)
	function forget(e: var): void {
		if (e.kind === "image" && e.path.indexOf(root.folder) !== 0)
			Quickshell.execDetached(["rm", "-f", e.path]);
	}

	// every copy, as it happens
	Process {
		id: watcher

		running: true
		command: ["desktop-clipboard", "watch"]
		stdout: SplitParser {
			onRead: line => {
				try {
					root.add(JSON.parse(line));
				} catch (e) {}
			}
		}
		onExited: again.restart()
	}

	// the watch stopped (no display yet, a restart of X): start it again
	Timer {
		id: again

		interval: 2000
		onTriggered: watcher.running = true
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
