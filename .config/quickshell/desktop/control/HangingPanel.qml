pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services

// A panel that hangs from the middle of the bar, in its colour, joined to it by inverse curves
// (the bar opens its outline there: Panel.hangingWidth). The window is as big as the screen and
// unshaped: the pointer never leaves it, so i3's focus-follows-mouse can't hand the focus back to
// the window below (a shaped window flickered: focus went there and back as it opened), and a
// click beside the panel closes it. It shows at once, without animation. A real window, as X11
// popups can't take the keyboard. Escape, a click beside it, or another window's focus asks to
// close (dismissed). The control center, clipboard, launcher, wallpaper and capture panels use it.
FloatingWindow {
	id: root

	required property string name // the window's title is "Desktop <name>"
	property bool open
	property int panelWidth: 760
	property int panelHeight: 640
	default property alias content: inner.data
	signal dismissed
	signal keyPressed(var event) // keys nothing inside took (Escape closes)

	readonly property ShellScreen screen: Quickshell.screens.find(s => s.name === WindowManager.focusedOutput) ?? Quickshell.screens[0]
	readonly property bool below: Config.position !== "bottom" // hangs below the bar, else above it
	readonly property rect island: Panel.islands[screen.name] ?? Qt.rect(0, 0, screen.width, 0)
	// centred under the bar, flush with it
	readonly property real px: Math.round(island.x + (island.width - panelWidth) / 2)
	readonly property real py: !Panel.barShown ? (below ? 0 : screen.height - panelHeight) : below ? island.y + island.height : island.y - panelHeight
	readonly property int fillet: Panel.controlFillet
	// the bar's colour, but nearly solid: nothing is blurred behind an unshaped full-screen window
	readonly property color fill: Qt.alpha(Theme.bg, Math.max(Config.bar.opacity, 0.96))

	title: "Desktop " + name
	implicitWidth: screen.width
	implicitHeight: screen.height
	// a fixed size: i3 floats such a window as it takes it, instead of tiling it for a moment first
	// (which flashed the other windows' borders and layout)
	minimumSize: Qt.size(screen.width, screen.height)
	maximumSize: Qt.size(screen.width, screen.height)
	color: "transparent"
	onVisibleChanged: if (!visible) dismissed()

	// the keyboard: i3 focuses a new window itself; ask too once it has the window (its "new" event
	// below), and again shortly in case that came first
	function takeFocus(): void {
		WindowManager.command(`[title="^${root.title}$"] focus`);
	}

	Timer {
		running: true
		interval: 250
		onTriggered: root.takeFocus()
	}

	ElapsedTimer {
		id: opened
	}

	// i3's window events: focus once it has the window; another window taking the focus closes it
	Connections {
		target: WindowManager

		function onWindowEvent(data: var): void {
			const name = data.container?.name ?? "";
			if (data.change === "new" && name === root.title)
				root.takeFocus();
			else if (data.change === "focus" && name && name !== root.title && opened.elapsed() > 600)
				root.dismissed();
		}
	}

	// a click beside the panel closes it
	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.AllButtons
		onPressed: root.dismissed()
	}

	// the panel's place under the bar, and room for its curves
	Item {
		x: root.px - root.fillet
		y: root.py
		width: root.panelWidth + 2 * root.fillet
		height: root.panelHeight
		visible: root.open

		// inverse curves where the panel meets the bar, so the bar's edge flows into it
		Repeater {
			model: [-1, 1] // left, right

			delegate: Canvas {
				id: curve

				required property int modelData
				property color tint: root.fill

				// beside the panel's edge at the bar, where it joins it
				x: modelData < 0 ? 0 : root.fillet + root.panelWidth
				y: root.below ? 0 : root.panelHeight - height
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
			y: 0
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
