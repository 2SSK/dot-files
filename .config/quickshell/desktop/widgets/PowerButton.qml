import QtQuick
import qs

// Opens the power menu in the island.
Glyph {
	text: "󰐥"
	color: Panel.view === "power" ? Theme.error : Theme.fg
	font.pixelSize: Theme.iconSize

	MouseArea {
		anchors.fill: parent
		anchors.margins: -4
		cursorShape: Qt.PointingHandCursor
		onClicked: Panel.togglePower()
	}
}
