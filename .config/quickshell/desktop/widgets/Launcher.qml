import QtQuick
import Quickshell
import qs

// The distro mark; opens the app launcher.
Glyph {
	glyph: Icons.g("layout-grid")
	color: Theme.primary
	font.pixelSize: Theme.iconSize + 1

	MouseArea {
		anchors.fill: parent
		anchors.margins: -4
		cursorShape: Qt.PointingHandCursor
		onClicked: Panel.toggleLauncher("apps")
	}
}
