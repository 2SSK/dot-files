import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs
import qs.services

// One screen's bar on any edge, an island or the whole edge. The window is only as big as the bar, as
// i3 reserves a dock's full window; on sway an island's window is the island itself, so SwayFX
// shadows it as it does windows (effects.conf); hidden, it shrinks to a pixel so i3 gives the room back.
PanelWindow {
	id: bar

	required property ShellScreen modelData

	readonly property string position: Config.position
	readonly property bool vertical: Config.vertical
	readonly property int size: Config.bar.size
	readonly property int gap: Config.island ? 6 : 0 // the island's distance from the screen edge
	// on sway, a docked island's window is just the island, its gap a margin
	readonly property bool compact: Config.wayland && Config.island && docked
	readonly property real edgeLength: (vertical ? modelData?.height : modelData?.width) ?? 0 // 0 as its screen goes away
	property bool docked: true // the window at full size; false only once the bar has slid away
	// the island's share of the edge, more of a narrow screen, between its content and the whole edge
	readonly property real share: Config.bar.length > 0 ? Config.bar.length : edgeLength < 1500 ? 0.8 : edgeLength < 2200 ? 0.55 : 0.42
	readonly property real length: !Config.island ? edgeLength : Math.min(edgeLength - 2 * gap, Math.max(content.naturalLength, share * edgeLength))

	screen: modelData
	anchors.top: position === "top" || vertical && !compact
	anchors.bottom: position === "bottom" || vertical && !compact
	anchors.left: position === "left" || !vertical && !compact
	anchors.right: position === "right" || !vertical && !compact
	margins.top: compact && position === "top" ? gap : 0
	margins.bottom: compact && position === "bottom" ? gap : 0
	margins.left: compact && position === "left" ? gap : 0
	margins.right: compact && position === "right" ? gap : 0
	implicitWidth: vertical ? (docked ? size + (compact ? 0 : gap) : 1) : compact ? length : 0
	implicitHeight: vertical ? (compact ? length : 0) : docked ? size + (compact ? 0 : gap) : 1
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
	readonly property rect island: Qt.rect(shape.x + (anchors.left ? margins.left : anchors.right ? (modelData?.width ?? 0) - width - margins.right : ((modelData?.width ?? 0) - width) / 2), shape.y + (anchors.top ? margins.top : anchors.bottom ? (modelData?.height ?? 0) - height - margins.bottom : ((modelData?.height ?? 0) - height) / 2), shape.width, shape.height)
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

	// SwayFX shadows the bar as it does windows (effects.conf): its corners, so the shadow follows the
	// island's round ends, or the static bar's square ones (plain sway refuses it, which is fine)
	Process {
		running: Config.wayland
		command: ["swaymsg", "-q", `layer_effects quickshell "blur enable; blur_ignore_transparent enable; shadows enable; corner_radius ${Config.island ? Math.round(Config.bar.size / 2) : 0}"`]
		onCommandChanged: if (Config.wayland) running = true
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
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}

		Behavior on y {
			enabled: !bar.vertical
			NumberAnimation {
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}

		Behavior on opacity {
			NumberAnimation {
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}

		width: bar.vertical ? bar.size : bar.length
		height: bar.vertical ? bar.length : bar.size
		// slid by x/y while hiding, not a transform: the window's shape follows geometry
		x: !bar.vertical ? (parent.width - width) / 2 : (bar.position === "left" && !bar.compact ? bar.gap : 0) + away
		y: bar.vertical ? (parent.height - height) / 2 : (bar.position === "top" && !bar.compact ? bar.gap : 0) + away
		radius: Config.island ? bar.size / 2 : 0
		// opaque while a panel hangs from it, as the panel is: one piece in one colour (see-through, each
		// would show whatever is behind it, the wallpaper here and a window there)
		color: Qt.alpha(Theme.bg, outlineMask.gap ? 1 : Config.bar.opacity)

		Behavior on color {
			ColorAnimation {
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}

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
