import QtQuick
import qs

// Opens the clipboard history.
Glyph {
	glyph: Icons.g("clipboard-text")
	color: Panel.clipboardOpen ? Theme.primary : Theme.fg
	filled: Panel.clipboardOpen
	font.pixelSize: Theme.iconSize - 1
	font.weight: Font.Normal

	MouseArea {
		anchors.fill: parent
		anchors.margins: -6
		cursorShape: Qt.PointingHandCursor
		onClicked: Panel.clipboardOpen = !Panel.clipboardOpen
	}
}
