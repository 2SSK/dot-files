// The desktop shell (qs -c desktop): one bar per screen, which grows into the OSD and the power
// menu. Settings: Config (~/.config/desktop/shell.json); colours: Theme (the desktop theme).
// Keys reach it over IPC: qs -c desktop ipc call <target> <function> (see i3's keys.conf).
import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar
import qs
import qs.services

ShellRoot {
	// services that watch on their own, started with the shell
	readonly property var watchers: [Locks, Recorder]

	Variants {
		model: Quickshell.screens

		Bar {}
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
