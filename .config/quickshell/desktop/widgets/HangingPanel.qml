pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

// A panel hanging from the middle of the bar, joined to it by inverse curves, drawn in a window as big
// as the screen so a click beside it lands there and closes it. The shell's dropdown panels use it.
Scope {
	id: root

	required property string name
	property bool open
	property int panelWidth: 760
	property int panelHeight: 640
	property bool visible: true // as a window's: the panels' loaders set it
	default property alias content: inner.data
	signal dismissed
	signal keyPressed(var event) // keys nothing inside took; an Escape the panel doesn't take closes it

	readonly property bool wayland: Config.wayland
	// pinned to the screen it opened on: focus moving to another monitor doesn't carry it along
	readonly property ShellScreen focusedScreen: Quickshell.screens.find(s => s.name === WindowManager.focusedOutput) ?? Quickshell.screens[0]
	property ShellScreen pinned: null
	readonly property ShellScreen screen: pinned ?? focusedScreen
	readonly property bool below: Config.position !== "bottom"
	readonly property rect island: Panel.islands[screen.name] ?? Qt.rect(0, 0, screen.width, 0)
	readonly property bool side: Config.vertical
	readonly property int sideGap: 10
	readonly property real px: side ? (Config.position === "left" ? island.x + island.width + sideGap : island.x - panelWidth - sideGap) : Math.round(island.x + (island.width - panelWidth) / 2)
	readonly property real py: side ? Math.round(Math.max(sideGap, Math.min(screen.height - panelHeight - sideGap, island.y + (island.height - panelHeight) / 2))) : !Panel.barShown ? (below ? 0 : screen.height - panelHeight) : below ? island.y + island.height : island.y - panelHeight
	readonly property int fillet: side ? 0 : Panel.fillet
	// opaque, and the bar it hangs from turns opaque with it (Bar.qml): one piece in one colour
	readonly property color fill: Theme.bg
	readonly property string title: "Desktop " + name

	// X11: i3 focuses a new window itself; ask too once it has it, and again shortly in case that came first
	function takeFocus(): void {
		if (!wayland)
			WindowManager.command(`[title="^${root.title}$"] focus`);
	}

	Timer {
		running: !root.wayland
		interval: 250
		onTriggered: root.takeFocus()
	}

	Component.onCompleted: {
		pinned = focusedScreen;
		Panel.hangingScreen = pinned.name; // the bar there opens its outline for it
	}
	Component.onDestruction: if (Panel.hangingScreen === pinned?.name) Panel.hangingScreen = ""

	FocusWatch {
		title: root.title
		active: !root.wayland
		onArrived: root.takeFocus()
		onFocusLost: root.dismissed()
	}

	// a focus scope, so the focus the panel gave a field as it was made comes back once it's moved
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

			Repeater {
				model: root.side ? [] : [-1, 1]

				delegate: Canvas {
					id: curve

					required property int modelData
					property color tint: root.fill

					x: modelData < 0 ? 0 : root.fillet + root.panelWidth
					y: root.below ? 0 : root.panelHeight - height
					width: root.fillet
					height: root.fillet
					transform: Scale {
						origin.x: curve.width / 2
						origin.y: curve.height / 2
						xScale: curve.modelData
						yScale: root.below ? 1 : -1
					}
					onTintChanged: requestPaint()
					// drawn for the right side under a top bar
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

	// Wayland: a layer surface, which takes the keyboard and is placed exactly without window rules
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

	// X11: a real window, as X11 popups can't take the keyboard; unshaped, so i3's focus-follows-mouse
	// can't hand the focus back to the window below. look.conf floats it at the screen's corner.
	LazyLoader {
		active: !root.wayland && root.visible

		FloatingWindow {
			title: root.title
			implicitWidth: root.screen.width
			implicitHeight: root.screen.height
			// a fixed size makes i3 float it at once instead of tiling it first (which flashed the layout)
			minimumSize: Qt.size(root.screen.width, root.screen.height)
			maximumSize: Qt.size(root.screen.width, root.screen.height)
			color: "transparent"
			onVisibleChanged: if (!visible) root.dismissed()

			Layout {}
		}
	}
}
