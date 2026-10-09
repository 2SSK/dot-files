pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// When idle (Settings → Power): the screen dims, locks, then switches off after idle.dim, .lock
// and .off minutes; desktop-idle sets X's timers to them, at start and on every change (xss-lock
// does the dimming and locking). Wayland: swayidle, with the sway port.
Singleton {
	id: root

	readonly property var times: [Config.idle.dim, Config.idle.lock, Config.idle.off]

	onTimesChanged: later.restart()
	Component.onCompleted: later.restart()

	Timer {
		id: later

		interval: 500
		onTriggered: if (!Quickshell.env("WAYLAND_DISPLAY")) apply.running = true
	}

	Process {
		id: apply

		command: ["desktop-idle", "apply", String(Config.idle.dim), String(Config.idle.lock), String(Config.idle.off)]
	}
}
