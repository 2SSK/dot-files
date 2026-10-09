import QtQuick
import qs
import qs.services

// Bluetooth: on, off or connected (accent); opens the Bluetooth page.
Glyph {
	text: Connectivity.bluetooth ? Icons.g("bluetooth") : Icons.g("bluetooth-slash")
	color: Panel.controlOpen && Panel.controlPage === "bluetooth" ? Theme.primary : Theme.fg
	filled: Panel.controlOpen && Panel.controlPage === "bluetooth"
	font.pixelSize: Theme.iconSize - 1
	font.weight: Font.Normal
	readonly property bool present: Connectivity.bluetoothAvailable

	visible: present

	MouseArea {
		anchors.fill: parent
		anchors.margins: -6
		cursorShape: Qt.PointingHandCursor
		onClicked: Panel.toggleControl("bluetooth")
	}
}
