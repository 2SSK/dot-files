pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// When idle (Settings → Power): the screen dims, locks, then switches off after idle.dim, .lock
// and .off minutes (0: never). X11 (i3): desktop-idle sets X's timers, at start and on every change
// (xss-lock dims and locks). Wayland (sway): the shell runs swayidle with them, restarted on a
// change; it also locks before sleep.
Singleton {
	id: root

	readonly property bool wayland: !!Quickshell.env("WAYLAND_DISPLAY")
	readonly property var times: [Config.idle.dim, Config.idle.lock, Config.idle.off]
	// swayidle's arguments: each timeout counts from when you stopped
	readonly property var swayidle: {
		const [dim, lock, off] = times;
		const args = ["swayidle", "-w"];
		if (dim > 0 && (lock === 0 || dim < lock))
			args.push("timeout", String(dim * 60), "desktop-idle dim", "resume", "desktop-idle undim");
		if (lock > 0)
			args.push("timeout", String(lock * 60), "desktop-idle undim; desktop-lock");
		if (off > 0)
			args.push("timeout", String(off * 60), "swaymsg 'output * power off'", "resume", "swaymsg 'output * power on'");
		args.push("before-sleep", "desktop-lock", "lock", "desktop-lock");
		return args;
	}

	onTimesChanged: later.restart()
	Component.onCompleted: later.restart()

	Timer {
		id: later

		interval: 500
		onTriggered: {
			if (root.wayland) {
				idler.running = false;
				idler.running = true;
			} else {
				apply.running = true;
			}
		}
	}

	Process {
		id: apply

		command: ["desktop-idle", "apply", String(Config.idle.dim), String(Config.idle.lock), String(Config.idle.off)]
	}

	Process {
		id: idler

		command: root.swayidle
	}
}
