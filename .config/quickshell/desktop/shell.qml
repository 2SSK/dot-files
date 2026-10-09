// The desktop shell (qs -c desktop): one bar per screen, which grows into the OSD and the power
// menu. Settings: Config (~/.config/desktop/shell.json); colours: Theme (the desktop theme).
// Keys reach it over IPC: qs -c desktop ipc call <target> <function> (see i3's keys.conf).
import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar
import qs.clipboard
import qs.control
import qs.settings
import qs
import qs.services

ShellRoot {
	// services that watch on their own, started with the shell
	readonly property var watchers: [Locks, Recorder, Notifications, Clipboard]

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

	IpcHandler {
		target: "settings"

		function toggle(): void {
			Panel.settingsOpen = !Panel.settingsOpen;
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
