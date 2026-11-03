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
	// a panel hanging from this bar (the control center, the launcher…): the island widens to it and
	// the two become one shape, square where they meet
	readonly property bool joined: Panel.hangingWidth > 0 && !vertical && (Panel.hangingScreen || WindowManager.focusedOutput) === modelData.name
	// a panel still folding away after it closed: the island keeps its width and shape until it's in
	readonly property bool held: Config.island && !vertical && Panel.heldWidth > 0 && Panel.heldScreen === modelData.name
	readonly property bool merged: joined || held
	// one shape with it (square where they meet, opaque, no outline there): on the island only once
	// the panel unfolds, so the island keeps its round ends while it widens
	readonly property bool attached: Config.island ? held : joined
	// the island is as long as what it holds, or the panel hanging from it
	readonly property real panelLength: joined ? Panel.hangingWidth : held ? Panel.heldWidth : 0
	readonly property real target: !Config.island ? edgeLength : Math.min(edgeLength - 2 * gap, Math.max(content.naturalLength, panelLength))
	// what's drawn. It follows what the island holds frame by frame (a workspace's dot grows in or
	// shrinks away with its own easing; a second animation chasing it made it stutter) and glides
	// only over a jump: a panel opening or closing, or the style changing
	property real length: target
	property real lastPanel: 0
	property bool lastIsland: Config.island

	onTargetChanged: {
		const jump = panelLength !== lastPanel || Config.island !== lastIsland;
		const opening = panelLength > lastPanel;
		lastPanel = panelLength;
		lastIsland = Config.island;
		if (!jump && !glide.running) {
			length = target;
			return;
		}
		glide.stop();
		glide.from = length;
		glide.to = target;
		glide.duration = opening ? 160 : Theme.normal;
		glide.start();
	}

	NumberAnimation {
		id: glide

		target: bar
		property: "length"
		easing.type: Easing.InOutCubic
		// it may have moved meanwhile (a dot that was still growing): end on where it is now
		onFinished: if (bar.length !== bar.target) bar.length = bar.target
	}

	screen: modelData
	anchors.top: position !== "bottom"
	anchors.bottom: position !== "top"
	anchors.left: position !== "right"
	anchors.right: position !== "left"
	// the static bar's inverse corners hang past it, in room the windows still get
	readonly property int corners: Config.island ? 0 : Theme.radiusCard
	implicitWidth: vertical ? (docked ? size + gap + corners : 1) : 0
	implicitHeight: vertical ? 0 : docked ? size + gap + corners : 1
	exclusiveZone: docked ? size + gap : 1
	color: "transparent"
	// the bar with its rounded ends (picom blurs only inside it), or the one-pixel edge while hidden
	mask: Region {
		item: bar.docked ? shape : edge
		radius: bar.docked && !bar.attached ? shape.radius : 0
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
		x: !bar.vertical ? (parent.width - width) / 2 : (bar.position === "left" ? bar.gap : 0) + away
		y: bar.vertical ? (parent.height - height) / 2 : (bar.position === "top" ? bar.gap : 0) + away
		radius: Config.island ? bar.size / 2 : 0

		Behavior on radius {
			NumberAnimation {
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}
		// square on the side a panel hangs from (the panel carries on from there)
		property real joinRadius: Config.island && bar.attached ? 0 : radius

		Behavior on joinRadius {
			NumberAnimation {
				duration: Theme.quick
				easing.type: Theme.curve
			}
		}
		bottomLeftRadius: bar.position === "top" ? joinRadius : radius
		bottomRightRadius: bar.position === "top" ? joinRadius : radius
		topLeftRadius: bar.position === "bottom" ? joinRadius : radius
		topRightRadius: bar.position === "bottom" ? joinRadius : radius
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
			bottomLeftRadius: parent.bottomLeftRadius
			bottomRightRadius: parent.bottomRightRadius
			topLeftRadius: parent.topLeftRadius
			topRightRadius: parent.topRightRadius
			color: "transparent"
			border.width: 1
			border.color: Qt.alpha(Theme.border, 0.6)
		}

		Item {
			id: outlineMask

			readonly property bool gap: bar.attached
			// the island's panel is as wide as it; the static bar's meets it with inverse corners
			readonly property real gapWidth: Config.island ? parent.width : Panel.hangingWidth + 2 * Panel.fillet
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
			opacity: Config.island ? 1 : 0
			visible: opacity > 0

			Behavior on opacity {
				NumberAnimation {
					duration: Theme.normal
					easing.type: Theme.curve
				}
			}

			source: outline
			maskEnabled: true
			maskSource: outlineMask
		}

		// static: inverse corners where the bar meets the screen's sides, as round as the windows'
		// (sway's corner_radius), so the screen below it has rounded corners too
		Repeater {
			model: [0, 1]

			delegate: Canvas {
				id: corner

				required property int modelData
				readonly property int r: Theme.radiusCard
				readonly property bool far: modelData === 1 // the right end, or the bottom one
				property color tint: shape.color

				width: r
				height: r
				x: bar.vertical ? (bar.position === "left" ? shape.width : -r) : far ? shape.width - r : 0
				y: bar.vertical ? (far ? shape.height - r : 0) : bar.position === "top" ? shape.height : -r
				opacity: Config.island ? 0 : 1
				visible: opacity > 0
				transform: Scale {
					origin.x: corner.r / 2
					origin.y: corner.r / 2
					xScale: (bar.vertical ? bar.position === "right" : corner.far) ? -1 : 1
					yScale: (bar.vertical ? corner.far : bar.position === "bottom") ? -1 : 1
				}

				Behavior on opacity {
					NumberAnimation {
						duration: Theme.normal
						easing.type: Theme.curve
					}
				}

				onTintChanged: requestPaint()
				// drawn for the left end under a top bar: the square, less a quarter circle
				onPaint: {
					const ctx = getContext("2d");
					ctx.reset();
					ctx.fillStyle = tint;
					ctx.beginPath();
					ctx.moveTo(0, 0);
					ctx.lineTo(r, 0);
					ctx.arc(r, r, r, -Math.PI / 2, Math.PI, true);
					ctx.closePath();
					ctx.fill();
				}
			}
		}

		BarContent {
			id: content

			anchors.fill: parent
			screen: bar.modelData

			// a new style lays the widgets out anew: they fade in as the bar takes its new shape
			Connections {
				target: Config

				function onIslandChanged(): void {
					content.opacity = 0;
					fadeIn.restart();
				}
			}

			NumberAnimation {
				id: fadeIn

				target: content
				property: "opacity"
				to: 1
				duration: Theme.slow
				easing.type: Theme.curve
			}
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

	Toasts {
		bar: bar
	}

	AlarmCard {
		bar: bar
		island: shape
	}
}
