import QtQuick
import qs
import qs.services

// Opens the todo list; a dot while tasks are open.
Glyph {
	glyph: Icons.g("checklist")
	color: Panel.controlOpen && Panel.controlPage === "todo" ? Theme.primary : Theme.fg
	filled: Panel.controlOpen && Panel.controlPage === "todo"
	font.pixelSize: Theme.iconSize - 1
	font.weight: Font.Normal

	Rectangle {
		visible: Todo.open > 0
		anchors.right: parent.right
		anchors.top: parent.top
		width: 6
		height: 6
		radius: 3
		color: Theme.primary
	}

	MouseArea {
		anchors.fill: parent
		anchors.margins: -6
		cursorShape: Qt.PointingHandCursor
		onClicked: Panel.toggleControl("todo")
	}
}
