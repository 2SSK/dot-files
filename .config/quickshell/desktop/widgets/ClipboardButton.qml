import QtQuick
import qs

// Opens the clipboard history.
BarButton {
	glyph: Icons.g("clipboard")
	active: Panel.clipboardOpen
	onClicked: Panel.clipboardOpen = !Panel.clipboardOpen
}
