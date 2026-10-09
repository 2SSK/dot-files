import QtQuick
import Quickshell
import qs

// The bar's three parts: start (left or top), centre, end (right or bottom).
Item {
	id: root

	required property ShellScreen screen
	readonly property bool vertical: Config.vertical
	readonly property int pad: Config.island ? Math.round(Config.bar.size / 2.5) : 8
	// what the parts need along the bar, with room between them
	readonly property real naturalLength: 2 * pad + 64 + (vertical ? start.height + center.height + end.height : start.width + center.width + end.width)

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
