pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.services
import qs.widgets

// The window switcher (Alt+Tab): the open windows as rounded cards on a ring, most recent first.
// The ring turns to bring the next one to the front; cards further round shrink, fade and turn
// away. Releasing Alt switches to the front one, Escape cancels, a click picks one. A quick tap
// switches to the last window without showing the ring. The window manager's "switcher" mode
// steps it on Tab. Letting go of Alt: on i3 the shell watches X for it (desktop-key-release; its
// popup can't take the keyboard); on sway a layer surface takes the keyboard while switching (sway
// won't run a release binding after another key), so the release, Enter and Escape reach it.
Scope {
	id: root

	required property PanelWindow bar

	readonly property bool here: WindowManager.focusedOutput === bar.screen?.name
	readonly property bool open: Windows.shown && here
	property bool mapped: false

	onOpenChanged: open ? mapped = true : unmap.restart()

	Timer {
		id: unmap

		interval: 220
		onTriggered: if (!root.open) root.mapped = false
	}

	// the cards on their ring, a dimmed screen behind them
	component Ring: Item {
		anchors.fill: parent

		// a click beside the cards cancels
		MouseArea {
			anchors.fill: parent
			acceptedButtons: Qt.AllButtons
			onPressed: Windows.close()
		}

		Rectangle {
			anchors.fill: parent
			color: Qt.alpha(Theme.bg, 0.35)
			opacity: root.open ? 1 : 0

			Behavior on opacity {
				NumberAnimation {
					duration: 180
				}
			}
		}

		PathView {
			id: ring

			readonly property real cx: width / 2
			readonly property real cy: height / 2 - 40
			readonly property real rx: Math.min(width * 0.34, 200 + count * 60)
			readonly property real ry: Math.min(120, 40 + count * 14)

			anchors.fill: parent
			model: Windows.windows
			currentIndex: Windows.selected
			pathItemCount: Math.min(count, 9)
			preferredHighlightBegin: 0
			preferredHighlightEnd: 0
			highlightRangeMode: PathView.StrictlyEnforceRange
			highlightMoveDuration: 320
			interactive: false
			opacity: root.open ? 1 : 0
			scale: root.open ? 1 : 0.92

			Behavior on opacity {
				NumberAnimation {
					duration: 200
				}
			}

			Behavior on scale {
				NumberAnimation {
					duration: 260
					easing.type: Easing.OutCubic
				}
			}

			// round the ring from the front (its bottom), the far side behind
			path: Path {
				startX: ring.cx
				startY: ring.cy + ring.ry

				PathAngleArc {
					centerX: ring.cx
					centerY: ring.cy
					radiusX: ring.rx
					radiusY: ring.ry
					startAngle: 90
					sweepAngle: 360
				}
			}

			delegate: Item {
				id: card

				required property var modelData
				required property int index
				readonly property bool front: PathView.isCurrentItem
				// 1 at the front of the ring, 0 at the back; -1 … 1 from left to right
				readonly property real depth: ring.ry > 0 ? (y + height / 2 - (ring.cy - ring.ry)) / (2 * ring.ry) : 1
				readonly property real side: ring.rx > 0 ? (x + width / 2 - ring.cx) / ring.rx : 0
				readonly property var entry: DesktopEntries.heuristicLookup(modelData.cls) ?? DesktopEntries.heuristicLookup(modelData.instance)

				width: 360
				height: 250
				// PathView places the item's centre on the path
				z: depth * 100
				scale: 0.62 + 0.38 * depth
				opacity: ring.count === 1 ? 1 : 0.4 + 0.6 * depth

				transform: Rotation {
					origin.x: card.width / 2
					origin.y: card.height / 2
					axis {
						x: 0
						y: 1
						z: 0
					}
					angle: -card.side * 38
				}

				Rectangle {
					anchors.fill: parent
					radius: 30
					color: Qt.alpha(Theme.surface, 0.96)
					border.width: card.front ? 3 : 1
					border.color: card.front ? Theme.primary : Qt.alpha(Theme.border, 0.9)

					Behavior on border.width {
						NumberAnimation {
							duration: 160
						}
					}
				}

				IconImage {
					id: icon

					anchors.horizontalCenter: parent.horizontalCenter
					y: 36
					implicitSize: 96
					source: Quickshell.iconPath(card.entry?.icon ?? card.modelData.cls.toLowerCase(), "application-x-executable")
					asynchronous: true
				}

				Text {
					anchors.top: icon.bottom
					anchors.topMargin: 16
					anchors.horizontalCenter: parent.horizontalCenter
					width: parent.width - 40
					horizontalAlignment: Text.AlignHCenter
					text: card.modelData.title
					elide: Text.ElideRight
					maximumLineCount: 2
					wrapMode: Text.Wrap
					color: Theme.fg
					font.family: Theme.fontSans
					font.hintingPreference: Theme.hinting
					font.pixelSize: Theme.px(16)
					font.weight: card.front ? Font.DemiBold : Font.Normal
				}

				Text {
					anchors.bottom: parent.bottom
					anchors.bottomMargin: 18
					anchors.horizontalCenter: parent.horizontalCenter
					text: (card.entry?.name ?? card.modelData.cls) + "  ·  " + card.modelData.workspace
					color: Theme.fgMuted
					font.family: Theme.fontSans
					font.hintingPreference: Theme.hinting
					font.weight: Theme.textWeight
					font.pixelSize: Theme.textBody
				}

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: Windows.choose(card.index)
				}
			}
		}
	}

	// X11: a popup over the bar's screen
	LazyLoader {
		active: !Quickshell.env("WAYLAND_DISPLAY") && root.mapped

		PopupWindow {
			anchor.window: root.bar
			anchor.rect.x: 0
			anchor.rect.y: Config.position === "bottom" ? root.bar.height - implicitHeight : 0
			implicitWidth: root.bar.screen.width
			implicitHeight: root.bar.screen.height
			visible: true
			color: "transparent"

			Ring {}
		}
	}

	// Wayland: a layer surface holding the keyboard from the first Tab, so Alt's release comes here
	LazyLoader {
		active: !!Quickshell.env("WAYLAND_DISPLAY") && root.here && (Windows.switching || root.mapped)

		PanelWindow {
			screen: root.bar.screen
			anchors {
				top: true
				bottom: true
				left: true
				right: true
			}
			exclusionMode: ExclusionMode.Ignore
			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.keyboardFocus: Windows.switching ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
			WlrLayershell.namespace: "desktop-switcher"
			color: "transparent"

			Ring {
				focus: true
				Component.onCompleted: forceActiveFocus()
				Keys.onReleased: event => {
					if (event.key === Qt.Key_Alt)
						Windows.commit();
				}
				Keys.onPressed: event => {
					if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
						Windows.commit();
					else if (event.key === Qt.Key_Escape)
						Windows.close();
				}
			}
		}
	}
}
