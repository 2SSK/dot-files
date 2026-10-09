import QtQuick
import Quickshell
import qs

// The bar's three parts: start (left or top), centre, end (right or bottom).
Item {
	id: root

	required property ShellScreen screen
	readonly property bool vertical: Config.vertical
	// capsules: the same gap at the ends as above and below them; else room for the round ends
	readonly property int pad: Config.bar.capsules ? Theme.barInset : Config.island ? Math.round(Config.bar.size / 2.5) : 8
	readonly property real gap: 40 // at least this between the centre and either side
	// what the parts need along the bar: the centre stays centred, so the longer side counts twice
	readonly property real naturalLength: vertical ? 2 * (pad + gap + Math.max(start.height, end.height)) + center.height : 2 * (pad + gap + Math.max(start.width, end.width)) + center.width

	Section {
		id: start

		names: Config.bar.left
		screen: root.screen
		x: root.vertical ? (root.width - width) / 2 : root.pad
		y: root.vertical ? root.pad : (root.height - height) / 2
	}

	Section {
		id: center

		names: Config.bar.center
		screen: root.screen
		x: (root.width - width) / 2
		y: (root.height - height) / 2
	}

	Section {
		id: end

		names: Config.bar.right
		screen: root.screen
		x: root.vertical ? (root.width - width) / 2 : root.width - width - root.pad
		y: root.vertical ? root.height - height - root.pad : (root.height - height) / 2
	}
}
