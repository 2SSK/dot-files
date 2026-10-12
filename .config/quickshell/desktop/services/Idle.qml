pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Idle dim, lock and screen off after idle.dim, .lock and .off minutes (0: never). On i3 desktop-idle
// sets X's timers; on sway the shell runs swayidle, which also locks before sleep and on lock-session.
Singleton {
	id: root

	readonly property bool wayland: Config.wayland
	readonly property var times: [Config.idle.dim, Config.idle.lock, Config.idle.off]
	// swayidle's arguments: each timeout counts from when you stopped
	readonly property var swayidle: {
		const [dim, lock, off] = times;
		// One swayidle per display: a shell restart leaves this display's last one running, so it goes first,
		// with KILL since an orphan no longer runs the event loop that handles TERM. Without it nothing locks.
		const missing = 'notify-send -u critical -a Lock "The screen can\'t lock" "swayidle isn\'t installed: Lock, the lid, idle and sleep do nothing on sway. Install it: pacman -S swayidle (Arch) or dnf install swayidle (Fedora)"';
		const args = ["sh", "-c", `command -v swayidle >/dev/null || { ${missing}; exit 127; }; for p in $(pgrep -u "$(id -u)" -x swayidle); do tr "\\0" "\\n" <"/proc/$p/environ" 2>/dev/null | grep -qx "WAYLAND_DISPLAY=$WAYLAND_DISPLAY" && kill -KILL "$p"; done; exec swayidle "$@"`, "sh", "-w"];
		if (dim > 0 && (lock === 0 || dim < lock))
			// dim stays running until undim stops it; in the background, since swayidle -w waits for each
			// command, and a waiting swayidle neither undims nor locks
			args.push("timeout", String(dim * 60), "desktop-idle dim &", "resume", "desktop-idle undim");
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
