pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// The screen backlight through brightnessctl; unavailable without one (desktops, VMs).
Singleton {
	id: root

	property bool available: false
	property string device: ""
	property real value: 0 // 0–1

	// from a slider: no OSD; brightnessctl runs at most every 60 ms while dragging
	function set(level: real): void {
		if (!available)
			return;
		value = Math.max(0.01, Math.min(1, level));
		pending.restart();
	}

	Timer {
		id: pending

		interval: 60
		onTriggered: Quickshell.execDetached(["brightnessctl", "-q", "-d", root.device, "set", Math.round(root.value * 100) + "%"])
	}

	function change(percent: int): void {
		if (!available)
			return;
		value = Math.max(0.01, Math.min(1, Math.round(value * 100 + percent) / 100));
		Quickshell.execDetached(["brightnessctl", "-q", "-d", device, "set", Math.round(value * 100) + "%"]);
		Panel.osd("brightness", value, false);
	}

	// one line: device,class,current,percent,max
	Process {
		running: true
		command: ["brightnessctl", "-m", "-c", "backlight"]
		stdout: StdioCollector {
			onStreamFinished: {
				const fields = text.trim().split(",");
				if (fields.length < 5)
					return;
				root.device = fields[0];
				root.value = parseInt(fields[2]) / parseInt(fields[4]);
				root.available = true;
			}
		}
	}
}
