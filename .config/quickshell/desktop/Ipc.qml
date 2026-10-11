import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// The shell's IPC: what keys.conf and the scripts in ~/.local/bin ask for, as
// qs -c desktop ipc call <target> <function> [argument]. docs/desktop-shell.md lists them.
Scope {
	IpcHandler {
		target: "lock"

		function lock(): void {
			if (Config.wayland)
				Lock.lock();
		}
		// true once sway confirms the lock, which desktop-lock waits for before sleep goes ahead
		function locked(): bool {
			return Lock.secure;
		}
	}

	IpcHandler {
		target: "audio"

		function up(): void {
			Audio.change(Config.audio.step);
		}
		function down(): void {
			Audio.change(-Config.audio.step);
		}
		function mute(): void {
			Audio.toggleMute();
		}
		function mic(): void {
			Audio.toggleMic();
		}
	}

	IpcHandler {
		target: "brightness"

		function up(): void {
			Brightness.change(Config.brightness.step);
		}
		function down(): void {
			Brightness.change(-Config.brightness.step);
		}
	}

	IpcHandler {
		target: "bar"

		function toggle(): void {
			Panel.toggleBar();
		}
	}

	IpcHandler {
		target: "notifications"

		function toggle(): void {
			Panel.toggleControl("notifications");
		}
		function dnd(): void {
			Notifications.dnd = !Notifications.dnd;
		}
		function clear(): void {
			Notifications.clear();
		}
	}

	IpcHandler {
		target: "control"

		function toggle(): void {
			Panel.toggleControl("home");
		}
		function open(page: string): void {
			Panel.controlPage = page;
			Panel.controlOpen = true;
		}
		function close(): void {
			Panel.controlOpen = false;
		}
		function page(page: string): void {
			Panel.toggleControl(page);
		}
	}

	IpcHandler {
		target: "clipboard"

		function toggle(): void {
			Panel.clipboardOpen = !Panel.clipboardOpen;
		}
	}

	// mode is region, window or screen
	IpcHandler {
		target: "capture"

		function toggle(): void {
			Panel.captureOpen ? Panel.captureOpen = false : Panel.openCapture("");
		}
		function shot(mode: string): void {
			Capture.start("shot", mode);
		}
		function record(mode: string): void {
			Capture.start("record", mode);
		}
		function stop(): void {
			Recorder.stop();
		}
	}

	// the window switcher, driven by i3's "switcher" mode
	IpcHandler {
		target: "switcher"

		function next(): void {
			Windows.step(1);
		}
		function prev(): void {
			Windows.step(-1);
		}
		function commit(): void {
			Windows.commit();
		}
		function cancel(): void {
			Windows.close();
		}
		// the ring's titles, most recent first, for checking it
		function list(): string {
			return Windows.windows.map(w => w.title).join("\n");
		}
	}

	IpcHandler {
		target: "launcher"

		function toggle(mode: string): void {
			Panel.toggleLauncher(mode);
		}
		function close(): void {
			Panel.launcherOpen = false;
		}
	}

	IpcHandler {
		target: "nightlight"

		function toggle(): void {
			NightLight.toggle();
		}
	}

	IpcHandler {
		target: "wallpaper"

		function toggle(): void {
			Panel.wallpaperOpen = !Panel.wallpaperOpen;
		}
		function shuffle(): void {
			Wallpaper.shuffle();
		}
	}

	IpcHandler {
		target: "alarm"

		function stop(): void {
			Alarms.stop();
		}
		function snooze(): void {
			Alarms.snooze();
		}
	}

	IpcHandler {
		target: "settings"

		function toggle(): void {
			Panel.settingsOpen = !Panel.settingsOpen;
		}
		// a page such as bar, appearance, notifications, levels, power, timeshift or keys
		function page(page: string): void {
			if (Panel.settingsOpen && Panel.settingsPage === page) {
				Panel.settingsOpen = false;
				return;
			}
			Panel.settingsPage = page;
			Panel.settingsOpen = true;
		}
	}

	IpcHandler {
		target: "recorder"

		function toggle(): void {
			Recorder.toggle();
		}
	}

	IpcHandler {
		target: "power"

		function toggle(): void {
			Panel.togglePower();
		}
		function open(): void {
			Panel.openPower();
		}
		function close(): void {
			Panel.closePower();
		}
		function next(): void {
			Panel.move(1);
		}
		function prev(): void {
			Panel.move(-1);
		}
		function activate(): void {
			Panel.activate(Panel.selected);
		}
		function pick(number: int): void {
			Panel.activate(number - 1);
		}
	}
}
