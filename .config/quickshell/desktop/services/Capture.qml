pragma Singleton

import QtQuick
import Quickshell
import qs

// Screenshots and recordings, from the capture panel (F12) or its IPC. With several monitors a
// screen capture asks which; the panel is closed and gone before anything is taken.
Singleton {
	id: root

	property var pending: null

	// kind: shot or record; mode: region, window or screen
	function start(kind: string, mode: string): void {
		if (mode === "screen" && Quickshell.screens.length > 1)
			Panel.openCapture(kind);
		else
			take(kind, mode, null);
	}

	// screen: a ShellScreen, or null for all of them
	function take(kind: string, mode: string, screen: var): void {
		pending = { kind, mode, monitor: screen?.name ?? "", geometry: screen ? `${screen.width}x${screen.height}+${screen.x}+${screen.y}` : "" };
		later.interval = Panel.captureOpen ? Theme.normal + 60 : 40; // the panel folded off screen first
		Panel.captureOpen = false;
		later.restart();
	}

	Timer {
		id: later

		onTriggered: {
			const p = root.pending;
			root.pending = null;
			if (!p)
				return;
			if (p.kind === "record")
				Recorder.start(p.mode, p.monitor);
			else
				Quickshell.execDetached(["desktop-capture", "shot", p.mode, ...(p.monitor ? ["--monitor", p.monitor, "--geometry", p.geometry] : [])]);
		}
	}
}
