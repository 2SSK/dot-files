import QtQuick
import qs

// Opens the power menu; red, on a red capsule.
Glyph {
	readonly property color capsule: Qt.alpha(Theme.error, 0.16)

	glyph: Icons.g("power")
	color: Theme.error
	font.pixelSize: Theme.iconSize

	MouseArea {
		anchors.fill: parent
		anchors.margins: -8
		cursorShape: Qt.PointingHandCursor
		onClicked: Panel.togglePower()
	}
}
