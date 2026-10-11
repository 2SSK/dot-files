import QtQuick
import qs
import qs.widgets

// A choice in the capture panel: an icon over its label (Region, Window, Screen); picked with the
// arrows or under the pointer it takes the accent; `danger` makes it the red Stop recording.
Rectangle {
	id: tile

	property string glyph
	property string label
	property bool danger: false
	property bool chosen: false // picked with the arrows
	signal clicked

	height: 78
	radius: 16
	color: danger ? (tileHover.hovered || chosen ? Qt.lighter(Theme.error, 1.1) : Theme.error) : tileHover.hovered || chosen ? Qt.alpha(Theme.primary, 0.16) : Qt.alpha(Theme.surface, 0.8)
	border.width: (tileHover.hovered || chosen) && !danger ? 1 : 0
	border.color: Qt.alpha(Theme.primary, 0.6)

	Behavior on color {
		ColorAnimation {
			duration: 120
		}
	}

	Column {
		anchors.centerIn: parent
		spacing: 6

		Glyph {
			anchors.horizontalCenter: parent.horizontalCenter
			glyph: Icons.g(tile.glyph)
			font.pixelSize: 22
			color: tile.danger ? Theme.primaryText : tileHover.hovered || tile.chosen ? Theme.primary : Theme.fg
			filled: tile.danger
		}

		UiText {
			anchors.horizontalCenter: parent.horizontalCenter
			text: tile.label
			color: tile.danger ? Theme.primaryText : Theme.fg
			font.weight: Font.Medium
		}
	}

	HoverHandler {
		id: tileHover
	}

	MouseArea {
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: tile.clicked()
	}
}
