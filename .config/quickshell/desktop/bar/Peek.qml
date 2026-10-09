import QtQuick
import Quickshell
import qs

// The hidden bar, back over the windows while the pointer stays on it (Panel.peek); it slides away
// a moment after the pointer leaves. i3 keeps the windows where they are.
PopupWindow {
	id: root

	required property PanelWindow bar
	required property Item island

	readonly property bool open: Panel.peek && !Panel.barShown
	readonly property string position: Config.position
	readonly property bool vertical: Config.vertical
	readonly property real reach: Config.bar.size + (Config.island ? 6 : 0) + 24 // bar, gap, shadow room

	// mapped while open (see Osd)
	property bool shown: false

	onOpenChanged: {
		if (open) {
			shown = true;
			leave.restart(); // goes again unless the pointer comes onto it
		} else {
			hide.restart();
		}
	}

	Timer {
		id: hide

		interval: 300
		onTriggered: if (!root.open) root.shown = false
	}

	Timer {
		id: leave

		interval: 700
		onTriggered: Panel.peek = false
	}

	anchor.window: bar
	anchor.rect.x: position === "right" ? bar.width - implicitWidth : 0
	anchor.rect.y: position === "bottom" ? bar.height - implicitHeight : 0
	implicitWidth: vertical ? reach : bar.width
	implicitHeight: vertical ? bar.height : reach
	visible: shown
	color: "transparent"
	mask: Region {
		item: zone
	}

	// the bar and the strip between it and the screen edge, where the pointer arrived: hovering
	// anywhere here keeps the bar out
	Item {
		id: zone

		x: root.vertical ? (root.position === "left" ? 0 : replica.x) : replica.x
		y: root.vertical ? replica.y : (root.position === "top" ? 0 : replica.y)
		width: root.vertical ? (root.position === "left" ? replica.x + replica.width : parent.width - replica.x) : replica.width
		height: root.vertical ? replica.height : (root.position === "top" ? replica.y + replica.height : parent.height - replica.y)

		HoverHandler {
			onHoveredChanged: hovered ? leave.stop() : leave.restart()
		}
	}

	Rectangle {
		id: replica

		readonly property real away: root.open ? 0 : (root.reach + 8) * (root.position === "top" || root.position === "left" ? -1 : 1)

		width: root.island.width
		height: root.island.height
		// slid by x/y, not a transform: the window's shape follows geometry
		x: (root.position === "right" ? parent.width - width - (Config.island ? 6 : 0) : root.position === "left" ? (Config.island ? 6 : 0) : root.island.x) + (root.vertical ? away : 0)
		y: (root.position === "bottom" ? parent.height - height - (Config.island ? 6 : 0) : root.position === "top" ? (Config.island ? 6 : 0) : root.island.y) + (root.vertical ? 0 : away)
		radius: root.island.radius
		color: root.island.color
		border.width: root.island.border.width
		border.color: root.island.border.color

		Behavior on x {
			NumberAnimation {
				duration: 240
				easing.type: Easing.OutCubic
			}
		}

		Behavior on y {
			NumberAnimation {
				duration: 240
				easing.type: Easing.OutCubic
			}
		}

		BarContent {
			anchors.fill: parent
			screen: root.bar.screen
		}
	}
}
