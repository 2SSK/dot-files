import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.I3
import qs

// The island growing into the OSD or the power menu, on the focused screen. A popup lies exactly
// over the bar: on an island it starts as the same pill (bar content included) and grows away from
// the edge; on a static bar a card slides out of it. The popup is bigger than the shape and lets
// clicks through everywhere else.
PopupWindow {
	id: root

	required property PanelWindow bar
	required property Item island

	readonly property bool vertical: Config.vertical
	readonly property string position: Config.position
	readonly property int size: Config.bar.size
	readonly property bool open: Panel.view !== "" && I3.focusedMonitor?.name === bar.screen?.name
	// on a shown island the shape starts as the pill itself; otherwise it's a card from the edge
	readonly property bool pill: Config.island && Panel.barShown
	property string view: "" // stays set while closing, so the content doesn't vanish mid-animation

	// along = the bar's direction, across = away from the edge
	readonly property real islandAlong: vertical ? island.height : island.width
	readonly property real viewAlong: (vertical ? loader.implicitHeight : loader.implicitWidth) + 40
	readonly property real viewAcross: (vertical ? loader.implicitWidth : loader.implicitHeight) + 24
	readonly property real openAlong: pill ? Math.max(islandAlong, viewAlong) : viewAlong
	readonly property real openAcross: (pill ? size : 0) + viewAcross
	readonly property real closedAlong: pill ? islandAlong : viewAlong
	readonly property real closedAcross: pill ? size : 0
	// from the screen edge to the shape: the island's gap, or just past a shown static bar
	readonly property real edge: Config.island ? bar.gap : Panel.barShown ? size : 0
	readonly property int pad: 32 // room for the shadow

	onOpenChanged: {
		if (open) {
			view = Panel.view;
			visible = true;
		} else {
			hide.restart();
		}
	}

	Connections {
		target: Panel

		function onViewChanged(): void {
			if (Panel.view !== "")
				root.view = Panel.view;
		}
	}

	Timer {
		id: hide

		interval: 380
		onTriggered: if (!root.open) root.visible = false
	}

	anchor.window: bar
	anchor.rect.x: position === "left" ? 0 : position === "right" ? bar.width - implicitWidth : island.x + island.width / 2 - implicitWidth / 2
	anchor.rect.y: position === "top" ? 0 : position === "bottom" ? bar.height - implicitHeight : island.y + island.height / 2 - implicitHeight / 2
	implicitWidth: vertical ? edge + openAcross + pad : Math.max(openAlong, islandAlong) + 2 * pad
	implicitHeight: vertical ? Math.max(openAlong, islandAlong) + 2 * pad : edge + openAcross + pad
	visible: false
	color: "transparent"
	mask: Region {
		item: shape
	}

	RectangularShadow {
		anchors.fill: shape
		radius: shape.radius
		blur: 28
		spread: 0
		offset.y: 4
		color: Qt.alpha("black", 0.45)
		opacity: root.open ? 1 : 0

		Behavior on opacity {
			NumberAnimation {
				duration: 200
			}
		}
	}

	Rectangle {
		id: shape

		readonly property real along: root.open ? root.openAlong : root.closedAlong
		readonly property real across: root.open ? root.openAcross : root.closedAcross

		width: root.vertical ? across : along
		height: root.vertical ? along : across
		x: root.position === "left" ? root.edge : root.position === "right" ? parent.width - root.edge - width : (parent.width - width) / 2
		y: root.position === "top" ? root.edge : root.position === "bottom" ? parent.height - root.edge - height : (parent.height - height) / 2
		clip: true
		color: Qt.alpha(Theme.bg, Config.island ? Math.max(Config.bar.opacity, 0.92) : 0.96)
		border.width: 1
		border.color: Qt.alpha(Theme.border, 0.6)
		// island: the pill's ends round off the open card; static: only the corners away from the edge
		radius: Config.island ? (root.open || !root.pill ? 22 : size / 2) : 0
		topLeftRadius: Config.island ? radius : (root.position === "bottom" || root.position === "right" ? 16 : 0)
		topRightRadius: Config.island ? radius : (root.position === "bottom" || root.position === "left" ? 16 : 0)
		bottomLeftRadius: Config.island ? radius : (root.position === "top" || root.position === "right" ? 16 : 0)
		bottomRightRadius: Config.island ? radius : (root.position === "top" || root.position === "left" ? 16 : 0)

		Behavior on width {
			NumberAnimation {
				duration: 360
				easing.type: Easing.OutBack
				easing.overshoot: 0.9
			}
		}

		Behavior on height {
			NumberAnimation {
				duration: 360
				easing.type: Easing.OutBack
				easing.overshoot: 0.9
			}
		}

		Behavior on radius {
			NumberAnimation {
				duration: 300
			}
		}

		// on an island the bar stays in place inside the growing shape
		BarContent {
			visible: root.pill
			screen: root.bar.screen
			width: root.island.width
			height: root.island.height
			x: root.position === "right" ? parent.width - width : root.vertical ? 0 : (parent.width - width) / 2
			y: root.position === "bottom" ? parent.height - height : !root.vertical ? 0 : (parent.height - height) / 2
		}

		Loader {
			id: loader

			readonly property real offset: root.pill ? root.size : 0

			x: root.position === "left" ? loader.offset + 12 : root.position === "right" ? parent.width - loader.offset - 12 - width : (parent.width - width) / 2
			y: root.position === "top" ? loader.offset + 12 : root.position === "bottom" ? parent.height - loader.offset - 12 - height : (parent.height - height) / 2
			opacity: root.open ? 1 : 0
			sourceComponent: root.view === "power" ? power : osd

			Behavior on opacity {
				NumberAnimation {
					duration: root.open ? 260 : 120
				}
			}
		}
	}

	Component {
		id: osd

		OsdView {}
	}

	Component {
		id: power

		PowerView {}
	}
}
