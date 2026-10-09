import QtQuick
import qs
import qs.services

// Wi-Fi: off, or on (dimmed while not connected); opens the Wi-Fi page.
Glyph {
	glyph: Connectivity.wifi ? Icons.g("wifi") : Icons.g("wifi-off")
	color: Panel.controlOpen && Panel.controlPage === "wifi" ? Theme.primary : Theme.fg
	filled: Panel.controlOpen && Panel.controlPage === "wifi"
	font.pixelSize: Theme.iconSize - 1
	font.weight: Font.Normal
	readonly property bool present: Connectivity.wifiAvailable

	visible: present
	opacity: Connectivity.wifi && !Connectivity.network ? 0.55 : 1

	MouseArea {
		anchors.fill: parent
		anchors.margins: -6
		cursorShape: Qt.PointingHandCursor
		onClicked: Panel.toggleControl("wifi")
	}
}
