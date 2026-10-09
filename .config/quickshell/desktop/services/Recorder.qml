pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Screen recording with gpu-screen-recorder (through desktop-capture): a dragged region, the
// focused window, or a screen (a monitor by name, else all of them), at 60 fps with the system
// sound, into ~/Videos/Recordings. Stopping sends SIGINT, which makes it finish the file. toggle()
// stops a recording, else opens the capture panel on Record. A region is dragged first: recording
// (the bar's red camera and clock) starts once it's picked.
Singleton {
	id: root

	readonly property bool recording: process.running && !picking
	property bool picking: false // a region being dragged
	readonly property string folder: (Quickshell.env("XDG_VIDEOS_DIR") || Quickshell.env("HOME") + "/Videos") + "/Recordings"
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
		picking = mode === "region";
		started = new Date();
		process.running = true;
	}

	Process {
		id: process

		onRunningChanged: if (!running) root.picking = false
		// desktop-capture says "recording" once the region is picked and the recorder starts
		stdout: SplitParser {
			onRead: line => {
				if (line === "recording" && root.picking) {
					root.picking = false;
					root.started = new Date();
				}
			}
		}
		onExited: code => {
			if (code === 1)
				return; // the region was cancelled
			Quickshell.execDetached(["notify-send", "-a", "Screen recording", code === 0 ? "Recording saved" : "Recording failed", code === 0 ? root.file : `gpu-screen-recorder exited with ${code}`]);
		}
	}
}
