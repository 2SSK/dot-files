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
	readonly property JsonObject audio: adapter.audio
	readonly property JsonObject brightness: adapter.brightness
	readonly property JsonObject power: adapter.power
	// i3 docks only at the top or bottom (a side dock takes the whole screen), so on X11 a side
	// position falls back to the top; sway places the bar on any edge
	readonly property bool wayland: !!Quickshell.env("WAYLAND_DISPLAY")
	readonly property string position: wayland || bar.position === "top" || bar.position === "bottom" ? bar.position : "top"
	readonly property bool vertical: position === "left" || position === "right"
	readonly property bool island: bar.style === "island"

	function save(): void {
		file.writeAdapter();
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
				property string position: "top" // top, bottom, left or right
				property int size: 34
				property real opacity: 0.85
				property real length: 0.66 // the island's share of the screen edge; 0 fits its content
				property var left: ["launcher", "workspaces"]
				property var center: ["clock"]
				property var right: ["tray", "stats", "volume", "brightness", "battery", "power"]
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
			property JsonObject power: JsonObject {
				property bool confirm: true // a second press runs the action
			}
		}
	}
}
