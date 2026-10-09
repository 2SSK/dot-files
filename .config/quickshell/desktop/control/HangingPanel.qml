pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.I3
import qs

// A panel that drops out of the middle of the bar, in its colour, joined to it by inverse curves
// (the bar opens its outline there: Panel.hangingWidth). The window is transparent and as big as
// the screen, so i3 can only put it at the screen's corner (look.conf) and the panel is drawn under
// the bar inside it; a click anywhere off the panel lands on the window. A real window, as X11
// popups can't take the keyboard. Escape, a click off it or another window's focus asks to close
// (dismissed). The control center and the clipboard are built on it.
FloatingWindow {
	id: root

	required property string name // the window's title is "Desktop <name>"
	property bool open
	property int panelWidth: 760
	property int panelHeight: 640
	default property alias content: inner.data
	signal dismissed
	signal keyPressed(var event) // keys nothing inside took (Escape closes)

	readonly property ShellScreen screen: Quickshell.screens.find(s => s.name === I3.focusedMonitor?.name) ?? Quickshell.screens[0]
	readonly property bool below: Config.position !== "bottom" // hangs below the bar, else above it
	readonly property rect island: Panel.islands[screen.name] ?? Qt.rect(0, 0, screen.width, 0)
	// centred under the bar, flush with it
	readonly property real px: Math.round(island.x + (island.width - panelWidth) / 2)
	readonly property real py: !Panel.barShown ? (below ? 0 : screen.height - panelHeight) : below ? island.y + island.height : island.y - panelHeight
	readonly property int fillet: Panel.controlFillet
	readonly property color fill: Qt.alpha(Theme.bg, Config.bar.opacity) // the bar's own colour
	property bool placed: false // mapped: the panel may drop in

	title: "Desktop " + name
	implicitWidth: screen.width
	implicitHeight: screen.height
	color: "transparent"
	onVisibleChanged: if (!visible) dismissed()

	// one frame to be mapped, then the panel drops
	Timer {
		running: true
		interval: 40
		onTriggered: root.placed = true
	}

	ElapsedTimer {
		id: opened
	}

	// another window taking the focus closes it, as a panel would
	I3IpcListener {
		subscriptions: ["window"]
		onIpcEvent: event => {
			const data = typeof event.data === "string" ? JSON.parse(event.data) : event.data;
			const name = data.container?.name ?? "";
			if (data.change === "focus" && name && name !== root.title && opened.elapsed() > 600)
				root.dismissed();
		}
	}

	// a click off the panel closes it
	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.AllButtons
		onPressed: root.dismissed()
	}

	// the panel's place under the bar (and room for its curves); the panel slides out of its edge
	Item {
		x: root.px - root.fillet
		y: root.py
		width: root.panelWidth + 2 * root.fillet
		height: root.panelHeight
		clip: true

		// inverse curves where the panel meets the bar, so the bar's edge flows into it
		Repeater {
			model: [-1, 1] // left, right

			delegate: Canvas {
				id: curve

				required property int modelData
				property color tint: root.fill

				// beside the panel's edge at the bar, following its slide (outside it: the panel clips)
				x: modelData < 0 ? 0 : root.fillet + root.panelWidth
				y: root.below ? card.y : card.y + card.height - height
				width: root.fillet
				height: root.fillet
				transform: Scale {
					origin.x: curve.width / 2
					origin.y: curve.height / 2
					xScale: curve.modelData // the left one is drawn mirrored
					yScale: root.below ? 1 : -1
				}
				onTintChanged: requestPaint()
				// drawn for the right side under a top bar: the corner where the panel's edge (x 0)
				// meets the bar (y 0), filled up to a quarter circle centred one radius out from it
				onPaint: {
					const ctx = getContext("2d");
					const r = width;
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

		Rectangle {
			id: card

			x: root.fillet
			width: root.panelWidth
			height: root.panelHeight
			y: root.placed && root.open ? 0 : root.below ? -height : height
			color: root.fill
			topLeftRadius: root.below ? 0 : 18
			topRightRadius: root.below ? 0 : 18
			bottomLeftRadius: root.below ? 18 : 0
			bottomRightRadius: root.below ? 18 : 0
			clip: true

			// clicks on the panel's own empty space stay on it (not the closing area behind)
			MouseArea {
				anchors.fill: parent
				acceptedButtons: Qt.AllButtons
			}

			Behavior on y {
				NumberAnimation {
					duration: root.open ? 260 : 200
					easing.type: root.open ? Easing.OutCubic : Easing.InCubic
				}
			}

			Item {
				id: inner

				anchors.fill: parent
				focus: true
				Keys.onEscapePressed: root.dismissed()
				Keys.onPressed: event => root.keyPressed(event)
			}
		}
	}
}
