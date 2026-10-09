import QtQuick
import qs
import qs.widgets

// A small rounded button: an optional icon and a label; on fills it with the accent.
Rectangle {
	id: root

	property string glyph
	property string label
	property bool on: false

	signal clicked

	implicitWidth: row.implicitWidth + 22
	implicitHeight: 34
	radius: 10
	color: on ? Theme.primary : hover.hovered ? Qt.alpha(Theme.fg, 0.1) : Qt.alpha(Theme.surface, 0.8)
	border.width: on ? 0 : 1
	border.color: Qt.alpha(Theme.border, 0.7)

	Behavior on color {
		ColorAnimation {
			duration: 140
		}
	}

	Row {
		id: row

		anchors.centerIn: parent
		spacing: 6

		Glyph {
			visible: root.glyph !== ""
			anchors.verticalCenter: parent.verticalCenter
			glyph: root.glyph
			filled: root.on
			font.pixelSize: 14
			color: root.on ? Theme.primaryText : Theme.fg
		}

		Text {
			visible: root.label !== ""
			anchors.verticalCenter: parent.verticalCenter
			text: root.label
			color: root.on ? Theme.primaryText : Theme.fg
			font.family: Theme.fontSans
			font.pixelSize: 13
			font.weight: root.on ? Font.DemiBold : Font.Normal
		}
	}

	HoverHandler {
		id: hover
	}

	MouseArea {
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: root.clicked()
	}
}
