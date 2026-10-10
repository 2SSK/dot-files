import QtQuick
import qs
import qs.widgets

// A one-line text field with a placeholder; accepted(text) on Enter. A password field can be
// revealable: an eye at its end shows what's typed.
Rectangle {
	id: root

	property alias text: input.text
	property string placeholder
	property bool password
	property bool revealable
	property bool revealed
	signal accepted(string text)
	signal keyPressed(var event) // before the field's own handling: accept it to take the key

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
		anchors.rightMargin: eye.visible ? eye.width + 18 : 14
		verticalAlignment: TextInput.AlignVCenter
		echoMode: root.password && !root.revealed ? TextInput.Password : TextInput.Normal
		color: Theme.fg
		selectionColor: Qt.alpha(Theme.primary, 0.4)
		font.family: Theme.fontSans
		font.hintingPreference: Theme.hinting
		font.weight: Theme.textWeight
		font.pixelSize: Theme.textBody
		clip: true
		activeFocusOnTab: true
		onAccepted: root.accepted(text)
		Keys.onPressed: event => root.keyPressed(event)
	}

	Glyph {
		id: eye

		visible: root.password && root.revealable
		anchors.right: parent.right
		anchors.rightMargin: 14
		anchors.verticalCenter: parent.verticalCenter
		glyph: Icons.g(root.revealed ? "eye-off" : "eye")
		font.pixelSize: 16
		font.weight: Font.Normal
		color: eyeArea.containsMouse ? Theme.fg : Theme.fgMuted

		MouseArea {
			id: eyeArea

			anchors.fill: parent
			anchors.margins: -8
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			onClicked: {
				root.revealed = !root.revealed;
				input.forceActiveFocus(); // keep typing
			}
		}
	}

	Text {
		anchors.left: parent.left
		anchors.leftMargin: 14
		anchors.verticalCenter: parent.verticalCenter
		visible: input.text === ""
		text: root.placeholder
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.hintingPreference: Theme.hinting
		font.weight: Theme.textWeight
		font.pixelSize: Theme.textBody
	}
}
