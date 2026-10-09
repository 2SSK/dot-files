import QtQuick
import qs
import qs.widgets

// A quick toggle: an icon, a name and its state; filled with the accent while on.
Rectangle {
	id: root

	property string glyph
	property real glyphRotation: 0
	property string label
	property string detail
	property bool on
	property bool available: true
	signal clicked

	height: 62
	radius: 14
	opacity: available ? 1 : 0.45
	color: on ? Theme.primary : hover.hovered && available ? Qt.alpha(Theme.overlay, 0.95) : Qt.alpha(Theme.surface, 0.8)

	Behavior on color {
		ColorAnimation {
			duration: 150
		}
	}

	Rectangle {
		id: badge

		x: 12
		anchors.verticalCenter: parent.verticalCenter
		width: 36
		height: 36
		radius: 18
		color: root.on ? Qt.alpha(Theme.onPrimary, 0.14) : Qt.alpha(Theme.fg, 0.07)

		Glyph {
			anchors.centerIn: parent
			glyph: root.glyph
			rotation: root.glyphRotation
			font.pixelSize: 17
			font.weight: Font.Normal
			color: root.on ? Theme.onPrimary : Theme.fg
		}
	}

	Column {
		anchors.left: badge.right
		anchors.leftMargin: 10
		anchors.right: parent.right
		anchors.rightMargin: 10
		anchors.verticalCenter: parent.verticalCenter
		spacing: 2

		Text {
			width: parent.width
			text: root.label
			elide: Text.ElideRight
			color: root.on ? Theme.onPrimary : Theme.fg
			font.family: Theme.fontSans
			font.pixelSize: 13
			font.weight: Font.DemiBold
		}

		Text {
			width: parent.width
			text: root.detail
			elide: Text.ElideRight
			color: root.on ? Qt.alpha(Theme.onPrimary, 0.75) : Theme.fgMuted
			font.family: Theme.fontSans
			font.pixelSize: 11
		}
	}

	HoverHandler {
		id: hover
	}

	MouseArea {
		anchors.fill: parent
		enabled: root.available
		cursorShape: Qt.PointingHandCursor
		onClicked: root.clicked()
	}
}
