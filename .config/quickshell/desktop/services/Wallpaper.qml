pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// The wallpaper: the images in wallpaper.folders, the one set, and rotation. Setting one points
// ~/.local/state/desktop/wallpaper at it, which the lock screen and sddm read too.
Singleton {
	id: root

	readonly property string home: Quickshell.env("HOME")
	readonly property string state: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/desktop"
	readonly property var folders: (Config.wallpaper.folders ?? []).map(f => f.replace(/^~/, home))
	readonly property int every: ({ "5m": 300, "1h": 3600, "1d": 86400 })[Config.wallpaper.rotate] ?? 0 // s
	property var files: []
	// theme folders such as ~/Wallpaper-Bank/tokyonight match the theme's family
	readonly property string family: Theme.palette.meta?.family ?? ""
	readonly property var themeFiles: files.filter(f => f.split("/").slice(-2, -1)[0] === family)
	property string current: ""
	property real changed: 0 // when it last changed (ms)
	property string pending: "" // picked while the last one was still fading in

	function set(path: string): void {
		if (!path || path === current)
			return;
		current = path;
		changed = Date.now();
		if (apply.running) {
			pending = path;
			return;
		}
		apply.command = ["desktop-wallpaper", "set", path];
		apply.running = true;
	}

	function shuffle(): void {
		const pool = themeFiles.length > 1 ? themeFiles : files;
		const others = pool.filter(f => f !== current);
		if (others.length)
			set(others[Math.floor(Math.random() * others.length)]);
	}

	function scan(): void {
		list.running = true;
	}

	onFoldersChanged: scan()

	Process {
		id: apply

		onExited: {
			const next = root.pending;
			root.pending = "";
			if (next && next !== apply.command[2]) {
				apply.command = ["desktop-wallpaper", "set", next];
				apply.running = true;
			}
		}
	}

	Process {
		id: list

		command: ["sh", "-c", 'for d in "$@"; do [ -d "$d" ] && find -L "$d" -maxdepth 2 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \\); done | sort', "sh", ...root.folders]
		stdout: StdioCollector {
			onStreamFinished: root.files = text.split("\n").filter(f => f)
		}
	}

	// changes made elsewhere (a terminal, the shutdown pick) show up through wallpaper-changed
	Process {
		id: look

		running: true
		command: ["sh", "-c", 'readlink "$1/wallpaper"; cat "$1/wallpaper-changed" 2>/dev/null || echo 0', "sh", root.state]
		stdout: StdioCollector {
			onStreamFinished: {
				const [current, changed] = text.split("\n");
				root.current = current ?? "";
				root.changed = Number(changed) * 1000;
			}
		}
	}

	FileView {
		path: root.state + "/wallpaper-changed"
		watchChanges: true
		printErrors: false
		onFileChanged: look.running = true
	}

	Timer {
		interval: 60000
		running: root.every > 0
		repeat: true
		onTriggered: if (Date.now() - root.changed >= root.every * 1000) root.shuffle()
	}

	Component.onCompleted: scan()
}
