pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// The wallpaper: the images in wallpaper.folders (shell.json; a folder each deep: theme folders
// such as ~/Wallpaper-Bank/tokyonight are matched to the theme), the one set, and rotation
// (wallpaper.rotate: off, 5m, 1h, 1d, or boot for a new one each boot; that one is picked while
// the system shuts down, by desktop-wallpaper next-boot, so the login screen has it). Setting one points
// ~/.local/state/desktop/wallpaper at it (the lock screen and sddm read that too); the backdrop
// (sway) or desktop-wallpaper's feh (i3) fades over to it. A change made elsewhere (desktop-wallpaper
// in a terminal, the shutdown pick) is seen through wallpaper-changed. The last change is
// remembered, so a rotation keeps its pace across restarts.
Singleton {
	id: root

	readonly property string home: Quickshell.env("HOME")
	readonly property string state: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/desktop"
	readonly property var folders: (Config.wallpaper.folders ?? []).map(f => f.replace(/^~/, home))
	readonly property int every: ({ "5m": 300, "1h": 3600, "1d": 86400 })[Config.wallpaper.rotate] ?? 0 // s
	property var files: []
	// the ones in a folder named after the current theme (~/Wallpaper-Bank/tokyonight/...)
	readonly property string family: Theme.palette.meta?.family ?? ""
	readonly property var themeFiles: files.filter(f => f.split("/").slice(-2, -1)[0] === family)
	property string current: ""
	property real changed: 0 // when it last changed (ms)
	property string pending: "" // picked while the last one was still fading in

	// one at a time: a pick made while the last one still fades in follows it
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

	// a different one, at random: from the current theme's folder when it has some
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

	// where things stand: the image set, and when it changed (again whenever it changes)
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

	// rotation, checked every minute against the last change
	Timer {
		interval: 60000
		running: root.every > 0
		repeat: true
		onTriggered: if (Date.now() - root.changed >= root.every * 1000) root.shuffle()
	}

	Component.onCompleted: scan()
}
