pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.widgets

// The capture panel asking which screen: the monitors drawn as they're arranged, numbered, the
// picked one in the accent; a click takes one, "All screens" every one, the arrow goes back.
Item {
	id: chooser

	readonly property real minX: Math.min(...screens.map(s => s.x))
	readonly property real minY: Math.min(...screens.map(s => s.y))
	readonly property real spanW: Math.max(...screens.map(s => s.x + s.width)) - minX
	readonly property real spanH: Math.max(...screens.map(s => s.y + s.height)) - minY
	readonly property real k: Math.min((width - 8) / spanW, (map.height - 8) / spanH)

	property string asking // "shot" or "record"
	property var screens: [] // left to right, top to bottom: their numbers
	property int monitor: 0 // the one picked with the keys
	signal back
	signal take(var screen) // a ShellScreen, or null for all of them

	Row {
		id: head

		spacing: 8

		Rectangle {
			width: 30
			height: 30
			radius: 10
			color: backHover.hovered ? Qt.alpha(Theme.fg, 0.1) : Qt.alpha(Theme.surface, 0.8)

			Glyph {
				anchors.centerIn: parent
				glyph: Icons.g("chevron-left")
				font.pixelSize: 15
			}

			HoverHandler {
				id: backHover
			}

			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.PointingHandCursor
				onClicked: chooser.back()
			}
		}

		UiText {
			anchors.verticalCenter: parent.verticalCenter
			text: chooser.asking === "record" ? "Record which screen?" : "Screenshot which screen?"
			font.family: Theme.fontHeading
			font.weight: Font.DemiBold
		}
	}

	Chip {
		anchors.right: parent.right
		anchors.verticalCenter: head.verticalCenter
		label: "All screens  (A)"
		onClicked: chooser.take(null)
	}

	Item {
		id: map

		anchors.top: head.bottom
		anchors.topMargin: 14
		width: parent.width
		height: parent.height - head.height - 14

		Repeater {
			model: chooser.screens

			delegate: Rectangle {
				id: monitor

				required property var modelData
				required property int index

				x: (map.width - chooser.spanW * chooser.k) / 2 + (modelData.x - chooser.minX) * chooser.k + 4
				y: (map.height - chooser.spanH * chooser.k) / 2 + (modelData.y - chooser.minY) * chooser.k + 4
				width: modelData.width * chooser.k - 8
				height: modelData.height * chooser.k - 8
				radius: 14
				readonly property bool chosen: monitorHover.hovered || chooser.monitor === index

				color: chosen ? Qt.alpha(Theme.primary, 0.2) : Qt.alpha(Theme.surface, 0.85)
				border.width: chosen ? 2 : 1
				border.color: chosen ? Theme.primary : Qt.alpha(Theme.border, 0.9)

				Behavior on color {
					ColorAnimation {
						duration: 120
					}
				}

				Column {
					anchors.centerIn: parent
					spacing: 4

					Glyph {
						anchors.horizontalCenter: parent.horizontalCenter
						glyph: Icons.g("device-desktop")
						font.pixelSize: 20
						color: monitor.chosen ? Theme.primary : Theme.fg
					}

					UiText {
						anchors.horizontalCenter: parent.horizontalCenter
						text: `${monitor.index + 1}  ${monitor.modelData.name}`
						font.family: Theme.fontHeading
						font.weight: Font.DemiBold
					}

					UiText {
						anchors.horizontalCenter: parent.horizontalCenter
						text: `${monitor.modelData.width}×${monitor.modelData.height}`
						color: Theme.fgMuted
						font.pixelSize: Theme.textCaption
					}
				}

				HoverHandler {
					id: monitorHover
				}

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: chooser.take(monitor.modelData)
				}
			}
		}
	}
}
