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

	// What went wrong with a device, by address, for the Bluetooth page to show and offer Re-pair:
	// "Couldn't connect", "Keeps dropping", "Couldn't pair". A stale bond (the device lost its keys:
	// reflashed, or its profile cleared) shows as any of them; forgetting and pairing again mends it.
	property var trouble: ({})
	property string repairing: "" // the address being re-paired: forgotten, paired again once seen
	property BluetoothDevice trying: null // the device connecting, given connectTimer to get there

	function setTrouble(address: string, what: string): void {
		const t = Object.assign({}, trouble);
		if (what)
			t[address] = what;
		else
			delete t[address];
		trouble = t;
	}

	function connectTo(device: BluetoothDevice): void {
		setTrouble(device.address, "");
		if (device.paired && !device.trusted)
			device.trusted = true;
		trying = device;
		connectTimer.restart();
		device.connect();
	}

	function pairWith(device: BluetoothDevice): void {
		setTrouble(device.address, "");
		device.pair();
	}

	function repair(device: BluetoothDevice): void {
		setTrouble(device.address, "");
		repairing = device.address;
		repairTimer.restart();
		if (adapter && !adapter.discovering)
			adapter.discovering = true; // to see it again once forgotten
		device.forget();
	}

	Timer {
		id: connectTimer

		interval: 12000
		onTriggered: {
			if (root.trying && !root.trying.connected)
				root.setTrouble(root.trying.address, "Couldn't connect");
			root.trying = null;
		}
	}

	// pairing again didn't get there: the device still holds the old bond and turns the new one away
	Timer {
		id: repairTimer

		interval: 30000
		onTriggered: {
			if (!root.repairing)
				return;
			root.setTrouble(root.repairing, "Clear its Bluetooth profile, then Pair");
			root.repairing = "";
		}
	}

	// each device: trusted while paired, so it reconnects by itself; its troubles noted; its battery
	// said once when low
	Instantiator {
		model: Bluetooth.devices

		delegate: Connections {
			required property BluetoothDevice modelData
			property bool warned: false // until it's charged past 25% again
			property var drops: [] // when it disconnected lately

			target: modelData

			// untrusted, bluez turns its reconnects away: so as it pairs, as the shell starts with it
			// paired, and if anything takes the trust away
			function trust(): void {
				if (modelData.paired && !modelData.trusted)
					modelData.trusted = true;
			}

			function onPairedChanged(): void {
				trust();
				if (modelData.paired)
					root.setTrouble(modelData.address, "");
				if (!modelData.paired || modelData.address !== root.repairing)
					return;
				root.repairing = "";
				root.connectTo(modelData);
			}

			function onTrustedChanged(): void {
				trust();
			}

			function onPairingChanged(): void {
				if (!modelData.pairing && !modelData.paired && modelData.address !== root.repairing)
					root.setTrouble(modelData.address, "Couldn't pair");
			}

			// as it changes, as it connects, and as the shell starts with it already low
			function check(): void {
				if (!modelData.connected || !modelData.batteryAvailable)
					return;
				if (modelData.battery <= 0.15 && !warned) {
					warned = true;
					Quickshell.execDetached(["notify-send", "-a", "Bluetooth", `${modelData.name} battery low`, `${Math.round(modelData.battery * 100)}% left`]);
				} else if (modelData.battery > 0.25) {
					warned = false;
				}
			}

			function onBatteryChanged(): void {
				check();
			}

			// connected: its trouble is over; three drops in half a minute: it's looping (a stale bond)
			function onConnectedChanged(): void {
				check();
				if (modelData.connected) {
					root.setTrouble(modelData.address, "");
					return;
				}
				const now = Date.now();
				drops = [...drops.filter(t => now - t < 30000), now];
				if (drops.length >= 3)
					root.setTrouble(modelData.address, "Keeps dropping");
			}

			Component.onCompleted: {
				trust();
				check();
				// back after Re-pair forgot it: pair again
				if (modelData.address === root.repairing && !modelData.paired)
					modelData.pair();
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
