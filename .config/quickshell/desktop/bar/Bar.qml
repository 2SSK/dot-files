import QtQuick
import Quickshell
import qs

// One screen's bar, on any edge. Island: a rounded pill floating off the edge, waybar-like. Static:
// the whole edge, polybar-like. i3 reserves a dock's full window, so the window is only as big as
// the bar; what the island grows into (OSD, power menu) is the Expansion popup over the windows.
// Hidden (Panel.barShown), the bar slides off the edge and the window shrinks to a pixel, so i3
// gives the room back while the popups still have a window to hang from; the pointer at that edge
// brings the bar back over the windows for a moment (Peek).
PanelWindow {
	id: bar

	required property ShellScreen modelData

	readonly property string position: Config.position
	readonly property bool vertical: Config.vertical
	readonly property int size: Config.bar.size
	readonly property int gap: Config.island ? 6 : 0 // the island's distance from the screen edge
	readonly property real edgeLength: vertical ? modelData.height : modelData.width
	property bool docked: true // the window at full size; false only once the bar has slid away
	readonly property real length: !Config.island ? edgeLength : Math.min(edgeLength - 2 * gap, Math.max(content.naturalLength, Config.bar.length * edgeLength))

	screen: modelData
	anchors.top: position !== "bottom"
	anchors.bottom: position !== "top"
	anchors.left: position !== "right"
	anchors.right: position !== "left"
	implicitWidth: vertical ? (docked ? size + gap : 1) : 0
	implicitHeight: vertical ? 0 : docked ? size + gap : 1
	color: "transparent"
	mask: Region {
		item: bar.docked ? shape : edge
	}

	// the one-pixel edge left while hidden
	MouseArea {
		id: edge

		anchors.fill: parent
		enabled: !bar.docked
		hoverEnabled: true
		onEntered: Panel.peek = true
	}

	Connections {
		target: Panel

		function onBarShownChanged(): void {
			if (Panel.barShown)
				bar.docked = true;
			else
				undock.restart();
		}
	}

	Timer {
		id: undock

		interval: 280
		onTriggered: if (!Panel.barShown) bar.docked = false
	}

	Rectangle {
		id: shape

		// off the edge while hidden
		readonly property real away: Panel.barShown ? 0 : (bar.size + bar.gap + 8) * (bar.position === "top" || bar.position === "left" ? -1 : 1)

		opacity: Panel.barShown ? 1 : 0

		Behavior on x {
			enabled: bar.vertical
			NumberAnimation {
				duration: 260
				easing.type: Easing.OutCubic
			}
		}

		Behavior on y {
			enabled: !bar.vertical
			NumberAnimation {
				duration: 260
				easing.type: Easing.OutCubic
			}
		}

		Behavior on opacity {
			NumberAnimation {
				duration: 220
			}
		}

		width: bar.vertical ? bar.size : bar.length
		height: bar.vertical ? bar.length : bar.size
		// slid by x/y while hiding, not a transform: the window's shape follows geometry
		x: !bar.vertical ? (parent.width - width) / 2 : (bar.position === "left" ? bar.gap : 0) + away
		y: bar.vertical ? (parent.height - height) / 2 : (bar.position === "top" ? bar.gap : 0) + away
		radius: Config.island ? bar.size / 2 : 0
		color: Qt.alpha(Theme.bg, Config.bar.opacity)
		border.width: Config.island ? 1 : 0
		border.color: Qt.alpha(Theme.border, 0.6)

		BarContent {
			id: content

			anchors.fill: parent
			screen: bar.modelData
		}
	}

	Expansion {
		bar: bar
		island: shape
	}

	Peek {
		bar: bar
		island: shape
	}

	Osd {
		bar: bar
	}
}
