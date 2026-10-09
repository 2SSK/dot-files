// The desktop shell (qs -c desktop): one bar per screen, which grows into the OSD and the power
// menu. Settings: Config (~/.config/desktop/shell.json); colours: Theme (the desktop theme).
// Keys reach it over IPC: qs -c desktop ipc call <target> <function> (see i3's keys.conf).
import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar
import qs.clipboard
import qs.wallpaper
import qs.launcher
import qs.capture
import qs.control
import qs.settings
import qs
import qs.services

ShellRoot {
	// services that watch on their own, started with the shell
	readonly property var watchers: [Locks, Recorder, Notifications, Clipboard, Events, Alarms, Wallpaper, Windows]

	Variants {
		model: Quickshell.screens

		Bar {}
	}

	LazyLoader {
		active: Panel.controlShown

		ControlCenter {
			visible: true
		}
	}

	LazyLoader {
		active: Panel.clipboardShown

		ClipboardWindow {
			visible: true
		}
	}

	LazyLoader {
		active: Panel.captureShown

		CaptureWindow {
			visible: true
		}
	}

	LazyLoader {
		active: Panel.launcherShown

		LauncherWindow {
			visible: true
		}
	}

	LazyLoader {
		active: Panel.wallpaperShown

		WallpaperWindow {
			visible: true
		}
	}

	LazyLoader {
		active: Panel.settingsOpen

		SettingsWindow {
			visible: true
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
		// a page, closing it when it's already showing (keys: todo, notes)
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

	// screenshots and recordings: region, window or screen (a screen asks which when there are several)
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
		// the ring's order, most recent first (for checking it)
		function list(): string {
			return Windows.windows.map(w => w.title).join("\n");
		}
	}

	// apps, emoji, files or themes; again on the same one closes it
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
		// a page (bar, appearance, notifications, levels, power, keys); again on the same one closes it
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
