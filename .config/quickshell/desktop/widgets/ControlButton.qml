import QtQuick
import qs

// Opens the control center (toggles, levels, media).
Glyph {
	text: Icons.g("sliders-horizontal")
	color: Panel.controlOpen ? Theme.primary : Theme.fg
	filled: Panel.controlOpen
	font.pixelSize: Theme.iconSize
	font.weight: Font.Normal

	MouseArea {
		anchors.fill: parent
		anchors.margins: -6
		cursorShape: Qt.PointingHandCursor
		onClicked: Panel.toggleControl("home")
	}
}
