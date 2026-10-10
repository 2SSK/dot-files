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
	readonly property color primaryText: ui.on_primary ?? "#1a1b26"
	readonly property color border: ui.border ?? "#3b4261"
	readonly property color error: ui.error ?? "#f7768e"
	readonly property color success: ui.success ?? "#9ece6a"
	readonly property color warning: ui.warning ?? "#e0af68"
	readonly property color secondary: ui.secondary ?? "#bb9af7"

	// the fonts and body weight, from Settings → Appearance → Fonts
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
	// Text sizes, all through textScale (Settings → Appearance → Text size) so the shell reads like
	// the rest of the desktop: the terminal is 14 pt (about 19 px), GTK apps Inter 11 at 125%. px(n)
	// scales a base size; the common ones are named: times and hints, buttons and chips, lists and
	// fields. The bar's own text follows the bar's height instead.
	readonly property real textScale: Config.fonts.scale ?? 1.15
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
		onLoaded: root.palette = JSON.parse(text())
	}

	IpcHandler {
		target: "theme"

		function reload(): void {
			file.reload();
		}
	}
}
