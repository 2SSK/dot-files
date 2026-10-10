import QtQuick
import qs
import qs.widgets

// A row in a list (a network, a device): icon, name, detail, and buttons on the right.
Rectangle {
	id: root

	property string glyph
	property string label
	property string detail
	property bool active
	default property alias buttons: tools.data
	signal clicked

	width: parent?.width ?? 0
	height: 58
	radius: 12
	color: active ? Qt.alpha(Theme.primary, 0.16) : hover.hovered ? Qt.alpha(Theme.overlay, 0.9) : Qt.alpha(Theme.surface, 0.8)

	HoverHandler {
		id: hover
	}

	MouseArea {
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: root.clicked()
	}

	Glyph {
		id: icon

		x: 16
		anchors.verticalCenter: parent.verticalCenter
		width: 22
		glyph: root.glyph
		font.pixelSize: 18
		font.weight: Font.Normal
		color: root.active ? Theme.primary : Theme.fg
	}

	Column {
		anchors.left: icon.right
		anchors.leftMargin: 14
		anchors.right: tools.left
		anchors.rightMargin: 10
		anchors.verticalCenter: parent.verticalCenter
		spacing: 2

		Text {
			width: parent.width
			text: root.label
			elide: Text.ElideRight
			color: Theme.fg
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.pixelSize: 14
			font.weight: root.active ? Font.DemiBold : Font.Medium
		}

		Text {
			width: parent.width
			visible: text !== ""
			text: root.detail
			elide: Text.ElideRight
			color: root.active ? Theme.primary : Theme.fgMuted
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.weight: Theme.textWeight
			font.pixelSize: 13
		}
	}

	Row {
		id: tools

		anchors.right: parent.right
		anchors.rightMargin: 10
		anchors.verticalCenter: parent.verticalCenter
		spacing: 6
	}
}
