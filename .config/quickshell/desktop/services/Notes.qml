pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// One scratch note, kept on this machine in ~/.local/share/desktop/notes.md; written a moment after
// typing stops.
Singleton {
	id: root

	property string pending: ""

	function read(): string {
		file.reload();
		return file.text();
	}

	function write(text: string): void {
		pending = text;
		saveTimer.restart();
	}

	Timer {
		id: saveTimer

		interval: 600
		onTriggered: file.setText(root.pending)
	}

	FileView {
		id: file

		path: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/desktop/notes.md"
		blockLoading: true
		printErrors: false
	}
}
