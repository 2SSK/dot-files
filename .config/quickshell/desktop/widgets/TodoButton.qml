import QtQuick
import Quickshell
import qs

// Opens the to-dos: desktop todo, a rofi menu over ~/.local/share/desktop/todo.md (as on i3).
BarButton {
	glyph: Icons.g("checklist")
	onClicked: Quickshell.execDetached(["desktop", "todo"])
}
