import QtQuick
import qs

// Opens the control center (toggles, levels, media).
Glyph {
	text: "\u{EB52}" // cod-settings (sliders)
	color: Panel.controlOpen ? Theme.primary : Theme.fg
	font.pixelSize: Theme.iconSize
	font.weight: Font.Normal

	MouseArea {
		anchors.fill: parent
		anchors.margins: -6
		cursorShape: Qt.PointingHandCursor
		onClicked: Panel.toggleControl("home")
	}
}
