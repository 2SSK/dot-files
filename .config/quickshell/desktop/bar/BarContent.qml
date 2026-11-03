import QtQuick
import Quickshell
import qs
import qs.services

// The bar's three parts: start (left or top), centre, end (right or bottom), as shell.json names them
// for the island; the static bar puts the status first, the workspaces in the middle, the clock
// last. With pills the island's two sides are as long as the longer one, so the centre sits in the
// middle of the screen; without them the parts sit side by side, every gap the same. They stay
// together while the island is wider (a panel hanging from it); a CPU, memory or heat warning takes
// the end's place there, as the island never grows for it.
Item {
	id: root

	required property ShellScreen screen
	readonly property bool vertical: Config.vertical
	readonly property bool pill: Config.island && Config.bar.capsules
	// capsules: the same gap at the ends as above and below them; else room for the round ends
	readonly property int pad: Config.bar.capsules ? Theme.barInset : Config.island ? Math.round(Config.bar.size / 3) : 8
	readonly property real gap: pill ? Theme.barInset : Config.island ? 18 : 40 // between the centre and either side
	// the island's pills are as long as each other, the clock in the very middle; without pills that
	// padding would only show as a gap, so the parts sit side by side, every gap the same
	readonly property bool packed: Config.island && !pill
	readonly property real side: Math.max(start.natural, end.natural)
	readonly property var parts: [start.natural, center.natural, end.natural].filter(n => n > 0)
	readonly property real naturalLength: packed ? 2 * pad + parts.reduce((a, b) => a + b, 0) + Math.max(0, parts.length - 1) * gap : 2 * (pad + side) + (center.natural > 0 ? center.natural + 2 * gap : gap)
	readonly property real along: vertical ? height : width
	// where the start sits: the island keeps its parts together in the middle
	readonly property real from: Config.island ? Math.max(pad, (along - naturalLength) / 2 + pad) : pad
	readonly property real centerAt: from + (start.natural > 0 ? start.natural + gap : 0) // packed only
	readonly property real endAt: centerAt + (center.natural > 0 ? center.natural + gap : 0)

	readonly property string hot: Config.island ? Stats.hot : ""
	// the static bar arranges the same widgets its own way: the status first (the right part's, then
	// the left's), the workspaces in the middle, the clock (the centre part) at the end
	readonly property var startNames: Config.island ? Config.bar.left : Config.bar.right.concat(Config.bar.left).filter(n => n !== "workspaces" && !Config.bar.center.includes(n))
	readonly property var centerNames: Config.island ? Config.bar.center : Config.bar.left.concat(Config.bar.right).filter(n => n === "workspaces")
	readonly property var endNames: Config.island ? Config.bar.right : Config.bar.center.filter(n => n !== "workspaces")

	Section {
		id: start

		names: root.startNames
		screen: root.screen
		length: Config.island && !root.packed ? root.side : 0
		x: root.vertical ? (root.width - width) / 2 : root.from
		y: root.vertical ? root.from : (root.height - height) / 2
	}

	Section {
		id: center

		names: root.centerNames
		screen: root.screen
		x: root.packed && !root.vertical ? root.centerAt : (root.width - width) / 2
		y: root.packed && root.vertical ? root.centerAt : (root.height - height) / 2
	}

	Section {
		id: end

		names: root.endNames
		screen: root.screen
		length: Config.island && !root.packed ? root.side : 0
		alertGlyph: ({ cpu: Icons.g("gauge"), mem: Icons.g("cpu"), temp: Icons.g("flame") })[root.hot] ?? ""
		alertText: ({ cpu: Math.round(Stats.cpu * 100) + "%", mem: Math.round(Stats.mem * 100) + "%", temp: Math.round(Stats.temp) + (root.vertical ? "°" : "°C") })[root.hot] ?? ""
		alertCrit: root.hot === "temp"
		x: root.vertical ? (root.width - width) / 2 : root.packed ? root.endAt : root.width - width - root.from
		y: root.vertical ? (root.packed ? root.endAt : root.height - height - root.from) : (root.height - height) / 2

		TapHandler {
			enabled: root.hot !== ""
			onTapped: Panel.toggleControl("system")
		}
	}
}
