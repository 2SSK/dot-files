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

	property color bg: ui.bg ?? "#1a1b26"
	property color surface: ui.surface ?? "#292e42"
	property color overlay: ui.overlay ?? "#3b4261"
	property color fg: ui.fg ?? "#c0caf5"
	property color fgMuted: ui.fg_muted ?? "#737aa2"
	property color primary: ui.primary ?? "#7aa2f7"
	property color primaryText: ui.on_primary ?? "#1a1b26"
	property color border: ui.border ?? "#3b4261"
	property color error: ui.error ?? "#f7768e"
	property color success: ui.success ?? "#9ece6a"
	property color warning: ui.warning ?? "#e0af68"
	property color secondary: ui.secondary ?? "#bb9af7"

	// a theme switch fades every colour across, the way the wallpaper does (not at startup: from the
	// fallbacks to the first palette is no change to see)
	property bool fades: false
	Behavior on bg { enabled: root.fades; Fade {} }
	Behavior on surface { enabled: root.fades; Fade {} }
	Behavior on overlay { enabled: root.fades; Fade {} }
	Behavior on fg { enabled: root.fades; Fade {} }
	Behavior on fgMuted { enabled: root.fades; Fade {} }
	Behavior on primary { enabled: root.fades; Fade {} }
	Behavior on primaryText { enabled: root.fades; Fade {} }
	Behavior on border { enabled: root.fades; Fade {} }
	Behavior on error { enabled: root.fades; Fade {} }
	Behavior on success { enabled: root.fades; Fade {} }
	Behavior on warning { enabled: root.fades; Fade {} }
	Behavior on secondary { enabled: root.fades; Fade {} }

	component Fade: ColorAnimation {
		duration: root.slow
		easing.type: root.curve
	}

	readonly property string fontSans: Config.fonts.sans || "Inter"
	readonly property string fontHeading: Config.fonts.heading || fontSans
	readonly property string fontMono: Config.fonts.mono || "JetBrainsMono Nerd Font"
	readonly property string fontBar: Config.fonts.bar || fontMono
	readonly property int barWeight: Config.fonts.barWeight || Font.DemiBold
	// every text asks for full hinting: Qt on Wayland ignores fontconfig's (slight), and the shell's
	// windows get no subpixel smoothing, so small text looked soft; full snaps stems to whole pixels
	readonly property int hinting: Font.PreferFullHinting
	// body text a step heavier than regular: Qt blends text linearly (kitty boosts its contrast), so
	// regular strokes at 12-14 px read thin and faint beside the terminal; headings set their own
	readonly property int textWeight: Config.fonts.weight || Font.Medium
	// Text sizes scale with textScale to match the desktop: the terminal is 14 pt (about 19 px), GTK
	// apps Inter 11 at 125%. The bar's own text follows the bar's height instead.
	readonly property real textScale: Config.fonts.scale ?? 1.15
	// Motion: three speeds and one curve (quick off the mark, settling gently, as macOS moves) for every
	// animation: quick for hovers and presses, normal for fades and panels, slow for the lock and pictures
	readonly property int quick: 120
	readonly property int normal: 220
	readonly property int slow: 400
	readonly property int curve: Easing.OutCubic

	readonly property int textCaption: px(12)
	readonly property int textLabel: px(13)
	readonly property int textBody: px(14)

	function px(size: real): int {
		return Math.round(size * textScale);
	}
	readonly property int fontSize: Math.round(Config.bar.size * 0.4) // 16 px at a 40 px bar
	// capsules sit this far inside the bar on every side, so their round ends run parallel to the
	// island's: a capsule's radius is the bar's less this gap
	readonly property int barInset: Math.round(Config.bar.size * 0.15)
	readonly property int iconSize: fontSize + 4

	FileView {
		id: file

		path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/desktop/theme/palette.json"
		watchChanges: true
		onFileChanged: reload()
		onLoaded: {
			root.palette = JSON.parse(text());
			root.fades = true;
		}
	}

	IpcHandler {
		target: "theme"

		function reload(): void {
			file.reload();
		}
	}
}
