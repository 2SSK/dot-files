import QtQuick
import QtQuick.Effects
import Quickshell
import qs
import qs.services

// One screen's bar on any edge, an island or the whole edge. The window is only as big as the bar, as
// i3 reserves a dock's full window; hidden, it shrinks to a pixel so i3 gives the room back.
PanelWindow {
	id: bar

	required property ShellScreen modelData

	readonly property string position: Config.position
	readonly property bool vertical: Config.vertical
	readonly property int size: Config.bar.size
	readonly property int gap: Config.island ? 6 : 0 // the island's distance from the screen edge
	readonly property real edgeLength: (vertical ? modelData?.height : modelData?.width) ?? 0 // 0 as its screen goes away
	property bool docked: true // the window at full size; false only once the bar has slid away
	// the island's share of the edge, more of a narrow screen, between its content and the whole edge
	readonly property real share: Config.bar.length > 0 ? Config.bar.length : edgeLength < 1500 ? 0.8 : edgeLength < 2200 ? 0.55 : 0.42
	readonly property real length: !Config.island ? edgeLength : Math.min(edgeLength - 2 * gap, Math.max(content.naturalLength, share * edgeLength))

	screen: modelData
	anchors.top: position !== "bottom"
	anchors.bottom: position !== "top"
	anchors.left: position !== "right"
	anchors.right: position !== "left"
	implicitWidth: vertical ? (docked ? size + gap : 1) : 0
	implicitHeight: vertical ? 0 : docked ? size + gap : 1
	color: "transparent"
	// the bar with its rounded ends (picom blurs only inside it), or the one-pixel edge while hidden
	mask: Region {
		item: bar.docked ? shape : edge
		radius: bar.docked ? shape.radius : 0
	}

	MouseArea {
		id: edge

		anchors.fill: parent
		enabled: !bar.docked
		hoverEnabled: true
		onEntered: Panel.peek = true
	}

	// where the bar is, for the control center to hang from
	readonly property rect island: Qt.rect(shape.x + (anchors.right && !anchors.left ? (modelData?.width ?? 0) - width : 0), shape.y + (anchors.bottom && !anchors.top ? (modelData?.height ?? 0) - height : 0), shape.width, shape.height)
	onIslandChanged: Panel.islands = Object.assign({}, Panel.islands, { [modelData.name]: island })
	Component.onCompleted: Panel.islands = Object.assign({}, Panel.islands, { [modelData.name]: island })

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

		// the island's outline, with a gap where the open control center meets the bar
		Rectangle {
			id: outline

			anchors.fill: parent
			visible: false
			layer.enabled: true
			radius: parent.radius
			color: "transparent"
			border.width: 1
			border.color: Qt.alpha(Theme.border, 0.6)
		}

		Item {
			id: outlineMask

			readonly property bool gap: Panel.hangingWidth > 0 && !bar.vertical && (Panel.hangingScreen || WindowManager.focusedOutput) === bar.modelData.name
			readonly property real gapWidth: Panel.hangingWidth + 2 * Panel.fillet
			readonly property real gapX: (parent.width - gapWidth) / 2

			anchors.fill: parent
			visible: false
			layer.enabled: true

			// everything but the panel's stretch of the edge it hangs from
			Rectangle {
				width: parent.width
				height: parent.height
				visible: !outlineMask.gap
			}

			Rectangle {
				visible: outlineMask.gap
				width: outlineMask.gapX
				height: parent.height
			}

			Rectangle {
				visible: outlineMask.gap
				x: outlineMask.gapX + outlineMask.gapWidth
				width: parent.width - x
				height: parent.height
			}

			Rectangle {
				visible: outlineMask.gap
				x: outlineMask.gapX
				y: bar.position === "bottom" ? 2 : 0
				width: outlineMask.gapWidth
				height: parent.height - 2
			}
		}

		MultiEffect {
			anchors.fill: parent
			visible: Config.island
			source: outline
			maskEnabled: true
			maskSource: outlineMask
		}

		BarContent {
			id: content

			anchors.fill: parent
			screen: bar.modelData
		}
	}

	PowerMenu {
		bar: bar
		island: shape
	}

	Peek {
		bar: bar
		island: shape
	}

	Switcher {
		bar: bar
	}

	Osd {
		bar: bar
	}

	Toasts {
		bar: bar
	}

	AlarmCard {
		bar: bar
		island: shape
	}
}
