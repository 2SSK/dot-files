pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Shell settings: ~/.config/desktop/shell.json, stowed from the repo so they're versioned. Keys
// missing from the file keep the defaults below.
Singleton {
	id: root

	readonly property JsonObject bar: adapter.bar
	readonly property JsonObject osd: adapter.osd
	readonly property JsonObject notifications: adapter.notifications
	readonly property JsonObject audio: adapter.audio
	readonly property JsonObject brightness: adapter.brightness
	readonly property JsonObject power: adapter.power
	readonly property JsonObject nightLight: adapter.nightLight
	readonly property JsonObject idle: adapter.idle
	readonly property JsonObject wallpaper: adapter.wallpaper
	readonly property JsonObject fonts: adapter.fonts
	// i3 docks only at the top or bottom (a side dock takes the whole screen), so on X11 a side
	// position falls back to the top; sway places the bar on any edge
	readonly property bool wayland: !!Quickshell.env("WAYLAND_DISPLAY")
	readonly property string position: wayland || bar.position === "top" || bar.position === "bottom" ? bar.position : "top"
	readonly property bool vertical: position === "left" || position === "right"
	readonly property bool island: bar.style === "island"

	// write shell.json soon after the last change (sliders change many times a second)
	// a setting changed and kept: Config.set("bar", "style", "island")
	function set(group: string, key: string, value: var): void {
		root[group][key] = value;
		save();
	}

	function save(): void {
		saveTimer.restart();
	}

	Timer {
		id: saveTimer

		interval: 400
		onTriggered: file.writeAdapter()
	}

	FileView {
		id: file

		path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/desktop/shell.json"
		watchChanges: true
		onFileChanged: reload()
		atomicWrites: false // write through the stow link into the repo instead of replacing it
		printErrors: false

		JsonAdapter {
			id: adapter

			property JsonObject bar: JsonObject {
				property string style: "island" // island: a floating pill; static: the whole edge
				property bool capsules: true // each widget in a soft capsule
				property string position: "top" // top, bottom, left or right
				property int size: 34
				property real opacity: 0.85
				property real length: 0 // the island's share of the screen edge; 0 picks one for the screen width
				property var left: ["workspaces", "scratchpad", "stats"]
				property var center: ["clock"]
				property var right: ["tray", "brightness", "tools", "recorder", "battery", "wifi", "bluetooth", "notifications", "power"]
			}
			property JsonObject fonts: JsonObject {
				property real scale: 1.15 // the shell's text against its base sizes (Settings → Appearance)
			}
			property JsonObject notifications: JsonObject {
				property int timeout: 5000 // ms a popup stays, unless the app sets its own
			}
			property JsonObject osd: JsonObject {
				property int timeout: 1800 // ms
			}
			property JsonObject audio: JsonObject {
				property int step: 5 // percent
			}
			property JsonObject brightness: JsonObject {
				property int step: 5
			}
			property JsonObject wallpaper: JsonObject {
				property var folders: ["~/.local/share/desktop/wallpapers", "~/Wallpaper-Bank"]
				property string rotate: "off" // off, 5m, 1h, 1d or boot
			}
			property JsonObject idle: JsonObject {
				property int dim: 4 // minutes alone until the screen dims (0: never)
				property int lock: 5 // until it locks
				property int off: 10 // until the screen switches off
			}
			property JsonObject nightLight: JsonObject {
				property int temperature: 4000 // K: lower is warmer
				property bool schedule: false // on by itself between from and to
				property string from: "19:00"
				property string to: "07:00"
			}
			property JsonObject power: JsonObject {
				property bool confirm: true // a second press runs the action
				property int batteryLow: 25 // % at which the battery turns red and warns
			}
		}
	}
}
