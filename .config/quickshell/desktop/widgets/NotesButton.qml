import QtQuick
import qs
import qs.services

// Opens the scratch note.
Glyph {
	text: "\u{F082E}" // md-notebook
	color: Panel.controlOpen && Panel.controlPage === "notes" ? Theme.primary : Theme.fg
	font.pixelSize: Theme.iconSize - 1
	font.weight: Font.Normal

	MouseArea {
		anchors.fill: parent
		anchors.margins: -6
		cursorShape: Qt.PointingHandCursor
		onClicked: Panel.toggleControl("notes")
	}
}
