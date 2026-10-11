pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.widgets

// The wallpaper picker's rotation choices, dropping from its chip; a pick is saved to shell.json
// and closes it.
Rectangle {
	id: menu

	property bool open: false
	property var choices: [] // { value, label }: wallpaper.rotate's values

	height: choices.implicitHeight + 12
	radius: 12
	color: Theme.surface
	border.width: 1
	border.color: Qt.alpha(Theme.border, 0.8)
	opacity: open ? 1 : 0
	visible: opacity > 0

	Behavior on opacity {
		NumberAnimation {
			duration: 150
		}
	}

	Behavior on y {
		NumberAnimation {
			duration: 180
			easing.type: Easing.OutCubic
		}
	}

	Column {
		id: choices

		x: 6
		y: 6
		width: parent.width - 12

		Repeater {
			model: menu.choices

			delegate: Rectangle {
				id: choice

				required property var modelData
				readonly property bool on: Config.wallpaper.rotate === modelData.value

				width: choices.width
				height: 32
				radius: 8
				color: choiceHover.hovered ? Qt.alpha(Theme.fg, 0.08) : "transparent"

				UiText {
					x: 10
					anchors.verticalCenter: parent.verticalCenter
					text: choice.modelData.label
					color: choice.on ? Theme.primary : Theme.fg
					font.weight: choice.on ? Font.DemiBold : Font.Normal
				}

				Glyph {
					visible: choice.on
					anchors.right: parent.right
					anchors.rightMargin: 10
					anchors.verticalCenter: parent.verticalCenter
					glyph: Icons.g("check")
					font.pixelSize: 13
					color: Theme.primary
				}

				HoverHandler {
					id: choiceHover
				}

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: {
						Config.wallpaper.rotate = choice.modelData.value;
						Config.save();
						menu.open = false;
					}
				}
			}
		}
	}
}
