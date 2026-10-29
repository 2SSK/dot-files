pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

// Screen sharing's picker: desktop share-pick (the portal's chooser) hands over what can be shared and
// waits on a FIFO in its folder; the capture panel asks which. Closing the panel declines.
Singleton {
	id: root

	property string dir: "" // the waiting picker's folder; "" when none waits
	property var sources: [] // screens, then windows most recent first: { line, screen, name, detail, icon }

	function pick(folder: string): void {
		answer(""); // one asked before still waiting: declined
		file.path = `${folder}/sources`;
		const screens = [], windows = [];
		for (const line of file.text().split("\n")) {
			const monitor = line.match(/^Monitor: (\S+) ?(.*)$/);
			const window = line.match(/^Window: (.*) \(([^()]*)\)$/);
			if (monitor) {
				screens.push({ line, screen: true, name: monitor[1], detail: monitor[2], icon: "" });
			} else if (window) {
				const i = Windows.windows.findIndex(w => w.title === window[1]);
				const w = Windows.windows[i];
				const entry = w ? DesktopEntries.heuristicLookup(w.cls) : null;
				windows.push({ line, screen: false, name: window[1], rank: i < 0 ? 1e6 : i,
					detail: [entry?.name ?? w?.cls, w ? `workspace ${w.workspace}` : ""].filter(Boolean).join("  ·  "),
					icon: entry?.icon ?? w?.cls.toLowerCase() ?? "" });
			}
		}
		sources = [...screens, ...windows.sort((a, b) => a.rank - b.rank)];
		dir = folder;
		Panel.captureAsk = "";
		Panel.captureOpen = true;
	}

	// line: one of the portal's, or "" to decline
	function answer(line: string): void {
		if (!dir)
			return;
		Quickshell.execDetached(["timeout", "5", "sh", "-c", 'printf "%s\\n" "$1" >"$2"', "sh", line, `${dir}/answer`]);
		dir = "";
	}

	function take(line: string): void {
		answer(line);
		Panel.captureOpen = false;
	}

	FileView {
		id: file

		blockLoading: true
	}

	Connections {
		target: Panel

		function onCaptureOpenChanged(): void {
			if (!Panel.captureOpen)
				root.answer("");
		}
	}
}
