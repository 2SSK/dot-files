import QtQuick
import qs
import qs.services

// Opens the todo list; a dot while tasks are open.
BarButton {
	glyph: Icons.g("checklist")
	page: "todo"

	Rectangle {
		visible: Todo.open > 0
		anchors.right: parent.right
		anchors.top: parent.top
		width: 6
		height: 6
		radius: 3
		color: Theme.primary
	}
}
