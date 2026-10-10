pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Clipboard history, newest first: text, images and files, as `desktop-clipboard watch` reports
// each copy. Like shell history it outlasts a reboot (Config.clipboard.persist): kept in
// ~/.local/state/desktop/clipboard/ (a folder only you can read), at most `max` entries, none older
// than `days`, the newest `images` pictures, a copy that's already there moving to the top. A
// password manager's copies are never kept. With persist off, text stays in memory and images in
// the runtime folder (RAM). Pinned entries are kept apart and never expire. Copying an entry back
// puts it on the clipboard as what it was: an image pastes as an image, files as attachments.
//
// An entry: { kind: "text" | "image" | "files", text, path, paths, time }
Singleton {
	id: root

	readonly property string folder: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/desktop/clipboard"
	property var history: []
	// pins from before images and files were kept are text, without a kind
	readonly property var pins: adapter.pins.map(p => p.kind ? p : Object.assign({ kind: "text" }, p))
	readonly property bool persist: Config.clipboard.persist
	readonly property int maxImages: Config.clipboard.images
	readonly property string images: folder + "/images" // kept pictures (pinned ones sit in folder)

	// what's kept: the newest `max`, none older than `days`
	function trim(list: var): var {
		const oldest = Date.now() - Config.clipboard.days * 86400000;
		return list.filter(h => h && h.kind && (h.time ?? 0) >= oldest).slice(0, Config.clipboard.max);
	}

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
		const next = trim([Object.assign({}, e, { time: Date.now() }), ...history.filter(h => key(h) !== k)]);
		// only the newest images stay, their files too
		const images = next.filter(h => h.kind === "image");
		for (const old of images.slice(maxImages))
			forget(old);
		history = next.filter(h => h.kind !== "image" || images.indexOf(h) < maxImages);
	}

	// the history kept on disk, a moment after it changes
	onHistoryChanged: if (persist && loaded) saveLater.restart()
	property bool loaded: false

	Timer {
		id: saveLater

		interval: 800
		onTriggered: {
			saved.entries = root.history;
			historyFile.writeAdapter();
		}
	}

	FileView {
		id: historyFile

		path: root.persist ? root.folder + "/history.json" : ""
		printErrors: false
		onLoaded: {
			root.history = root.trim(saved.entries);
			root.loaded = true;
		}
		onLoadFailed: root.loaded = true // none yet

		JsonAdapter {
			id: saved

			property var entries: []
		}
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

	// an image's file goes with its entry (a pinned copy, directly in the folder, stays)
	function forget(e: var): void {
		if (e.kind === "image" && (e.path.indexOf(root.images + "/") === 0 || e.path.indexOf(root.folder) !== 0))
			Quickshell.execDetached(["rm", "-f", e.path]);
	}

	// every copy, as it happens
	Process {
		id: watcher

		running: true
		command: ["desktop-clipboard", "watch"]
		environment: root.persist ? { DESKTOP_CLIPBOARD_IMAGES: root.images } : {}
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
		command: ["sh", "-c", 'mkdir -p "$1/images" && chmod 700 "$1" "$1/images"', "sh", root.folder]
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
