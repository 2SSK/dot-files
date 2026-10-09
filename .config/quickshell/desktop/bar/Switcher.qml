pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Widgets
import qs
import qs.services
import qs.widgets

// The window switcher (Ctrl+Tab): the open windows as rounded cards on a ring, most recent first.
// The ring turns to bring the next one to the front; cards further round shrink, fade and turn
// away. Releasing Ctrl switches to the front one, Escape cancels, a click picks one. A quick tap
// switches to the last window without showing the ring. i3's "switcher" mode hands it the keys.
PopupWindow {
	id: root

	required property PanelWindow bar

	readonly property bool open: Windows.shown && I3.focusedMonitor?.name === bar.screen?.name
	property bool mapped: false

	onOpenChanged: open ? mapped = true : unmap.restart()

	Timer {
		id: unmap

		interval: 220
		onTriggered: if (!root.open) root.mapped = false
	}

	anchor.window: bar
	anchor.rect.x: 0
	anchor.rect.y: Config.position === "bottom" ? bar.height - implicitHeight : 0
	implicitWidth: bar.screen.width
	implicitHeight: bar.screen.height
	visible: mapped
	color: "transparent"

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
		readonly property real rx: Math.min(width * 0.3, 140 + count * 45)
		readonly property real ry: Math.min(90, 30 + count * 10)

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

			width: 250
			height: 180
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
				radius: 24
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
				y: 26
				implicitSize: 64
				source: Quickshell.iconPath(card.entry?.icon ?? card.modelData.cls.toLowerCase(), "application-x-executable")
				asynchronous: true
			}

			Text {
				anchors.top: icon.bottom
				anchors.topMargin: 12
				anchors.horizontalCenter: parent.horizontalCenter
				width: parent.width - 32
				horizontalAlignment: Text.AlignHCenter
				text: card.modelData.title
				elide: Text.ElideRight
				maximumLineCount: 2
				wrapMode: Text.Wrap
				color: Theme.fg
				font.family: Theme.fontSans
				font.pixelSize: 13
				font.weight: card.front ? Font.DemiBold : Font.Normal
			}

			Text {
				anchors.bottom: parent.bottom
				anchors.bottomMargin: 12
				anchors.horizontalCenter: parent.horizontalCenter
				text: (card.entry?.name ?? card.modelData.cls) + "  ·  " + card.modelData.workspace
				color: Theme.fgMuted
				font.family: Theme.fontSans
				font.pixelSize: 11
			}

			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.PointingHandCursor
				onClicked: Windows.choose(card.index)
			}
		}
	}
}
