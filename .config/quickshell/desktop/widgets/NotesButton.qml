import QtQuick
import Quickshell
import qs

// Opens the notes: desktop notes, a rofi menu over ~/.local/share/desktop/notes (as on i3).
BarButton {
	glyph: Icons.g("notes")
	onClicked: Quickshell.execDetached(["desktop", "notes"])
}
