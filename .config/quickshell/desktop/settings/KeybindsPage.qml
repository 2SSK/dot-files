pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.widgets

// Every key binding, read from i3's own config (keys.conf, workspaces.conf, resize.conf), so the
// list can't drift from what the keys do: each one in plain words, grouped (shell, windows,
// workspaces, apps, i3), the ten workspace keys folded into one row. Bindings inside a mode (the
// power menu's, the switcher's, resizing) and the keys inside the shell's own panels are listed by
// hand at the end. The settings window's search narrows it all.
Column {
	id: root

	readonly property string dir: Quickshell.env("HOME") + "/.config/i3/conf.d/"
	property var bindings: [] // { group, keys: [...], label }
	readonly property var groups: ["Shell", "Windows", "Workspaces", "Apps", "i3"]
	readonly property var inside: [
		{ keys: ["Alt", "Tab"], label: "Window switcher: hold Alt, Tab steps on (Shift+Tab back), let go to switch, Esc cancels" },
		{ keys: ["Tab"], label: "Launcher: next mode (apps, emoji, files, themes); Shift+Tab goes back" },
		{ keys: ["Enter"], label: "Launcher, files: copy the file, to paste as an attachment (Ctrl+Enter opens it, Shift+Enter copies its path)" },
		{ keys: ["←", "→", "↑", "↓"], label: "Launcher, capture and power menu: move; Enter picks" },
		{ keys: ["R", "W", "S"], label: "Capture: screenshot of a region, the window, a screen (with Shift: record)" },
		{ keys: ["1", "…", "5"], label: "Power menu: jump to an action" },
		{ keys: ["H", "J", "K", "L"], label: "Resize mode: shrink and grow the window (arrows too); Esc or Enter ends it" },
		{ keys: ["Space"], label: "Control center, Home: play or pause (← → skip)" },
		{ keys: ["Esc"], label: "Any panel: close it (a click beside it does too)" }
	]
	property string query // the search, from the settings window (it stays put while this scrolls)
	readonly property string needle: query.trim().toLowerCase()
	readonly property var shown: bindings.filter(b => match(b))

	function match(b: var): bool {
		return !needle || b.label.toLowerCase().includes(needle) || b.keys.join(" ").toLowerCase().includes(needle);
	}

	// "$mod+Shift+Return" -> ["Super", "Shift", "Enter"]
	function keys(combo: string): var {
		const names = { "$mod": "Super", "Mod4": "Super", "Mod1": "Alt", "Control": "Ctrl", "Return": "Enter", "minus": "−", "semicolon": ";", "period": ".", "comma": ",", "slash": "/", "space": "Space", "Escape": "Esc", "Left": "←", "Right": "→", "Up": "↑", "Down": "↓", "Print": "PrtSc" };
		return combo.split("+").map(k => names[k] ?? (k.length === 1 ? k.toUpperCase() : k));
	}

	// what a binding does, in words, and its group
	function describe(cmd: string): var {
		cmd = cmd.replace(/;\s*mode\s+"[^"]*"\s*$/, "").trim();
		const shell = cmd.match(/^\$shell\s+(\S+)\s+(\S+)\s*(.*)$/);
		if (shell) {
			const [, target, fn, arg] = shell;
			const known = {
				"audio up": "Volume up", "audio down": "Volume down", "audio mute": "Mute", "audio mic": "Microphone mute",
				"brightness up": "Brightness up", "brightness down": "Brightness down", "bar toggle": "Show or hide the bar",
				"recorder toggle": "Stop recording (else the capture panel)", "notifications toggle": "Notifications",
				"control toggle": "Control center", "clipboard toggle": "Clipboard history", "wallpaper toggle": "Wallpapers",
				"capture toggle": "Screenshot and recording", "settings toggle": "Settings", "power open": "Power menu",
				"switcher next": "Window switcher", "switcher prev": "Window switcher, backwards"
			};
			const label = known[`${target} ${fn}`] ?? (target === "launcher" ? `Launcher: ${arg}` : target === "control" && fn === "page" ? `Control center: ${arg}` : `${target} ${fn} ${arg}`.trim());
			return { group: "Shell", label };
		}
		let m;
		if ((m = cmd.match(/^workspace number (\d+)$/)))
			return { group: "Workspaces", label: `Workspace ${m[1]}` };
		if ((m = cmd.match(/^move container to workspace number (\d+)$/)))
			return { group: "Workspaces", label: `Move window to workspace ${m[1]}` };
		if ((m = cmd.match(/^workspace (next|prev)$/)))
			return { group: "Workspaces", label: m[1] === "next" ? "Next workspace" : "Previous workspace" };
		if ((m = cmd.match(/^focus (left|right|up|down)$/)))
			return { group: "Windows", label: `Focus ${m[1]}` };
		if ((m = cmd.match(/^move (left|right|up|down)$/)))
			return { group: "Windows", label: `Move window ${m[1]}` };
		if ((m = cmd.match(/^move window to output (\w+)$/)))
			return { group: "Windows", label: `Move window to the ${m[1]} monitor` };
		if ((m = cmd.match(/^move workspace to output (\w+)$/)))
			return { group: "Workspaces", label: `Move workspace to the ${m[1]} monitor` };
		const windows = {
			"kill": "Close window", "fullscreen toggle": "Fullscreen", "floating toggle": "Float or tile the window",
			"focus parent": "Focus the parent container", "focus mode_toggle": "Focus between tiled and floating",
			"layout stacking": "Stacked layout", "layout tabbed": "Tabbed layout", "layout toggle split": "Split layout, turned",
			"split h": "Split side by side", "split v": "Split one above the other", "scratchpad show": "Show the scratchpad",
			"move scratchpad": "Send the window to the scratchpad", "mode \"resize\"": "Resize mode",
			"mode \"passthrough\"": "Keys to the VM (again: back to i3)"
		};
		if (windows[cmd])
			return { group: "Windows", label: windows[cmd] };
		const i3 = { "reload": "Reload i3's config", "restart": "Restart i3 in place", "exit": "Log out" };
		if (i3[cmd])
			return { group: "i3", label: i3[cmd] };
		if (/^exec\s+(?:--no-startup-id\s+)?desktop-capture shot region$/.test(cmd))
			return { group: "Shell", label: "Screenshot a region (panels stay open)" };
		if ((m = cmd.match(/^exec\s+(?:--no-startup-id\s+)?(.*)$/)))
			return { group: "Apps", label: m[1] === "$term" ? "Terminal" : `Run ${m[1]}` };
		return { group: "i3", label: cmd };
	}

	function parse(text: string): var {
		const found = [];
		let depth = 0;
		for (const raw of text.split("\n")) {
			const line = raw.trim();
			if (/^mode\s+"[^"]*"\s*\{$/.test(line)) {
				depth++;
				continue;
			}
			if (line === "}") {
				depth = Math.max(0, depth - 1);
				continue;
			}
			const m = line.match(/^bindsym\s+(?:--\S+\s+)*(\S+)\s+(.+)$/);
			if (!m || depth > 0 || m[1].startsWith("XF86"))
				continue;
			found.push(Object.assign({ keys: keys(m[1]) }, describe(m[2])));
		}
		return found;
	}

	// the ten workspace keys (and their move keys) as one row each
	function fold(list: var): var {
		const out = [];
		for (const [pattern, label] of [[/^Workspace \d+$/, "Workspace 1 … 10"], [/^Move window to workspace \d+$/, "Move window to workspace 1 … 10"]]) {
			const rows = list.filter(b => pattern.test(b.label));
			if (rows.length)
				out.push({ group: "Workspaces", keys: [...rows[0].keys.slice(0, -1), "1 … 0"], label });
		}
		return [...list.filter(b => !/^(Move window to )?[Ww]orkspace \d+$/.test(b.label)), ...out];
	}

	function load(): void {
		bindings = fold([keysFile, workspacesFile, resizeFile].map(f => parse(f.text())).reduce((all, list) => all.concat(list), []));
	}

	spacing: 18

	FileView {
		id: keysFile

		path: root.dir + "keys.conf"
		blockLoading: true
		printErrors: false
		onLoaded: root.load()
	}

	FileView {
		id: workspacesFile

		path: root.dir + "workspaces.conf"
		blockLoading: true
		printErrors: false
		onLoaded: root.load()
	}

	FileView {
		id: resizeFile

		path: root.dir + "resize.conf"
		blockLoading: true
		printErrors: false
		onLoaded: root.load()
	}

	component KeyCaps: Row {
		required property var list

		spacing: 4

		Repeater {
			model: parent.list

			delegate: Rectangle {
				required property string modelData

				width: Math.max(26, key.implicitWidth + 14)
				height: 24
				radius: 6
				color: Qt.alpha(Theme.surface, 0.9)
				border.width: 1
				border.color: Qt.alpha(Theme.border, 0.9)

				Text {
					id: key

					anchors.centerIn: parent
					text: parent.modelData
					color: Theme.fg
					font.family: Theme.fontSans
					font.hintingPreference: Theme.hinting
					font.pixelSize: Theme.textLabel
					font.weight: Font.Medium
				}
			}
		}
	}

	component KeyRow: Item {
		required property var modelData

		width: root.width
		height: 34

		KeyCaps {
			anchors.verticalCenter: parent.verticalCenter
			list: parent.modelData.keys
		}

		Text {
			x: 230
			width: parent.width - x
			anchors.verticalCenter: parent.verticalCenter
			text: parent.modelData.label
			elide: Text.ElideRight
			color: Theme.fg
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.weight: Theme.textWeight
			font.pixelSize: Theme.textBody
		}
	}

	Repeater {
		model: root.groups

		delegate: Section {
			id: group

			required property string modelData
			readonly property var rows: root.shown.filter(b => b.group === modelData)

			visible: rows.length > 0
			title: modelData

			Repeater {
				model: group.rows

				delegate: KeyRow {}
			}
		}
	}

	Section {
		readonly property var rows: root.inside.filter(b => root.match(b))

		visible: rows.length > 0
		title: "Inside the shell"

		Repeater {
			model: parent.rows

			delegate: KeyRow {}
		}
	}

	Text {
		visible: root.bindings.length === 0
		text: "No i3 key config found in " + root.dir
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.hintingPreference: Theme.hinting
		font.weight: Theme.textWeight
		font.pixelSize: Theme.textBody
	}
}
