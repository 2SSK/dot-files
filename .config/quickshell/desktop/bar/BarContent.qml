import QtQuick
import Quickshell
import qs
import qs.services

// The bar's three parts: start (left or top), centre, end (right or bottom), as shell.json names them
// for the island; the static bar puts the status first, the workspaces in the middle, the clock
// last. On the island the two sides are as long as the longer one, so the centre sits in the middle
// of the screen, and they stay together round it while the island is wider (a panel hanging from
// it); a CPU, memory or heat warning takes the end's place there, as the island never grows for it.
Item {
	id: root

	required property ShellScreen screen
	readonly property bool vertical: Config.vertical
	readonly property bool pill: Config.island && Config.bar.capsules
	// capsules: the same gap at the ends as above and below them; else room for the round ends
	readonly property int pad: Config.bar.capsules ? Theme.barInset : Config.island ? Math.round(Config.bar.size / 3) : 8
	readonly property real gap: pill ? Theme.barInset : Config.island ? 16 : 40 // between the centre and either side
	readonly property real side: Math.max(start.natural, end.natural)
	readonly property real naturalLength: 2 * (pad + side) + (center.natural > 0 ? center.natural + 2 * gap : gap)
	readonly property real along: vertical ? height : width
	// where the start sits: the island keeps its parts together in the middle
	readonly property real from: Config.island ? Math.max(pad, (along - naturalLength) / 2 + pad) : pad

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
		length: Config.island ? root.side : 0
		x: root.vertical ? (root.width - width) / 2 : root.from
		y: root.vertical ? root.from : (root.height - height) / 2
	}

	Section {
		id: center

		names: root.centerNames
		screen: root.screen
		x: (root.width - width) / 2
		y: (root.height - height) / 2
	}

	Section {
		id: end

		names: root.endNames
		screen: root.screen
		length: Config.island ? root.side : 0
		alertGlyph: ({ cpu: Icons.g("gauge"), mem: Icons.g("cpu"), temp: Icons.g("flame") })[root.hot] ?? ""
		alertText: ({ cpu: Math.round(Stats.cpu * 100) + "%", mem: Math.round(Stats.mem * 100) + "%", temp: Math.round(Stats.temp) + (root.vertical ? "°" : "°C") })[root.hot] ?? ""
		alertCrit: root.hot === "temp"
		x: root.vertical ? (root.width - width) / 2 : root.width - width - root.from
		y: root.vertical ? root.height - height - root.from : (root.height - height) / 2

		TapHandler {
			enabled: root.hot !== ""
			onTapped: Panel.toggleControl("system")
		}
	}
}
