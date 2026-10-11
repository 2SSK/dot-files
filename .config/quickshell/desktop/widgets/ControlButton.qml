import QtQuick
import qs

// Opens the control center (toggles, levels, media).
BarButton {
	glyph: Icons.g("adjustments-horizontal")
	active: Panel.controlOpen
	font.pixelSize: Theme.iconSize
	onClicked: Panel.toggleControl("home")
}
