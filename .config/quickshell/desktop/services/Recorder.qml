pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Screen recording with gpu-screen-recorder: the whole screen at 60 fps with the system sound,
// into ~/Videos. Stopping sends SIGINT, which makes it finish the file.
Singleton {
	id: root

	readonly property bool recording: process.running
	readonly property string folder: Quickshell.env("XDG_VIDEOS_DIR") || Quickshell.env("HOME") + "/Videos"
	property string file: ""
	property date started: new Date()

	function toggle(): void {
		recording ? process.signal(2) : start();
	}

	function start(): void {
		file = `${folder}/Recording ${Qt.formatDateTime(new Date(), "yyyy-MM-dd HH.mm.ss")}.mp4`;
		started = new Date();
		process.running = true;
	}

	Process {
		id: process

		command: ["sh", "-c", 'mkdir -p "$1" && exec gpu-screen-recorder -w screen -f 60 -a default_output -o "$2"', "sh", root.folder, root.file]
		onExited: code => Quickshell.execDetached(["notify-send", "-a", "Screen recording", code === 0 ? "Recording saved" : "Recording failed", code === 0 ? root.file : `gpu-screen-recorder exited with ${code}`])
	}
}
