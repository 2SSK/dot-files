pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking

// Wi-Fi (NetworkManager) and Bluetooth (BlueZ): on or off, and what's connected.
Singleton {
	id: root

	readonly property bool wifiAvailable: Networking.wifiHardwareEnabled && Networking.devices.values.some(d => d.type === DeviceType.Wifi)
	readonly property bool wifi: Networking.wifiEnabled
	readonly property string network: Networking.devices.values.filter(d => d.type === DeviceType.Wifi).flatMap(d => d.networks.values).find(n => n.connected)?.name ?? ""

	readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
	readonly property bool bluetoothAvailable: adapter !== null
	readonly property bool bluetooth: adapter?.enabled ?? false
	readonly property string device: Bluetooth.devices.values.find(d => d.connected)?.name ?? ""

	function toggleWifi(): void {
		Networking.wifiEnabled = !Networking.wifiEnabled;
	}

	function toggleBluetooth(): void {
		if (adapter)
			adapter.enabled = !adapter.enabled;
	}
}
