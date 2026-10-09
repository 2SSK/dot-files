pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Screen recording with gpu-screen-recorder (through desktop-capture): a dragged region, the
// focused window, or a screen (a monitor by name, else all of them), at 60 fps with the system
// sound, into ~/Videos. Stopping sends SIGINT, which makes it finish the file. toggle() stops a
// recording, else opens the capture panel on Record.
Singleton {
	id: root

	readonly property bool recording: process.running && started.getTime() > 0
	readonly property string folder: Quickshell.env("XDG_VIDEOS_DIR") || Quickshell.env("HOME") + "/Videos"
	property string file: ""
	property date started: new Date(0)

	function toggle(): void {
		if (process.running)
			stop();
		else
			Panel.openCapture("record");
	}

	function stop(): void {
		process.signal(2);
	}

	// mode: region, window or screen; monitor: a screen's name, or "" for all
	function start(mode: string, monitor: string): void {
		if (process.running)
			return;
		file = `${folder}/Recording ${Qt.formatDateTime(new Date(), "yyyy-MM-dd HH.mm.ss")}.mp4`;
		process.command = ["desktop-capture", "record", mode, file, ...(monitor ? ["--monitor", monitor] : [])];
		started = new Date(0);
		process.running = true;
	}

	Process {
		id: process

		onRunningChanged: if (!running) root.started = new Date(0)
		// desktop-capture says "recording" once the region is picked and the recorder starts
		stdout: SplitParser {
			onRead: line => {
				if (line === "recording")
					root.started = new Date();
			}
		}
		onExited: code => {
			if (code === 1)
				return; // the region was cancelled
			Quickshell.execDetached(["notify-send", "-a", "Screen recording", code === 0 ? "Recording saved" : "Recording failed", code === 0 ? root.file : `gpu-screen-recorder exited with ${code}`]);
		}
	}
}
