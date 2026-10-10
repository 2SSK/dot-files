import QtQuick
import qs

// One setting: its name and a line about it on the left, the control on the right.
Rectangle {
	id: root

	property string label
	property string hint
	default property alias control: slot.data

	width: parent?.width ?? 0
	height: Math.max(56, text.implicitHeight + 24, slot.childrenRect.height + 20)
	radius: 12
	color: Qt.alpha(Theme.surface, 0.55)

	Column {
		id: text

		anchors.left: parent.left
		anchors.leftMargin: 16
		anchors.right: slot.left
		anchors.rightMargin: 16
		anchors.verticalCenter: parent.verticalCenter
		spacing: 3

		Text {
			text: root.label
			color: Theme.fg
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.pixelSize: 14
			font.weight: Font.Medium
		}

		Text {
			width: parent.width
			visible: root.hint !== ""
			text: root.hint
			wrapMode: Text.Wrap
			color: Theme.fgMuted
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.weight: Theme.textWeight
			font.pixelSize: 13
		}
	}

	Item {
		id: slot

		anchors.right: parent.right
		anchors.rightMargin: 16
		anchors.verticalCenter: parent.verticalCenter
		width: childrenRect.width
		height: childrenRect.height
	}
}
