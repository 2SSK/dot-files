import QtQuick
import qs
import qs.services

// A scratch note: type anywhere; it's saved a moment after you stop.
Rectangle {
	readonly property string title: "Notes"
	readonly property var actions: []

	height: Math.max(460, edit.implicitHeight + 32)
	radius: 14
	color: Qt.alpha(Theme.surface, 0.8)

	TextEdit {
		id: edit

		x: 16
		y: 16
		width: parent.width - 32
		wrapMode: TextEdit.Wrap
		color: Theme.fg
		selectionColor: Qt.alpha(Theme.primary, 0.4)
		font.family: Theme.fontSans
		font.pixelSize: 14
		Component.onCompleted: {
			text = Notes.read();
			cursorPosition = length;
			forceActiveFocus();
		}
		onTextChanged: if (activeFocus) Notes.write(text)
	}

	Text {
		x: 16
		y: 16
		visible: edit.length === 0
		text: "Write something…"
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.pixelSize: 14
	}
}
