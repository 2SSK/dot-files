import QtQuick
import qs

// A one-line text field with a placeholder; accepted(text) on Enter.
Rectangle {
	id: root

	property alias text: input.text
	property string placeholder
	property bool password
	signal accepted(string text)

	function focusField(): void {
		input.forceActiveFocus();
	}

	height: 40
	radius: 10
	color: Qt.alpha(Theme.surface, 0.9)
	border.width: 1
	border.color: input.activeFocus ? Theme.primary : Qt.alpha(Theme.border, 0.8)

	TextInput {
		id: input

		anchors.fill: parent
		anchors.leftMargin: 14
		anchors.rightMargin: 14
		verticalAlignment: TextInput.AlignVCenter
		echoMode: root.password ? TextInput.Password : TextInput.Normal
		color: Theme.fg
		selectionColor: Qt.alpha(Theme.primary, 0.4)
		font.family: Theme.fontSans
		font.pixelSize: 14
		clip: true
		onAccepted: root.accepted(text)
	}

	Text {
		anchors.left: parent.left
		anchors.leftMargin: 14
		anchors.verticalCenter: parent.verticalCenter
		visible: input.text === ""
		text: root.placeholder
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.pixelSize: 14
	}
}
