import QtQuick
import qs

// A small pill button with a word on it.
Rectangle {
	id: root

	property string text
	property bool accent
	signal clicked

	width: label.implicitWidth + 22
	height: 28
	radius: 14
	color: accent ? (hover.hovered ? Qt.lighter(Theme.primary, 1.1) : Theme.primary) : hover.hovered ? Qt.alpha(Theme.fg, 0.12) : Qt.alpha(Theme.overlay, 0.9)

	Text {
		id: label

		anchors.centerIn: parent
		text: root.text
		color: root.accent ? Theme.primaryText : Theme.fg
		font.family: Theme.fontSans
		font.pixelSize: 12
		font.weight: Font.Medium
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
