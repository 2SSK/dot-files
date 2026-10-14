pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.services
import qs.widgets

// Bluetooth: your devices (paired, connected first), then ones nearby, looked for while this is open.
// Nameless devices (phones and beacons advertising only an address) are left out.
Column {
	id: root

	readonly property string title: "Bluetooth"
	readonly property var actions: [
		{ glyph: Connectivity.bluetooth ? Icons.g("bluetooth") : Icons.g("bluetooth-off"), on: Connectivity.bluetooth, act: () => Connectivity.toggleBluetooth() }
	]
	readonly property var named: Array.from(Bluetooth.devices.values).filter(d => d.name && !/^([0-9A-F]{2}[-:]){5}[0-9A-F]{2}$/i.test(d.name))
	readonly property var mine: named.filter(d => d.paired).sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
	readonly property var nearby: named.filter(d => !d.paired).sort((a, b) => a.name.localeCompare(b.name))

	function scan(on: bool): void {
		if (Connectivity.adapter && Connectivity.adapter.discovering !== on)
			Connectivity.adapter.discovering = on;
	}

	// BlueZ's icon name for the kind of device
	function glyphOf(icon: string): string {
		const kinds = [["input-keyboard", "keyboard"], ["input-mouse", "mouse"], ["input-tablet", "mouse"], ["input-gaming", "device-gamepad-2"],
			["audio-head", "headphones"], ["audio", "device-speaker"], ["phone", "device-mobile"], ["computer", "device-laptop"], ["watch", "device-watch"]];
		return Icons.g(kinds.find(([prefix]) => icon.startsWith(prefix))?.[1] ?? "bluetooth");
	}

	spacing: 8

	Component.onCompleted: scan(Connectivity.bluetooth)
	Component.onDestruction: scan(false)

	Connections {
		target: Connectivity

		function onBluetoothChanged(): void {
			root.scan(Connectivity.bluetooth);
		}
	}

	UiText {
		visible: !Connectivity.bluetoothAvailable || !Connectivity.bluetooth || root.named.length === 0
		width: parent.width
		topPadding: 30
		horizontalAlignment: Text.AlignHCenter
		wrapMode: Text.Wrap
		text: !Connectivity.bluetoothAvailable ? "No Bluetooth here (it needs BlueZ and an adapter)." : !Connectivity.bluetooth ? "Bluetooth is off." : "Looking for devices…"
		color: Theme.fgMuted
	}

	component Heading: UiText {
		topPadding: 4
		color: Theme.fgMuted
		font.pixelSize: Theme.textLabel
	}

	component Device: ListRow {
		id: row

		required property BluetoothDevice modelData

		width: root.width
		glyph: root.glyphOf(modelData.icon)
		label: modelData.name
		detail: (modelData.connected ? "Connected" : modelData.pairing ? "Pairing…" : modelData.paired ? "Paired" : "Nearby") + (modelData.batteryAvailable ? ` · ${Math.round(modelData.battery * 100)}%` : "")
		active: modelData.connected
		onClicked: modelData.connected ? modelData.disconnect() : modelData.paired ? modelData.connect() : modelData.pair()

		SmallButton {
			text: row.modelData.connected ? "Disconnect" : row.modelData.paired ? "Connect" : "Pair"
			accent: !row.modelData.connected
			onClicked: row.clicked()
		}

		SmallButton {
			visible: row.modelData.paired && !row.modelData.connected
			text: "Forget"
			onClicked: row.modelData.forget()
		}
	}

	Heading {
		visible: Connectivity.bluetooth && root.mine.length > 0
		text: "My devices"
	}

	// a ScriptModel keeps each row as a scan reorders them
	Repeater {
		model: ScriptModel {
			values: Connectivity.bluetooth ? root.mine : []
		}

		delegate: Device {}
	}

	Heading {
		visible: Connectivity.bluetooth && root.nearby.length > 0
		text: "Nearby"
	}

	Repeater {
		model: ScriptModel {
			values: Connectivity.bluetooth ? root.nearby : []
		}

		delegate: Device {}
	}
}
