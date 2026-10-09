import QtQuick
import qs

// Opens the power menu; red.
Glyph {
	text: "\u{F0425}" // md-power
	color: Theme.error
	font.pixelSize: Theme.iconSize

	MouseArea {
		anchors.fill: parent
		anchors.margins: -8
		cursorShape: Qt.PointingHandCursor
		onClicked: Panel.togglePower()
	}
}
