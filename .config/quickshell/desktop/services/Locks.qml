pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Caps Lock and Num Lock, read from the keyboard LEDs in /sys (the same on X11 and Wayland, and no
// key bindings needed); a change shows in the OSD.
Singleton {
	id: root

	property bool caps: false
	property bool num: false
	property string capsLed: ""
	property string numLed: ""
	property bool ready: false

	function read(file: FileView): bool {
		if (!file)
			return false; // a reload tearing the shell down mid-tick
		file.reload();
		return file.text().trim() !== "0";
	}

	Process {
		running: true
		command: ["sh", "-c", "ls -d /sys/class/leds/*::capslock /sys/class/leds/*::numlock 2>/dev/null"]
		stdout: StdioCollector {
			onStreamFinished: {
				const leds = text.trim().split("\n");
				root.capsLed = leds.find(led => led.endsWith("::capslock")) ?? "";
				root.numLed = leds.find(led => led.endsWith("::numlock")) ?? "";
			}
		}
	}

	FileView {
		id: capsFile

		path: root.capsLed ? root.capsLed + "/brightness" : ""
		blockLoading: true
		printErrors: false
	}

	FileView {
		id: numFile

		path: root.numLed ? root.numLed + "/brightness" : ""
		blockLoading: true
		printErrors: false
	}

	Timer {
		interval: 500
		running: root.capsLed !== "" || root.numLed !== ""
		repeat: true
		onTriggered: {
			const caps = root.capsLed ? root.read(capsFile) : false;
			const num = root.numLed ? root.read(numFile) : false;
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
