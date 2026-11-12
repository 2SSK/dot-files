pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// The wallpaper: the images in wallpaper.folders, the one set, and rotation. Setting one points
// ~/.local/state/desktop/wallpaper at it, which the lock screen and sddm read too. On sway a video or
// GIF from the same folders can play over it as a live wallpaper, turned on and off by hand in the
// picker; the still one stays set beneath it, and rotation never touches the live one.
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
	property var liveFiles: [] // videos and GIFs (sway only)
	property string live: "" // the one playing, or ""
	property var thumbs: ({}) // a wallpaper -> its small picture (a video's frame), for the picker

	function isLive(path: string): bool {
		return /\.(gif|mp4|webm|mkv|mov)$/i.test(path);
	}

	// the one playing again stops it
	function setLive(path: string): void {
		if (path === live)
			return stopLive();
		live = path;
		Quickshell.execDetached(["desktop", "wallpaper", "live", path]);
	}

	function stopLive(): void {
		if (!live)
			return;
		live = "";
		Quickshell.execDetached(["desktop", "wallpaper", "live", "off"]);
	}

	function set(path: string): void {
		if (!path || path === current)
			return;
		current = path;
		changed = Date.now();
		if (apply.running) {
			pending = path;
			return;
		}
		apply.command = ["desktop", "wallpaper", "set", path];
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
		if (Config.wayland)
			liveList.running = true;
	}

	onFoldersChanged: scan()

	Process {
		id: apply

		onExited: {
			const next = root.pending;
			root.pending = "";
			if (next && next !== apply.command[2]) {
				apply.command = ["desktop", "wallpaper", "set", next];
				apply.running = true;
			}
		}
	}

	Process {
		id: list

		command: ["sh", "-c", 'for d in "$@"; do [ -d "$d" ] && find -L "$d" -maxdepth 2 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \\); done | sort', "sh", ...root.folders]
		stdout: StdioCollector {
			onStreamFinished: {
				root.files = text.split("\n").filter(f => f);
				root.makeThumbs();
			}
		}
	}

	Process {
		id: liveList

		command: ["sh", "-c", 'for d in "$@"; do [ -d "$d" ] && find -L "$d" -maxdepth 2 -type f \\( -iname "*.gif" -o -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" -o -iname "*.mov" \\); done | sort', "sh", ...root.folders]
		stdout: StdioCollector {
			onStreamFinished: {
				root.liveFiles = text.split("\n").filter(f => f);
				root.makeThumbs();
			}
		}
	}

	// each tile takes its small picture as soon as it's made: the first time all are made at the
	// lowest priority, later they're only read back (a new or edited file gets a new one)
	function makeThumbs(): void {
		const all = files.concat(liveFiles).filter(f => !thumbs[f]);
		if (!all.length || thumbnails.running)
			return;
		thumbnails.command = ["nice", "-n", "19", "desktop", "wallpaper", "thumbs", ...all];
		thumbnails.running = true;
	}

	Process {
		id: thumbnails

		stdout: SplitParser {
			onRead: line => {
				const [file, thumb] = line.split("\t");
				if (thumb)
					root.thumbs = Object.assign({}, root.thumbs, { [file]: thumb });
			}
		}
		onExited: root.makeThumbs() // any found while it ran
	}

	Process {
		running: Config.wayland
		command: ["sh", "-c", 'readlink -f "$1/live-wallpaper" || true', "sh", root.state]
		stdout: StdioCollector {
			onStreamFinished: root.live = text.trim()
		}
	}

	// nobody sees it behind the lock: paused, not decoding
	Connections {
		target: Lock

		function onLockedChanged(): void {
			if (root.live)
				Quickshell.execDetached(["desktop", "wallpaper", "live", Lock.locked ? "pause" : "resume"]);
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

	// a screen that appears has no wallpaper: the laptop's own after a suspend (it goes away and comes
	// back), a monitor plugged in. awww runs without its cache (it would cover a new one at login)
	Connections {
		target: Quickshell

		function onScreensChanged(): void {
			if (Config.wayland)
				redraw.restart();
		}
	}

	Timer {
		id: redraw

		interval: 1000 // once awww has seen the screen too
		onTriggered: Quickshell.execDetached(["desktop", "wallpaper", "restore"])
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
