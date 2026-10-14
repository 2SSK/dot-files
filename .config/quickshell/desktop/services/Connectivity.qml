pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking

// Wi-Fi (NetworkManager) and Bluetooth (BlueZ): on or off, and what's connected.
Singleton {
	id: root

	readonly property bool wifiAvailable: Networking.wifiHardwareEnabled && wifiCard
	readonly property bool wifiCard: Networking.devices.values.some(d => d.type === DeviceType.Wifi)
	readonly property bool wifiBlocked: wifiCard && !Networking.wifiHardwareEnabled // the radio switch, or rfkill
	readonly property bool wifi: Networking.wifiEnabled
	readonly property string network: Array.from(Networking.devices.values).filter(d => d.type === DeviceType.Wifi).reduce((all, d) => all.concat(Array.from(d.networks.values)), []).find(n => n.connected)?.name ?? ""

	readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
	readonly property bool bluetoothAvailable: adapter !== null
	readonly property bool bluetooth: adapter?.enabled ?? false
	readonly property string device: Array.from(Bluetooth.devices.values).find(d => d.connected)?.name ?? ""

	function toggleWifi(): void {
		Networking.wifiEnabled = !Networking.wifiEnabled;
	}

	function toggleBluetooth(): void {
		if (adapter)
			adapter.enabled = !adapter.enabled;
	}

	// a device paired is trusted too, so it reconnects by itself
	Instantiator {
		model: Bluetooth.devices

		delegate: Connections {
			required property BluetoothDevice modelData

			target: modelData

			function onPairedChanged(): void {
				if (modelData.paired && !modelData.trusted)
					modelData.trusted = true;
			}
		}
	}

	// The pairing agent: keyboards, earbuds and mice that ask to confirm a pairing need one to answer,
	// and Quickshell has none. NoInputNoOutput pairs with no code to type or compare.
	Process {
		running: root.bluetoothAvailable
		command: ["bluetoothctl", "--agent", "NoInputNoOutput"]
		stdinEnabled: true // bluetoothctl quits when its input ends
	}
}
