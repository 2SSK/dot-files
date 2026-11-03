import QtQuick
import qs
import qs.widgets

// A row in a list (a network, a device): icon (or something of its own in lead), name, detail, and
// buttons on the right.
Rectangle {
	id: root

	property string glyph
	property string label
	property string detail
	property bool active
	default property alias buttons: tools.data
	property alias lead: leadSlot.data // instead of the glyph: signal bars, a picture
	signal clicked

	width: parent?.width ?? 0
	height: 58
	radius: Theme.radiusCard
	color: active ? Qt.alpha(Theme.primary, 0.16) : hover.hovered ? Qt.alpha(Theme.overlay, 0.9) : Qt.alpha(Theme.surface, 0.8)

	HoverHandler {
		id: hover
	}

	MouseArea {
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: root.clicked()
	}

	Item {
		id: icon

		x: 16
		anchors.verticalCenter: parent.verticalCenter
		width: 22
		height: 22

		Glyph {
			visible: root.glyph !== ""
			anchors.centerIn: parent
			glyph: root.glyph
			font.pixelSize: 18
			font.weight: Font.Normal
			color: root.active ? Theme.primary : Theme.fg
		}

		Item {
			id: leadSlot

			anchors.centerIn: parent
			width: childrenRect.width
			height: childrenRect.height
		}
	}

	Column {
		anchors.left: icon.right
		anchors.leftMargin: 14
		anchors.right: tools.left
		anchors.rightMargin: 10
		anchors.verticalCenter: parent.verticalCenter
		spacing: 2

		UiText {
			width: parent.width
			text: root.label
			elide: Text.ElideRight
			font.weight: root.active ? Font.DemiBold : Font.Medium
		}

		UiText {
			width: parent.width
			visible: text !== ""
			text: root.detail
			elide: Text.ElideRight
			color: root.active ? Theme.primary : Theme.fgMuted
			font.pixelSize: Theme.textLabel
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
