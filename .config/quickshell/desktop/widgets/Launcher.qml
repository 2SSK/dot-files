import QtQuick
import Quickshell
import qs

// The distro mark; opens the app launcher.
Glyph {
	text: Icons.g("squares-four")
	color: Theme.primary
	font.pixelSize: Theme.iconSize + 1

	MouseArea {
		anchors.fill: parent
		anchors.margins: -4
		cursorShape: Qt.PointingHandCursor
		onClicked: Quickshell.execDetached(["rofi", "-show", "drun"])
	}
}
