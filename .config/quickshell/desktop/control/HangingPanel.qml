pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

// A panel that hangs from the middle of the bar, in its colour, joined to it by inverse curves
// (the bar opens its outline there: Panel.hangingWidth). It is drawn in a window as big as the
// screen, so a click beside the panel lands on it and closes it, and it shows at once, without
// animation. Escape, a click beside it, or (X11) another window's focus asks to close (dismissed).
// The control center, clipboard, launcher, wallpaper, capture and password panels use it.
//
// The window depends on the session. Wayland (sway): a layer surface over the screen with the
// keyboard to itself, placed exactly, no window rules. X11 (i3): a real window, as X11 popups can't
// take the keyboard; unshaped, so the pointer never leaves it and i3's focus-follows-mouse can't
// hand the focus back to the window below (a shaped one flickered as it opened). The panel's
// contents live in one item, moved into whichever window is made.
Scope {
	id: root

	required property string name // the X11 window's title is "Desktop <name>"
	property bool open
	property int panelWidth: 760
	property int panelHeight: 640
	property bool visible: true // as a window's: the panels' loaders set it
	default property alias content: inner.data
	signal dismissed
	signal keyPressed(var event) // keys nothing inside took; an Escape the panel doesn't take closes it

	readonly property bool wayland: !!Quickshell.env("WAYLAND_DISPLAY")
	// the screen it opened on, kept while it's open: focus moving to another monitor (on sway it
	// follows the pointer) doesn't carry it along
	readonly property ShellScreen focusedScreen: Quickshell.screens.find(s => s.name === WindowManager.focusedOutput) ?? Quickshell.screens[0]
	property ShellScreen pinned: null
	readonly property ShellScreen screen: pinned ?? focusedScreen
	readonly property bool below: Config.position !== "bottom" // hangs below the bar, else above it
	readonly property rect island: Panel.islands[screen.name] ?? Qt.rect(0, 0, screen.width, 0)
	// a bar on the left or right: the panel floats beside it, centred on it, kept on the screen
	readonly property bool side: Config.vertical
	readonly property int sideGap: 10
	// centred under the bar, flush with it (or beside a side bar)
	readonly property real px: side ? (Config.position === "left" ? island.x + island.width + sideGap : island.x - panelWidth - sideGap) : Math.round(island.x + (island.width - panelWidth) / 2)
	readonly property real py: side ? Math.round(Math.max(sideGap, Math.min(screen.height - panelHeight - sideGap, island.y + (island.height - panelHeight) / 2))) : !Panel.barShown ? (below ? 0 : screen.height - panelHeight) : below ? island.y + island.height : island.y - panelHeight
	// the curves where it joins a horizontal bar; none beside a side bar, which it doesn't touch
	readonly property int fillet: side ? 0 : Panel.controlFillet
	// the bar's colour and see-through as much, so the panel reads as part of it: on sway SwayFX blurs
	// behind it as behind the bar (effects.conf, desktop-panel). X11: solid, as nothing is blurred
	// behind a window as big as the screen and what's under would show through
	readonly property color fill: wayland ? Qt.alpha(Theme.bg, Config.bar.opacity) : Theme.bg
	readonly property string title: "Desktop " + name

	// the keyboard (X11): i3 focuses a new window itself; ask too once it has the window (its "new"
	// event below), and again shortly in case that came first
	function takeFocus(): void {
		if (!wayland)
			WindowManager.command(`[title="^${root.title}$"] focus`);
	}

	Timer {
		running: !root.wayland
		interval: 250
		onTriggered: root.takeFocus()
	}

	ElapsedTimer {
		id: opened
	}

	Component.onCompleted: {
		pinned = focusedScreen;
		Panel.hangingScreen = pinned.name; // the bar there opens its outline for it
	}
	Component.onDestruction: if (Panel.hangingScreen === pinned?.name) Panel.hangingScreen = ""

	// i3's window events: focus once it has the window; another window taking the focus closes it
	Connections {
		target: WindowManager
		enabled: !root.wayland

		function onWindowEvent(data: var): void {
			const name = data.container?.name ?? "";
			if (data.change === "new" && name === root.title)
				root.takeFocus();
			else if (data.change === "focus" && name && name !== root.title && opened.elapsed() > 600)
				root.dismissed();
		}
	}

	// what the panels put in: moved into the window's card once that exists. A focus scope, so the
	// focus the panel gave a field as it was made (a search, a password) comes back with it
	FocusScope {
		id: inner

		focus: true
		// the panel first: Keys' own onEscapePressed would run before it and take every Escape
		Keys.onPressed: event => {
			root.keyPressed(event);
			if (!event.accepted && event.key === Qt.Key_Escape) {
				root.dismissed();
				event.accepted = true;
			}
		}
	}

	// the panel under the bar, its curves, and the area beside it that closes it on a click
	component Layout: Item {
		anchors.fill: parent

		Component.onCompleted: {
			inner.parent = holder;
			inner.anchors.fill = holder;
			inner.forceActiveFocus();
		}

		MouseArea {
			anchors.fill: parent
			acceptedButtons: Qt.AllButtons
			onPressed: root.dismissed()
		}

		Item {
			x: root.px - root.fillet
			y: root.py
			width: root.panelWidth + 2 * root.fillet
			height: root.panelHeight
			visible: root.open

			// inverse curves where the panel meets the bar, so the bar's edge flows into it
			Repeater {
				model: root.side ? [] : [-1, 1] // left, right (none beside a side bar)

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
					// drawn for the right side under a top bar: the corner where the panel's edge
					// (x 0) meets the bar (y 0), filled up to a quarter circle one radius out from it
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
				x: root.fillet
				width: root.panelWidth
				height: root.panelHeight
				color: root.fill
				topLeftRadius: root.below && !root.side ? 0 : 18
				topRightRadius: root.below && !root.side ? 0 : 18
				bottomLeftRadius: root.below || root.side ? 18 : 0
				bottomRightRadius: root.below || root.side ? 18 : 0
				clip: true

				// clicks on the panel's own empty space stay on it (not the closing area behind)
				MouseArea {
					anchors.fill: parent
					acceptedButtons: Qt.AllButtons
				}

				Item {
					id: holder

					anchors.fill: parent
				}
			}
		}
	}

	// Wayland: a layer surface over the whole screen, with the keyboard to itself
	LazyLoader {
		active: root.wayland && root.visible

		PanelWindow {
			screen: root.screen
			anchors {
				top: true
				bottom: true
				left: true
				right: true
			}
			exclusionMode: ExclusionMode.Ignore
			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
			WlrLayershell.namespace: "desktop-panel"
			color: "transparent"

			Layout {}
		}
	}

	// X11: a window as big as the screen (look.conf floats it at the screen's corner)
	LazyLoader {
		active: !root.wayland && root.visible

		FloatingWindow {
			title: root.title
			implicitWidth: root.screen.width
			implicitHeight: root.screen.height
			// a fixed size: i3 floats such a window as it takes it, instead of tiling it for a
			// moment first (which flashed the other windows' borders and layout)
			minimumSize: Qt.size(root.screen.width, root.screen.height)
			maximumSize: Qt.size(root.screen.width, root.screen.height)
			color: "transparent"
			onVisibleChanged: if (!visible) root.dismissed()

			Layout {}
		}
	}
}
