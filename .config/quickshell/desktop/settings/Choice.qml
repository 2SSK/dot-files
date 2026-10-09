pragma ComponentBehavior: Bound

import QtQuick
import qs

// Segmented buttons: one of `options` ({ value, label }) is `value`; a click calls picked(value).
Rectangle {
	id: root

	property var options: []
	property var value
	signal picked(var value)

	implicitWidth: row.implicitWidth + 6
	implicitHeight: 34
	radius: 10
	color: Qt.alpha(Theme.overlay, 0.7)

	Row {
		id: row

		anchors.centerIn: parent
		spacing: 2

		Repeater {
			model: root.options

			delegate: Rectangle {
				id: option

				required property var modelData
				readonly property bool on: root.value === modelData.value

				width: Math.max(64, label.implicitWidth + 24)
				height: 28
				radius: 8
				color: on ? Theme.primary : hover.hovered ? Qt.alpha(Theme.fg, 0.08) : "transparent"

				Behavior on color {
					ColorAnimation {
						duration: 140
					}
				}

				Text {
					id: label

					anchors.centerIn: parent
					text: option.modelData.label
					color: option.on ? Theme.primaryText : Theme.fg
					font.family: Theme.fontSans
					font.pixelSize: 13
					font.weight: Font.Medium
				}

				HoverHandler {
					id: hover
				}

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: root.picked(option.modelData.value)
				}
			}
		}
	}
}
