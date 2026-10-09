pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The active desktop theme's palette (palette.json, rendered by `theme`). A switch swaps the whole
// state directory, so besides watching the file, theme calls `qs -c desktop ipc call theme reload`.
Singleton {
	id: root

	property var palette: ({})
	readonly property var ui: palette.ui ?? ({})

	readonly property color bg: ui.bg ?? "#1a1b26"
	readonly property color surface: ui.surface ?? "#292e42"
	readonly property color overlay: ui.overlay ?? "#3b4261"
	readonly property color fg: ui.fg ?? "#c0caf5"
	readonly property color fgMuted: ui.fg_muted ?? "#737aa2"
	readonly property color primary: ui.primary ?? "#7aa2f7"
	readonly property color onPrimary: ui.on_primary ?? "#1a1b26"
	readonly property color border: ui.border ?? "#3b4261"
	readonly property color error: ui.error ?? "#f7768e"
	readonly property color success: ui.success ?? "#9ece6a"

	readonly property string fontSans: "Inter"
	readonly property string fontMono: "JetBrainsMono Nerd Font"
	readonly property int fontSize: Math.round(Config.bar.size * 0.4)

	FileView {
		id: file

		path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/desktop/theme/palette.json"
		watchChanges: true
		onFileChanged: reload()
		onLoaded: root.palette = JSON.parse(text())
	}

	IpcHandler {
		target: "theme"

		function reload(): void {
			file.reload();
		}
	}
}
