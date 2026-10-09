import QtQuick
import qs

// Opens the clipboard history.
Glyph {
	text: "\u{F014C}" // md-clipboard-outline
	color: Panel.clipboardOpen ? Theme.primary : Theme.fg
	font.pixelSize: Theme.iconSize - 1
	font.weight: Font.Normal

	MouseArea {
		anchors.fill: parent
		anchors.margins: -6
		cursorShape: Qt.PointingHandCursor
		onClicked: Panel.clipboardOpen = !Panel.clipboardOpen
	}
}
