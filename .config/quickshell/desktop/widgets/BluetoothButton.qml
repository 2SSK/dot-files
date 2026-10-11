import QtQuick
import qs
import qs.services

// Bluetooth: on, off or connected (accent); opens the Bluetooth page.
BarButton {
	readonly property bool present: Connectivity.bluetoothAvailable

	glyph: Connectivity.bluetooth ? Icons.g("bluetooth") : Icons.g("bluetooth-off")
	page: "bluetooth"
	visible: present
}
