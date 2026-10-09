import QtQuick
import Quickshell
import qs

// The distro mark; opens the app launcher.
Glyph {
	text: "󰣇"
	color: Theme.primary
	font.pixelSize: Theme.fontSize + 3

	MouseArea {
		anchors.fill: parent
		anchors.margins: -4
		cursorShape: Qt.PointingHandCursor
		onClicked: Quickshell.execDetached(["rofi", "-show", "drun"])
	}
}
