pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Caps Lock and Num Lock, read from the keyboard LEDs in /sys (the same on X11 and Wayland, and no
// key bindings needed); a change shows in the OSD. Every keyboard's LEDs count (on when any is: the
// window manager keeps them in step), and the list is looked at again every 10 s: a keyboard that
// reconnects (Bluetooth, a replug, waking up) comes back under a new name, and watching only the
// one found at startup missed its changes.
Singleton {
	id: root

	property bool caps: false
	property bool num: false
	property var leds: [] // every keyboard's caps and num lock LED folders
	property bool ready: false

	function lit(kind: string): bool {
		for (let i = 0; i < views.count; i++) {
			const view = views.objectAt(i);
			if (!view || !view.led.endsWith(kind))
				continue;
			view.reload();
			if (view.text().trim() === "1")
				return true;
		}
		return false;
	}

	Process {
		id: scan

		running: true
		command: ["sh", "-c", "ls -d /sys/class/leds/*::capslock /sys/class/leds/*::numlock 2>/dev/null"]
		stdout: StdioCollector {
			onStreamFinished: {
				const found = text.trim().split("\n").filter(led => led);
				if (found.join() !== root.leds.join())
					root.leds = found;
			}
		}
	}

	Timer {
		interval: 10000
		running: true
		repeat: true
		onTriggered: scan.running = true
	}

	Instantiator {
		id: views

		model: root.leds

		delegate: FileView {
			required property string modelData
			readonly property string led: modelData

			path: modelData + "/brightness"
			blockLoading: true
			printErrors: false
		}
	}

	Timer {
		interval: 500
		running: root.leds.length > 0
		repeat: true
		onTriggered: {
			const caps = root.lit("::capslock");
			const num = root.lit("::numlock");
			if (root.ready && caps !== root.caps)
				Panel.osd("caps", caps ? 1 : 0, !caps);
			if (root.ready && num !== root.num)
				Panel.osd("num", num ? 1 : 0, !num);
			root.caps = caps;
			root.num = num;
			root.ready = true;
		}
	}
}
