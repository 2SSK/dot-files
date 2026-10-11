import QtQuick
import qs
import qs.services

// Wi-Fi: off, or on (dimmed while not connected); opens the Wi-Fi page.
BarButton {
	readonly property bool present: Connectivity.wifiAvailable

	glyph: Connectivity.wifi ? Icons.g("wifi") : Icons.g("wifi-off")
	page: "wifi"
	visible: present
	opacity: Connectivity.wifi && !Connectivity.network ? 0.55 : 1
}
